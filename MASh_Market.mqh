//+---------------------------------------------------------------------------+
//|                                                           MASh_Market.mqh |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property strict

//+---------------------------------------------------------------------------+
//|   I N C L U D E S                                                         |
//+---------------------------------------------------------------------------+
#include            <Arrays/List.mqh>


//+---------------------------------------------------------------------------+
//|   D E F I N E S                                                           |
//+---------------------------------------------------------------------------+
#define         BALANCE_UT              "MASv_BalanceUpdateTime"
#define         BALANCE_FN              "MASv_BalanceFirstNumber"
#define         BALANCE_V_UT            "MASv_BalanceUpdateTime_virtual"
#define         BALANCE_V_FN            "MASv_BalanceFirstNumber_virtual"
#define         BALANCE_VIRT            "MASv_BalanceVirtual"
#define         BALANCE_VIRT_START      10000.0
#define         ORDER_PREFIX            "M_Order_"

color           COLOR_BUY = clrLimeGreen;
color           COLOR_SELL = clrOrangeRed;
int             M_SLIPPAGE = 3;
int             M_MAGIC = 123456;

enum SYMBOL_TYPE {
    FOREX,
    CFD,
    FUTURES
};

enum ORDER_TYPE {
    REAL_TRADE,
    VIRTUAL_TRADE,
    VIRTUAL_STOPS
};


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
//+
//+---------------------------------------------------------------------------+
//|   S Y S T E M                                                             |
//+---------------------------------------------------------------------------+
bool NewBar(const int period = PERIOD_CURRENT)
{
    static datetime lastTime = 0;
    if( lastTime != iTime(Symbol(), period, 0) ) {      
        lastTime = iTime(Symbol(), period, 0);
        return true;
    }
    return false;
};

int BarTimeLeft(const int period = PERIOD_CURRENT, const string symbol = NULL)
{
	return PeriodSeconds(period) - (int)MarketInfo(symbol, MODE_TIME) % PeriodSeconds(period);
};

int IndexOfBar(const datetime time_bar, 
               const string symbol = NULL, const int period = PERIOD_CURRENT)
{
    int index = 0;
    while( time_bar < iTime(symbol, period, index) ) {
        index++;
    }
    return index;
};

int GetOffsetFromServerTimeZone()
{
    // datetime TimeCurrent()
    // Возвращает последнее известное время сервера
    // (время прихода последней котировки) в формате datetime

    // datetime TimeLocal()
    // Возвращает локальное компьютерное время в формате datetime

    // datetime TimeGMT()
    // Возвращает время GMT формате datetime с учетом перехода
    // на зимнее или летнее время по локальному времени компьютера,
    // на котором запущен клиентский терминал

    // int TimeGMTOffset()
    // Возвращает текущую разницу между временем GMT и локальным
    // временем компьютера в секундах с учетом перехода на зимнее или летнее время
    // TimeGMTOffset() =  TimeGMT() - TimeLocal()

    // int TimeDaylightSavings()
    // Возвращает признак перехода на летнее /зимнее время
    // Если был произведен переход на зимнее (стандартное) время, то возвращается 0.

    // return TimeGMTOffset() - (TimeGMT() - TimeCurrent());
    return (int)(TimeLocal() - TimeCurrent());
};


//+---------------------------------------------------------------------------+
//|   M A R K E T   D A T A                                                   |
//+---------------------------------------------------------------------------+
double Convert(const double value, const string origin, const string target)
{   // Return converted value from origin to target symbol
    if( origin == target || origin == "" || target == "" ) {
        return value;
    }
    const string prefx = StringSubstr(Symbol(), 6);
    string symbol1 = origin + target + prefx;
    string symbol2 = target + origin + prefx;
    if( MarketInfo(symbol1, MODE_BID) > 0.0 ) {
        return NormalizeDouble(value * MarketInfo(symbol1, MODE_BID), (int)MarketInfo(symbol1, MODE_DIGITS));
    }
    if( MarketInfo(symbol2, MODE_BID) > 0.0 ) {
        return NormalizeDouble(value / MarketInfo(symbol2, MODE_BID), (int)MarketInfo(symbol2, MODE_DIGITS));
    }
    return -1.0;
};

int SymbolsList(const bool selected, string &symbols[])
{
    string symbolsFileName;
    int symbolsNumber, offset;
    if( selected ) 
        symbolsFileName = "symbols.sel";
    else
        symbolsFileName = "symbols.raw";
    int hFile = FileOpenHistory(symbolsFileName, FILE_BIN|FILE_READ);
    if( hFile < 0 ) 
        return -1;
    if( selected ) {
        symbolsNumber = ((int)FileSize(hFile) - 4) / 128;
        offset = 116;
    } else { 
        symbolsNumber = (int)FileSize(hFile) / 1936;
        offset = 1924;
    }
    ArrayResize(symbols, symbolsNumber);
    if( selected )
        FileSeek(hFile, 4, SEEK_SET);
    for( int i = 0; i < symbolsNumber; i++ ) {
        symbols[i] = FileReadString(hFile, 12);
        FileSeek(hFile, offset, SEEK_CUR);
    }
    FileClose(hFile);
    return symbolsNumber;
};

double GetAccountBalance(const ORDER_TYPE type = REAL_TRADE)
{   // Return account balance (origin or virtual)
    if( type == VIRTUAL_TRADE ) {
        double _balance;
        if( GlobalVariableCheck(BALANCE_VIRT) ) {
            _balance = GlobalVariableGet(BALANCE_VIRT);
        } else {
            _balance = BALANCE_VIRT_START;
            GlobalVariableSet(BALANCE_VIRT, _balance);
        }
        return _balance;
    }
    return AccountBalance();
};

double GetBalanceFirstNum(const ORDER_TYPE type = REAL_TRADE)
{   // Update and return balance for first number
    string postfix = "";
    double balance = GetAccountBalance(type);
    if( type == VIRTUAL_TRADE ) {
        postfix = "_virtual";
    }
    string updateTime = BALANCE_UT + postfix;
    string firstNumber = BALANCE_FN + postfix;
    if( Month() != TimeMonth((datetime)GlobalVariableGet(updateTime)) ) {
        GlobalVariableSet(updateTime, (double)GlobalVariableSet(firstNumber, balance));
    }
    return GlobalVariableGet(firstNumber);
};


//+---------------------------------------------------------------------------+
//|   M O N E Y   M A N A G E M E N T                                         |
//+---------------------------------------------------------------------------+
double GetRiskBuyOneLot(const double openPrice, const double stopPrice)
{
    if( openPrice <= 0.0 || stopPrice <= 0.0 ) {
        Print(__FUNCTION__ + "Error = Cannot calculate risk on buy one lot.");
        return 0.0;
    }
    return Convert(MathAbs(openPrice-stopPrice) * MarketInfo(Symbol(), MODE_LOTSIZE),
                    StringSubstr(Symbol(), 3, 3), AccountCurrency());
};

double GetLotSize(const double oneLotRisk, const double oneOrderRisk)
{
    double _minLot = MarketInfo(Symbol(), MODE_MINLOT);
    if( oneLotRisk * _minLot >= oneOrderRisk || oneLotRisk <= 0 ) {
        return _minLot;
    } else if( _minLot == 1 ) {
        return MathFloor(oneOrderRisk / oneLotRisk); // Часть от риска лотом
    } else {
        return NormalizeDouble(oneOrderRisk / oneLotRisk - _minLot, 2);
    }
    return -1.0;
};

double GetOpenedOrdersRisk()
{
    double openedRiskSum = 0.0, openedCommision = 0.0;
    for( int idx = 0; idx < OrdersTotal(); idx++ ) {
        if( OrderSelect(idx, SELECT_BY_POS) ) {
            int openedType = OrderType();
            if( openedType == OP_BUY || openedType == OP_SELL ) {
                openedRiskSum += MathAbs(OrderOpenPrice() - OrderStopLoss());
                openedCommision += OrderCommission() + OrderSwap();
            }
        } else {
            Print(__FUNCTION__ + ": Error = Order not found.");
        }
    }
    return openedCommision + Convert(openedRiskSum, StringSubstr(Symbol(), 3, 3),
                                     AccountCurrency());
};

double GetOpenedOrdersNegativeRisk()
{
    // GOTO: Implementation
    return 0.0;
};


//+---------------------------------------------------------------------------+
//|   T I M E F R A M E S                                                     |
//+---------------------------------------------------------------------------+
ENUM_TIMEFRAMES PeriodMore(const int period, const bool x5 = false)
{   // Returns next tf. x5 - more x 5
    int minute = (period == 0 ? Period() : period);
    switch( (ENUM_TIMEFRAMES)minute ) {
        case PERIOD_M1:  return(PERIOD_M5);
        case PERIOD_M5:  if(x5) return(PERIOD_M15); else return(PERIOD_M30);
        case PERIOD_M15: if(x5) return(PERIOD_M30); else return(PERIOD_H1);
        case PERIOD_M30: if(x5) return(PERIOD_H1);  else return(PERIOD_H4);
        case PERIOD_H1:  return(PERIOD_H4);
        case PERIOD_H4:  return(PERIOD_D1);
        case PERIOD_D1:  return(PERIOD_W1);
        case PERIOD_W1:  return(PERIOD_MN1);
        case PERIOD_MN1: return(PERIOD_MN1);
        default:         return(PERIOD_CURRENT);
    }
};

ENUM_TIMEFRAMES PeriodLess(const int period, const bool x5 = false)
{   // Returns prev tf. x5 - less x 5
    int minute = (period == 0 ? Period() : period);
    switch( (ENUM_TIMEFRAMES)minute ) {
        case PERIOD_M1:  return(PERIOD_M1);
        case PERIOD_M5:  return(PERIOD_M1);
        case PERIOD_M15: if(x5) return(PERIOD_M5);  else return(PERIOD_M5);// ?
        case PERIOD_M30: if(x5) return(PERIOD_M15); else return(PERIOD_M5);
        case PERIOD_H1:  if(x5) return(PERIOD_M30); else return(PERIOD_M15);
        case PERIOD_H4:  return(PERIOD_H1);
        case PERIOD_D1:  return(PERIOD_H4);
        case PERIOD_W1:  return(PERIOD_D1);
        case PERIOD_MN1: return(PERIOD_W1);
        default:         return(PERIOD_CURRENT);
    }
};


//+---------------------------------------------------------------------------+
//|   T R A D E   C L A S S E S                                               |
//+---------------------------------------------------------------------------+
class COrder : public CObject
{
public:
    int         m_ticket;
    string      m_symbol;
    int         m_type;
    double      m_volume;
    double      m_openPrice;
    datetime    m_openTime;
    double      m_stopLoss;
    double      m_takeProfit;
    int         m_slippage;
    string      m_comment;
    int         m_magicNumber;
    datetime    m_expiration;
    double      m_closePrice;
    datetime    m_closeTime;
    double      m_commission;
    double      m_swap;
    void COrder();
    void COrder(const string symb, const int cmd, const double vol,
                const double prc, const int slppg, const double stop,
                const double take, const string comm,
                const int magic, const datetime exp);
    void ~COrder();
    void Draw();
    bool Load(const int handle);
    bool Save(const int handle);
private:
    void DrawArrowOpen(const color clr);
    void DrawArrowClose(const color clr);
    void DrawLine(const color clr);
};

class CMarket : public CObject
{
public:
    void CMarket();
    void CMarket(const int slippage, const string folder = "", const int magic = 0);
    void ~CMarket();

public:
    virtual void    M_OnTick() = 0;
    virtual bool    M_OrderClose(int ticket, double lots, double price,
                               int slippage, color arrow_color = CLR_NONE) = 0;
    virtual bool    M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE) = 0;
    virtual double  M_OrderClosePrice() const = 0;
    virtual datetime M_OrderCloseTime() const = 0;
    virtual string  M_OrderComment(const string newComment = "") = 0;
    virtual double  M_OrderCommission() const = 0;
    virtual bool    M_OrderDelete(int ticket, color arrow_color = CLR_NONE) = 0;
    virtual datetime M_OrderExpiration() const = 0;
    virtual double  M_OrderLots() const = 0;
    virtual int     M_OrderMagicNumber() const = 0;
    virtual bool    M_OrderModify(int ticket, double price, double stoploss,
                                double takeprofit, datetime expiration,
                                color arrow_color = CLR_NONE) = 0;
    virtual double  M_OrderOpenPrice() const = 0;
    virtual datetime M_OrderOpenTime() const = 0;
    virtual void    M_OrderPrint() const = 0;
    virtual double  M_OrderProfit() const = 0;
    virtual bool    M_OrderSelect(int index, int select, int pool = MODE_TRADES) = 0;
    virtual int     M_OrderSend(string symbol, int cmd, double volume,
                              double price, int slippage, double stoploss,
                              double takeprofit, string comment = NULL, int magic = 0,
                              datetime expiration = 0, color arrow_color = clrNONE) = 0;
    virtual int     M_OrdersHistoryTotal() const = 0;
    virtual double  M_OrderStopLoss() const = 0;
    virtual int     M_OrdersTotal() const = 0;
    virtual double  M_OrderSwap() const = 0;
    virtual string  M_OrderSymbol() const = 0;
    virtual double  M_OrderTakeProfit() const = 0;
    virtual int     M_OrderTicket() const = 0;
    virtual int     M_OrderType() const = 0;

protected:
    void SaveOpenedOrders(const string postfix = "_orders.csv");
    void SaveHistoryOrders(const string postfix = "_history.csv");
    void LoadOpenedOrders(const string postfix = "_orders.csv");
    void LoadHistoryOrders(const string postfix = "_history.csv");

protected:
    CList m_ordersList;
    CList m_ordersHistory;
    COrder* m_currentOrder;
    string m_path;
    int m_slippage;
};

class CRealTrade : public  CMarket
{
public:
    void CRealTrade();
    void CRealTrade(const int slippage, const string folder = "", const int magic = 0);
    void ~CRealTrade();

public:
    void    M_OnTick();
    bool    M_OrderClose(int ticket, double lots, double price,
                       int slippage, color arrow_color = CLR_NONE);
    bool    M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE);
    double  M_OrderClosePrice() const;
    datetime M_OrderCloseTime() const;
    string  M_OrderComment(const string newComment = "");
    double  M_OrderCommission() const;
    bool    M_OrderDelete(int ticket, color arrow_color = CLR_NONE);
    datetime M_OrderExpiration() const;
    double  M_OrderLots() const;
    int     M_OrderMagicNumber() const;
    bool    M_OrderModify(int ticket, double price, double stoploss,
                        double takeprofit, datetime expiration,
                        color arrow_color = CLR_NONE);
    double  M_OrderOpenPrice() const;
    datetime M_OrderOpenTime() const;
    void    M_OrderPrint() const;
    double  M_OrderProfit() const;
    bool    M_OrderSelect(int index, int select, int pool = MODE_TRADES);
    int     M_OrderSend(string symbol, int cmd, double volume,
                      double price, int slippage, double stoploss,
                      double takeprofit, string comment = NULL, int magic = 0,
                      datetime expiration = 0, color arrow_color = clrNONE);
    int     M_OrdersHistoryTotal() const;
    double  M_OrderStopLoss() const;
    int     M_OrdersTotal() const;
    double  M_OrderSwap() const;
    string  M_OrderSymbol() const;
    double  M_OrderTakeProfit() const;
    int     M_OrderTicket() const;
    int     M_OrderType() const;
};

class CVirtualTrade : public CMarket
{
public:
    void CVirtualTrade();
    void CVirtualTrade(const int slippage, const string folder = "", const int magic = 0);
    void ~CVirtualTrade();

public:
    void    M_OnTick();
    bool    M_OrderClose(int ticket, double lots, double price,
                       int slippage, color arrow_color = CLR_NONE);
    bool    M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE);
    double  M_OrderClosePrice() const;
    datetime M_OrderCloseTime() const;
    string  M_OrderComment(const string newComment = "");
    double  M_OrderCommission() const;
    bool    M_OrderDelete(int ticket, color arrow_color = CLR_NONE);
    datetime M_OrderExpiration() const;
    double  M_OrderLots() const;
    int     M_OrderMagicNumber() const;
    bool    M_OrderModify(int ticket, double price, double stoploss,
                        double takeprofit, datetime expiration,
                        color arrow_color = CLR_NONE);
    double  M_OrderOpenPrice() const;
    datetime M_OrderOpenTime() const;
    void    M_OrderPrint() const;
    double  M_OrderProfit() const;
    bool    M_OrderSelect(int index, int select, int pool = MODE_TRADES);
    int     M_OrderSend(string symbol, int cmd, double volume,
                      double price, int slippage, double stoploss,
                      double takeprofit, string comment = NULL, int magic = 0,
                      datetime expiration = 0, color arrow_color = clrNONE);
    int     M_OrdersHistoryTotal() const;
    double  M_OrderStopLoss() const;
    int     M_OrdersTotal() const;
    double  M_OrderSwap() const;
    string  M_OrderSymbol() const;
    double  M_OrderTakeProfit() const;
    int     M_OrderTicket() const;
    int     M_OrderType() const;
};

class CVirtualStops : public CMarket
{
public:
    void CVirtualStops();
    void CVirtualStops(const int slippage, const string folder = "", const int magic = 0);
    void ~CVirtualStops();

public:
    void    M_OnTick();
    bool    M_OrderClose(int ticket, double lots, double price,
                       int slippage, color arrow_color = CLR_NONE);
    bool    M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE);
    double  M_OrderClosePrice() const;
    datetime M_OrderCloseTime() const;
    string  M_OrderComment(const string newComment = "");
    double  M_OrderCommission() const;
    bool    M_OrderDelete(int ticket, color arrow_color = CLR_NONE);
    datetime M_OrderExpiration() const;
    double  M_OrderLots() const;
    int     M_OrderMagicNumber() const;
    bool    M_OrderModify(int ticket, double price, double stoploss,
                        double takeprofit, datetime expiration,
                        color arrow_color = CLR_NONE);
    double  M_OrderOpenPrice() const;
    datetime M_OrderOpenTime() const;
    void    M_OrderPrint() const;
    double  M_OrderProfit() const;
    bool    M_OrderSelect(int index, int select, int pool = MODE_TRADES);
    int     M_OrderSend(string symbol, int cmd, double volume,
                      double price, int slippage, double stoploss,
                      double takeprofit, string comment = NULL, int magic = 0,
                      datetime expiration = 0, color arrow_color = clrNONE);
    int     M_OrdersHistoryTotal() const;
    double  M_OrderStopLoss() const;
    int     M_OrdersTotal() const;
    double  M_OrderSwap() const;
    string  M_OrderSymbol() const;
    double  M_OrderTakeProfit() const;
    int     M_OrderTicket() const;
    int     M_OrderType() const;

private:
    void LoadOpenedOrders(const string postfix = "_orders.csv");
};

CMarket* GetTradeObject(const ORDER_TYPE tradeType, const string directory = "",
                        const int slippage = 3, const int magic = 0)
{
    CMarket *result = NULL;
    switch( tradeType ) {
        case REAL_TRADE:    { result = new CRealTrade(); break; }
        case VIRTUAL_TRADE: { result = new CVirtualTrade(slippage, directory, magic); break; }
        case VIRTUAL_STOPS: { result = new CVirtualStops(slippage, directory, magic); break; }
    }
    return result;
};


//+---------------------------------------------------------------------------+
//|   M O N E Y   M A N A G E M E N T                                         |
//+---------------------------------------------------------------------------+
double GetOpenedOrdersRisk(CMarket *obj)
{
    double openedRiskSum = 0.0, openedCommision = 0.0;
    for( int idx = 0; idx < obj.M_OrdersTotal(); idx++ ) {
        if( obj.M_OrderSelect(idx, SELECT_BY_POS) ) {
            int openedType = obj.M_OrderType();
            if( openedType == OP_BUY || openedType == OP_SELL ) {
                openedRiskSum += MathAbs(obj.M_OrderOpenPrice() - obj.M_OrderStopLoss());
                openedCommision += obj.M_OrderCommission() + obj.M_OrderSwap();
            }
        } else {
            Print(__FUNCTION__ + ": Error = Order not found.");
        }
    }
    return openedCommision + Convert(openedRiskSum, StringSubstr(Symbol(), 3, 3),
                                     AccountCurrency());
};

double GetOpenedOrdersNegativeRisk(CMarket *obj)
{
    // GOTO: Implementation
    return 0.0;
};


//+---------------------------------------------------------------------------+
//|   C O R D E R   C L A S S   I M P L E M E N T A T I O N                   |
//+---------------------------------------------------------------------------+
void COrder::COrder() : CObject(), m_ticket(0), m_symbol(""),
                        m_type(0), m_volume(0.0),
                        m_openPrice(0.0), m_openTime(0),
                        m_stopLoss(0.0), m_takeProfit(0.0),
                        m_slippage(M_SLIPPAGE), m_comment(""),
                        m_magicNumber(0), m_expiration(0),
                        m_closePrice(0.0), m_closeTime(0),
                        m_commission(0.1), m_swap(0.0)
{};

void COrder::COrder(const string symb, const int cmd, const double vol,
                    const double prc, const int slppg, const double stop,
                    const double take, const string comm, const int magic,
                    const datetime exp) : CObject(),
                        m_symbol(symb), m_type(cmd),
                        m_volume(vol), m_openPrice(prc),
                        m_slippage(slppg), m_stopLoss(stop),
                        m_takeProfit(take), m_comment(comm),
                        m_magicNumber(magic), m_expiration(exp),
                        m_closePrice(0.0), m_closeTime(0),
                        m_commission(0.1), m_swap(0.0)
{
    m_ticket = (int)TimeCurrent() % 1000000;
    if( m_type == OP_BUY || m_type == OP_SELL ) {
        m_openTime = TimeCurrent();
    } else {
        m_openTime = 0;
    }
};

void COrder::~COrder()
{};

void COrder::Draw()
{
    if( m_openTime == 0 ) {
        if( m_type != OP_BUY && m_type != OP_SELL ) {
            // ? Draw horisontal line
        } else {
            return;
        }
    }
    color _clrOpen;
    if( m_type == OP_BUY || m_type == OP_BUYLIMIT || m_type == OP_BUYSTOP) {
        _clrOpen = COLOR_BUY;
    } else {
        _clrOpen = COLOR_SELL;
    }
    DrawArrowOpen(_clrOpen);
    if( m_closePrice > 0.0 ) {
        DrawLine(_clrOpen);
        DrawArrowClose(_clrOpen);
    }
};

bool COrder::Load(const int handle)
{
    double _profit;
    ReadHistoryLine(handle, m_openTime, m_type, m_volume, m_symbol,
                    m_openPrice, m_stopLoss, m_takeProfit, m_closeTime, 
                    m_closePrice, m_commission, m_swap, _profit, m_comment);
    m_ticket = (int)m_openTime % 1000000;
    m_slippage = M_SLIPPAGE;
    m_magicNumber = M_MAGIC;
    m_expiration = m_closeTime;
    return true;
};

bool COrder::Save(const int handle)
{
    double profit = 0.0;
    if( m_closePrice > 0.0 ) {
        if( m_type == OP_BUY ) {
            profit = Convert(m_closePrice - m_openPrice, StringSubstr(Symbol(), 3, 3), AccountCurrency());
            profit = m_volume * MarketInfo(Symbol(), MODE_LOTSIZE) * profit - 0.1;
        } else if( m_type == OP_SELL ) {
            profit = Convert(m_openPrice - m_closePrice, StringSubstr(Symbol(), 3, 3), AccountCurrency() );
            profit = m_volume * MarketInfo(Symbol(), MODE_LOTSIZE) * profit - 0.1;
        }
    }
    WriteHistoryLine(handle, m_openTime, m_type, m_volume, m_symbol,
                     m_openPrice, m_stopLoss, m_takeProfit, m_closeTime, 
                     m_closePrice, m_commission, m_swap, profit, m_comment);
    return true;
};

void COrder::DrawArrowOpen(const color clr = clrGray)
{
    const string name = StringConcatenate(ORDER_PREFIX, m_ticket, "_Open");
    if( ObjectFind(name) >= 0 ) {
        ObjectDelete(name);
    }
    if( !ObjectCreate(name, OBJ_ARROW_BUY, 0, m_openTime, m_openPrice) ) {
        Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        return;
    }
    const uchar code = 2;
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
};

void COrder::DrawArrowClose(const color clr = clrGray)
{
    const string name = StringConcatenate(ORDER_PREFIX, m_ticket, "_Close");
    if( ObjectFind(name) >= 0 ) {
        ObjectDelete(name);
    }
    if( !ObjectCreate(name, OBJ_ARROW_BUY, 0, m_closeTime, m_closePrice) ) {
        Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        return;
    }
    const uchar code = 3;
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
};

void COrder::DrawLine(const color clr = clrGray)
{
    const string name = StringConcatenate(ORDER_PREFIX, m_ticket, "_Line");
    if( ObjectFind(name) >= 0 ) {
        ObjectDelete(name);
    }
    if( !ObjectCreate(name, OBJ_TREND, 0, m_openTime, m_openPrice, m_closeTime, m_closePrice) ) {
        Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        return;
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
};


//+---------------------------------------------------------------------------+
//|   C M A R K E T   C L A S S   I M P L E M E N T A T I O N                 |
//+---------------------------------------------------------------------------+
void CMarket::CMarket()
{
    m_path = "ML-Assistant/";
    m_slippage = M_SLIPPAGE;
};

void CMarket::CMarket(const int slippage, const string folder = "", const int magic = 0)
{
    m_slippage = slippage;
    M_MAGIC = magic;
    // Check slash
    if( StringLen(folder) > 0 ) {
        if( StringFind(folder, "/") < StringLen(folder)-1 ) {
            m_path = StringConcatenate(folder, "/");
        }
    }
};

void CMarket::~CMarket()
{
    m_ordersList.Clear();
    m_ordersHistory.Clear();
    ObjectsDeleteAll(0, ORDER_PREFIX);
};

void CMarket::SaveOpenedOrders(const string postfix = "_orders.csv")
{
    string filePath = StringConcatenate(m_path, Symbol(), postfix);
    int hFile = FileOpen(filePath, FILE_WRITE | FILE_CSV | FILE_SHARE_WRITE, StringGetChar(";", 0));
    for( int idx = 0; idx < m_ordersList.Total(); idx++ ) {
        m_ordersList.GetNodeAtIndex(idx).Save(hFile);
    }
    FileClose(hFile);
};

void CMarket::SaveHistoryOrders(const string postfix = "_history.csv")
{
    string filePath = StringConcatenate(m_path, Symbol(), postfix);
    int hFile = FileOpen(filePath, FILE_WRITE | FILE_CSV | FILE_SHARE_WRITE, StringGetChar(";", 0));
    for( int idx = 0; idx < m_ordersHistory.Total(); idx++ ) {
        m_ordersHistory.GetNodeAtIndex(idx).Save(hFile);
    }
    FileClose(hFile);
};

void CMarket::LoadOpenedOrders(const string postfix = "_orders.csv")
{
    string filePath = StringConcatenate(Symbol(), postfix);
    int hFile = FileOpen(filePath, FILE_READ | FILE_CSV | FILE_SHARE_READ, StringGetChar(";", 0));
    if( hFile != INVALID_HANDLE ) {
        while( !FileIsEnding(hFile) ) {
            m_ordersList.Add(new COrder());
            COrder* _order = m_ordersList.GetCurrentNode();
            _order.Load(hFile);
            _order.Draw();
        }
        FileClose(hFile);
    }
};

void CMarket::LoadHistoryOrders(const string postfix = "_history.csv")
{
    string filePath = StringConcatenate(Symbol(), postfix);
    int hFile = FileOpen(filePath, FILE_READ | FILE_CSV | FILE_SHARE_READ, StringGetChar(";", 0));
    if( hFile != INVALID_HANDLE ) {
        while( !FileIsEnding(hFile) ) {
            m_ordersHistory.Add(new COrder());
            COrder* _order = m_ordersHistory.GetCurrentNode();
            _order.Load(hFile);
            _order.Draw();
        }
        FileClose(hFile);
    }
};


//+---------------------------------------------------------------------------+
//|   C R E A L _ T R A D E   C L A S S   I M P L E M E N T A T I O N         |
//+---------------------------------------------------------------------------+
void CRealTrade::CRealTrade() : CMarket()
{};

void CRealTrade::CRealTrade(const int slippage, const string folder = "", const int magic = 0) :
        CMarket(slippage, folder, magic)
{};

void CRealTrade::~CRealTrade()
{};

void CRealTrade::M_OnTick()
{};

bool CRealTrade::M_OrderClose(int ticket, double lots, double price,
                            int slippage, color arrow_color = CLR_NONE)
{
    return OrderClose(ticket, lots, price, slippage, arrow_color);
};

bool CRealTrade::M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE)
{
    return OrderCloseBy(ticket, opposite, arrow_color);
};

double CRealTrade::M_OrderClosePrice() const
{
    return OrderClosePrice();
};

datetime CRealTrade::M_OrderCloseTime() const
{
    return OrderCloseTime();
};

string CRealTrade::M_OrderComment(const string newComment = "")
{
    return OrderComment();
};

double CRealTrade::M_OrderCommission() const
{
    return OrderCommission();
};

bool CRealTrade::M_OrderDelete(int ticket, color arrow_color = CLR_NONE)
{
    return OrderDelete(ticket, arrow_color);
};

datetime CRealTrade::M_OrderExpiration() const
{
    return OrderExpiration();
};

double CRealTrade::M_OrderLots() const
{
    return OrderLots();
};

int CRealTrade::M_OrderMagicNumber() const
{
    return OrderMagicNumber();
};

bool CRealTrade::M_OrderModify(int ticket, double price, double stoploss,
                             double takeprofit, datetime expiration,
                             color arrow_color = CLR_NONE)
{
    return OrderModify(ticket, price, stoploss, takeprofit, expiration, arrow_color);
};

double CRealTrade::M_OrderOpenPrice() const
{
    return OrderOpenPrice();
};

datetime CRealTrade::M_OrderOpenTime() const
{
    return OrderOpenTime();
};

void CRealTrade::M_OrderPrint() const
{
    OrderPrint();
};

double CRealTrade::M_OrderProfit() const
{
    return OrderProfit();
};

bool CRealTrade::M_OrderSelect(int index, int select, int pool = MODE_TRADES)
{
    return OrderSelect(index, select, pool);
};

int CRealTrade::M_OrderSend(string symbol, int cmd, double volume,
                          double price, int slippage,
                          double stoploss, double takeprofit,
                          string comment = NULL, int magic = 0,
                          datetime expiration = 0, color arrow_color = clrNONE)
{
    return OrderSend(symbol, cmd, volume, NormalizeDouble(price, Digits),
                        slippage, stoploss, takeprofit,
                        comment, magic, expiration, arrow_color);
};

int CRealTrade::M_OrdersHistoryTotal() const
{
    return OrdersHistoryTotal();
};

double CRealTrade::M_OrderStopLoss() const
{
    return OrderStopLoss();
};

int CRealTrade::M_OrdersTotal() const
{
    return OrdersTotal();
};

double CRealTrade::M_OrderSwap() const
{
    return OrderSwap();
};

string CRealTrade::M_OrderSymbol() const
{
    return OrderSymbol();
};

double CRealTrade::M_OrderTakeProfit() const
{
    return OrderTakeProfit();
};

int CRealTrade::M_OrderTicket() const
{
    return OrderTicket();
};

int CRealTrade::M_OrderType() const
{
    return OrderType();
};


//+---------------------------------------------------------------------------+
//|   C V I R T U A L _ T R A D E   C L A S S   I M P L E M E N T A T I O N   |
//+---------------------------------------------------------------------------+
void CVirtualTrade::CVirtualTrade() : CMarket()
{
    LoadOpenedOrders("_v-orders.csv");
    LoadHistoryOrders("_v-history.csv");
};

void CVirtualTrade::CVirtualTrade(const int slippage, const string folder = "", const int magic = 0) : 
        CMarket(slippage, folder, magic)
{
    LoadOpenedOrders("_v-orders.csv");
    LoadHistoryOrders("_v-history.csv");
};

void CVirtualTrade::~CVirtualTrade()
{
    SaveOpenedOrders("_v-orders.csv");
    SaveHistoryOrders("_v-history.csv");
    m_ordersList.Clear();
    m_ordersHistory.Clear();
    ObjectsDeleteAll(0, ORDER_PREFIX);
};

void CVirtualTrade::M_OnTick()
{
    for( int idx = 0; idx < M_OrdersTotal(); idx++ ) {
        M_OrderSelect(idx, SELECT_BY_POS);
        if( M_OrderSymbol() != Symbol() ) {
            continue;
        }
        if( M_OrderExpiration() <= TimeCurrent() ) {
            double _closePrice = 0.0;
            if( M_OrderType() == OP_BUY ) {
                _closePrice = MarketInfo(Symbol(), MODE_BID);
            } else if( M_OrderType() == OP_SELL ) {
                _closePrice = MarketInfo(Symbol(), MODE_ASK);
            }
            M_OrderClose(M_OrderTicket(), M_OrderLots(), _closePrice, m_slippage);
            continue;
        }
        const int ticket = M_OrderTicket();
        const int type = M_OrderType();
        const double stop = M_OrderStopLoss();
        const double take = M_OrderTakeProfit();
        const double vol = M_OrderLots();
        // Check stop levels
        if( stop > 0.0 ) { // Check the break of stop levels.
            if( type == OP_BUY ) {
                if( stop >= MarketInfo(Symbol(), MODE_BID) ) {
                    M_OrderComment(M_OrderComment() + "_[sl]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_BID), m_slippage);
                    continue;
                }
            } else if( type == OP_SELL ) {
                if( stop <= MarketInfo(Symbol(), MODE_ASK) ) {
                    M_OrderComment(M_OrderComment() + "_[sl]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_ASK), m_slippage);
                    continue;
                }
            }
        }
        if( take > 0.0 ) { // Check the break of take levels.
            if( type == OP_BUY ) {
                if( take <= MarketInfo(Symbol(), MODE_BID) ) {
                    M_OrderComment(M_OrderComment() + "_[tp]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_BID), m_slippage);
                    continue;
                }
            } else if( type == OP_SELL ) {
                if( take >= MarketInfo(Symbol(), MODE_ASK) ) {
                    M_OrderComment(M_OrderComment() + "_[tp]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_ASK), m_slippage);
                    continue;
                }
            }
        }
        // Check limit and stop orders
        if( type != OP_BUY && type != OP_SELL ) { // it's Limit or Stop order.
            double openPrice = m_currentOrder.m_openPrice;
            double orderSlippage = m_currentOrder.m_slippage * MarketInfo(Symbol(), MODE_TICKVALUE);
            if( type == OP_BUYLIMIT || type == OP_BUYSTOP ) {
                double _ask = MarketInfo(Symbol(), MODE_ASK);
                if( openPrice - orderSlippage <= _ask ) { // openPrice(+-slippage) == ask
                    if( openPrice + orderSlippage >= _ask ) { 
                        m_currentOrder.m_type = OP_BUY;
                        m_currentOrder.m_openPrice = _ask;
                        m_currentOrder.m_openTime = TimeCurrent();
                    }
                }
            } else if( type == OP_SELLLIMIT || type == OP_SELLSTOP ) {
                double _bid = MarketInfo(Symbol(), MODE_BID);
                if( openPrice - orderSlippage <= _bid ) { // openPrice(+-slippage) == bid
                    if( openPrice + orderSlippage >= _bid ) {
                        m_currentOrder.m_type = OP_SELL;
                        m_currentOrder.m_openPrice = _bid;
                        m_currentOrder.m_openTime = TimeCurrent();
                    }
                }
            }
        }
    } // for orders.total
    // Close all orders when negative balance
    const double _balance = GetAccountBalance(VIRTUAL_TRADE);
    const double _losses = GetOpenedOrdersNegativeRisk(&this);
    if( _balance <= _losses ) {
        for( int idx = 0; idx < M_OrdersTotal(); idx++ ) {
            M_OrderSelect(idx, SELECT_BY_POS);
            double _closePrice = 0.0;
            if( M_OrderType() == OP_BUY ) {
                _closePrice = MarketInfo(Symbol(), MODE_BID);
            } else if( M_OrderType() == OP_SELL ) {
                _closePrice = MarketInfo(Symbol(), MODE_ASK);
            }
            M_OrderClose(M_OrderTicket(), M_OrderLots(), _closePrice, m_slippage);
        }
    }
};

bool CVirtualTrade::M_OrderClose(int ticket, double lots, double price,
                               int slippage, color arrow_color = CLR_NONE)
{
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    // If not opened
    if( M_OrderType() != OP_BUY && M_OrderType() != OP_SELL ) {
        m_ordersHistory.Add(m_ordersList.DetachCurrent());
        COrder* closed = m_ordersHistory.GetCurrentNode();
        closed.Draw();
        return true;
    }
    // Get market price
    double _closePrice = 0.0;
    if( M_OrderType() == OP_BUY ) {
        _closePrice = MarketInfo(M_OrderSymbol(), MODE_BID);
    } else if( M_OrderType() == OP_SELL ) {
        _closePrice = MarketInfo(M_OrderSymbol(), MODE_ASK);
    }
    // Check slippage
    if( MathAbs(price - _closePrice) > (slippage * MarketInfo(Symbol(), MODE_TICKVALUE)) ) {
        Print(__FUNCTION__ + ": Error = Incorrect price.");
        return false;
    }
    // Close order
    if( M_OrderLots() <= lots ) { // close all volume
        m_currentOrder.m_closePrice = _closePrice;
        m_currentOrder.m_closeTime = TimeCurrent();
        m_ordersHistory.Add(m_ordersList.DetachCurrent());
        COrder* closedOrder = m_ordersHistory.GetCurrentNode();
        closedOrder.Draw();
        return true;
    } else { // close part
        m_currentOrder.m_volume -= lots;
        m_ordersHistory.Add(new COrder(M_OrderSymbol(), M_OrderType(),
                                        lots, M_OrderOpenPrice(),
                                        m_slippage, M_OrderStopLoss(),
                                        M_OrderTakeProfit(), M_OrderComment(),
                                        M_OrderMagicNumber(), M_OrderExpiration()));
        COrder* closedOrder = m_ordersHistory.GetCurrentNode();
        closedOrder.m_openTime = m_currentOrder.m_openTime;
        closedOrder.m_closePrice = _closePrice;
        closedOrder.m_closeTime = TimeCurrent();
        closedOrder.Draw();
        return true;
    }
};

bool CVirtualTrade::M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE)
{
    COrder *orderOpened, *orderClosed;
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    orderClosed = m_currentOrder;
    M_OrderSelect(opposite, SELECT_BY_TICKET);
    orderOpened = m_currentOrder;
    // GOTO: implementation
    return false;
};

double CVirtualTrade::M_OrderClosePrice() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_closePrice;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0.0;
};

datetime CVirtualTrade::M_OrderCloseTime() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_closeTime;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

string CVirtualTrade::M_OrderComment(const string newComment = "")
{
    if( m_currentOrder != NULL ) {
        if( newComment != "" ) { // For log with virtual trade
            m_currentOrder.m_comment = newComment;
        }
        return m_currentOrder.m_comment;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return "";
};

double CVirtualTrade::M_OrderCommission() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_commission;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0.0;
};

bool CVirtualTrade::M_OrderDelete(int ticket, color arrow_color = CLR_NONE)
{
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    if( m_currentOrder == NULL ) {
        Print(__FUNCTION__ + ": Error = Order not found.");
        return false;
    }
    if( m_currentOrder.m_type == OP_BUY || m_currentOrder.m_type == OP_SELL ) {
        Print(__FUNCTION__ + ": Error = The order is already open.");
        return false;
    }
    m_currentOrder.m_comment += "_[del]";
    m_ordersHistory.Add(m_ordersList.DetachCurrent());
    return true;
};

datetime CVirtualTrade::M_OrderExpiration() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_expiration;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

double CVirtualTrade::M_OrderLots() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_volume;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0.0;
};

int CVirtualTrade::M_OrderMagicNumber() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_magicNumber;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0.0;
};

bool CVirtualTrade::M_OrderModify(int ticket, double price, double stoploss,
                                double takeprofit, datetime expiration, color arrow_color = CLR_NONE)
{
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    if( m_currentOrder == NULL ) {
        Print(__FUNCTION__ + ": Error = Order not found.");
        return false;
    }
    if( m_currentOrder.m_closePrice > 0.0 ) {
        Print(__FUNCTION__ + ": Error = Order is closed.");
        return false;
    }
    if( m_currentOrder.m_stopLoss == stoploss ) {
        if( m_currentOrder.m_takeProfit == takeprofit ) {
            if( m_currentOrder.m_expiration == expiration ) {
                if( m_currentOrder.m_openPrice == price ) {
                    Print(__FUNCTION__ + ": Error = Parameters is equal.");
                    return false;
                }
            }
        }
    }
    m_currentOrder.m_stopLoss = stoploss;
    m_currentOrder.m_takeProfit = takeprofit;
    if( m_currentOrder.m_type != OP_BUY && m_currentOrder.m_type != OP_SELL ) {
        m_currentOrder.m_openPrice = price;
        m_currentOrder.m_expiration = expiration;
    }
    m_currentOrder.Draw();
    return true;
};

double CVirtualTrade::M_OrderOpenPrice() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_openPrice;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0.0;
};

datetime CVirtualTrade::M_OrderOpenTime() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_openTime;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

void CVirtualTrade::M_OrderPrint() const
{
    if( m_currentOrder != NULL ) {
        COrder* _co = m_currentOrder;
        PrintFormat("#%d, %s, %s, %f, %s, %f, %f, %f, %s, %f, %f, %f, %f, %s, %d, %s", 
                        _co.m_ticket, _co.m_openTime, _co.m_type, _co.m_volume,
                        _co.m_symbol, _co.m_openPrice, _co.m_stopLoss, _co.m_takeProfit,
                        _co.m_closeTime, _co.m_closePrice, _co.m_commission, _co.m_swap,
                        M_OrderProfit(), _co.m_comment, _co.m_magicNumber, _co.m_expiration);
    } // GOTO: type
    // #номер тикета; время открытия; торговая операция; 
    //  количество лотов; символ; цена открытия; стоп лосс; тейк профит; 
    //  время закрытия; цена закрытия; комиссия; своп; прибыль; комментарий; 
    //  магическое число; дата истечения отложенного ордера
    Print(__FUNCTION__ + ": Error = Current order not found.");
};

double CVirtualTrade::M_OrderProfit() const
{
    if( m_currentOrder != NULL ) {
        if( m_currentOrder.m_type != OP_BUY && m_currentOrder.m_type != OP_SELL ) {
            return 0.0;
        }
        double result = 0.0;
        if( m_currentOrder.m_closePrice > 0.0 ) { // Order is closed
            result = m_currentOrder.m_openPrice - m_currentOrder.m_closePrice;
            if( m_currentOrder.m_type == OP_BUY ) {
                result *= -1;
            }
        } else { // Order is opened
            if( m_currentOrder.m_type == OP_BUY ) {
                result = MarketInfo(Symbol(), MODE_BID) - m_currentOrder.m_openPrice;
            } else {
                result = m_currentOrder.m_openPrice - MarketInfo(Symbol(), MODE_ASK);
            }
        }
        return Convert(result, StringSubstr(m_currentOrder.m_symbol, 3, 3), AccountCurrency());
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0.0;
};

bool CVirtualTrade::M_OrderSelect(int index, int select, int pool = MODE_TRADES)
{
    if( select == SELECT_BY_POS ) {
        if( pool == MODE_TRADES ) {
            m_currentOrder = m_ordersList.GetNodeAtIndex(index);
        } else if( pool == MODE_HISTORY ) {
            m_currentOrder = m_ordersHistory.GetNodeAtIndex(index);
        }
        if( m_currentOrder != NULL ) {
            return true;
        }
    } else if( select == SELECT_BY_TICKET ) {
        for( int idx = 0; idx < m_ordersList.Total(); idx++ ) {
            m_currentOrder = m_ordersList.GetNodeAtIndex(idx);
            if( index == m_currentOrder.m_ticket ) {
                return true;
            }
        }
        for( int idx = 0; idx < m_ordersHistory.Total(); idx++ ) {
            m_currentOrder = m_ordersHistory.GetNodeAtIndex(idx);
            if( index == m_currentOrder.m_ticket ) {
                return true;
            }
        }
    }
    m_currentOrder = NULL;
    Print(__FUNCTION__ + ": Error = Order not found.");
    return false;
};

int CVirtualTrade::M_OrderSend(string symbol, int cmd, double volume,
                             double price, int slippage, double stoploss,
                             double takeprofit, string comment = NULL, int magic = 0,
                             datetime expiration = 0, color arrow_color = clrNONE)
{
    if( price <= 0.0 || volume <= 0.0 ) {
        Print(__FUNCTION__ + ": Error = Wrong price.");
        return -1;
    }
    if( cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP ) {
        if( (stoploss > 0.0 && price <= stoploss) ||
            (takeprofit > 0.0 && price >= takeprofit) ) {
                Print(__FUNCTION__ + ": Error = Wrong stop levels.");
        }
    } else {
        if( (stoploss > 0.0 && price >= stoploss) ||
            (takeprofit > 0.0 && price <= takeprofit) ) {
                Print(__FUNCTION__ + ": Error = Wrong stop levels.");
        }
    }
    m_ordersList.Add(new COrder(symbol, cmd, volume, price, slippage, stoploss, 
                                takeprofit, comment, magic, expiration));
    m_currentOrder = m_ordersList.GetCurrentNode();
    m_currentOrder.Draw();
    return m_currentOrder.m_ticket;
};

int CVirtualTrade::M_OrdersHistoryTotal() const
{
    return m_ordersHistory.Total();
};

double CVirtualTrade::M_OrderStopLoss() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_stopLoss;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

int CVirtualTrade::M_OrdersTotal() const
{
    return m_ordersList.Total();
};

double CVirtualTrade::M_OrderSwap() const
{
    // GOTO: calculate swap from Marketinfo(MODE_SWAPLONG, MODE_SWAPSHORT, MODE_SWAPTYPE)
    return 0.0;
};

string CVirtualTrade::M_OrderSymbol() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_symbol;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return "";
};

double CVirtualTrade::M_OrderTakeProfit() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_takeProfit;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

int CVirtualTrade::M_OrderTicket() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_ticket;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

int CVirtualTrade::M_OrderType() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_type;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return -1;
};


//+---------------------------------------------------------------------------+
//|   C V I R T U A L _ S T O P S   C L A S S   I M P L E M E N T A T I O N   |
//+---------------------------------------------------------------------------+
void CVirtualStops::CVirtualStops() : CMarket()
{
    LoadOpenedOrders();
    LoadHistoryOrders();
};

void CVirtualStops::CVirtualStops(const int slippage, const string folder = "", const int magic = 0) : 
        CMarket(slippage, folder, magic)
{
    LoadOpenedOrders();
    LoadHistoryOrders();
};

void CVirtualStops::~CVirtualStops()
{
    SaveOpenedOrders();
    SaveHistoryOrders();
    m_ordersList.Clear();
    m_ordersHistory.Clear();
    ObjectsDeleteAll(0, ORDER_PREFIX);
};

void CVirtualStops::LoadOpenedOrders(const string postfix = "_orders.csv")
{
    string filePath = StringConcatenate(Symbol(), postfix);
    int hFile = FileOpen(filePath, FILE_READ | FILE_CSV | FILE_SHARE_READ, StringGetChar(";", 0));
    if( hFile != INVALID_HANDLE ) {
        while( !FileIsEnding(hFile) ) {
            m_ordersList.Add(new COrder());
            COrder* _order = m_ordersList.GetCurrentNode();
            _order.Load(hFile);
            // _order.Draw();
        }
        FileClose(hFile);
    }
    for( int idx = 0; idx < m_ordersList.Total(); idx++ ) {
        // GOTO: filtrate virt and real opened orders
        // OrderSelect()
    }
};

void CVirtualStops::M_OnTick()
{
    for( int idx = 0; idx < M_OrdersTotal(); idx++ ) {
        M_OrderSelect(idx, SELECT_BY_POS);
        if( M_OrderSymbol() != Symbol() ) {
            continue;
        }
        if( M_OrderExpiration() <= TimeCurrent() ) {
            double _closePrice = 0.0;
            if( M_OrderType() == OP_BUY ) {
                _closePrice = MarketInfo(Symbol(), MODE_BID);
            } else if( M_OrderType() == OP_SELL ) {
                _closePrice = MarketInfo(Symbol(), MODE_ASK);
            }
            M_OrderClose(M_OrderTicket(), M_OrderLots(), _closePrice, m_slippage);
            continue;
        }
        const int ticket = M_OrderTicket();
        const int type = M_OrderType();
        const double stop = M_OrderStopLoss();
        const double take = M_OrderTakeProfit();
        const double vol = M_OrderLots();
        // Check stop levels
        if( stop > 0.0 ) { // Check the break of stop levels.
            if( type == OP_BUY ) {
                if( stop >= MarketInfo(Symbol(), MODE_BID) ) {
                    M_OrderComment(M_OrderComment() + "_[sl]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_BID), m_slippage);
                    continue;
                }
            } else if( type == OP_SELL ) {
                if( stop <= MarketInfo(Symbol(), MODE_ASK) ) {
                    M_OrderComment(M_OrderComment() + "_[sl]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_ASK), m_slippage);
                    continue;
                }
            }
        }
        if( take > 0.0 ) { // Check the break of take levels.
            if( type == OP_BUY ) {
                if( take <= MarketInfo(Symbol(), MODE_BID) ) {
                    M_OrderComment(M_OrderComment() + "_[tp]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_BID), m_slippage);
                    continue;
                }
            } else if( type == OP_SELL ) {
                if( take >= MarketInfo(Symbol(), MODE_ASK) ) {
                    M_OrderComment(M_OrderComment() + "_[tp]");
                    M_OrderClose(ticket, vol, MarketInfo(Symbol(), MODE_ASK), m_slippage);
                    continue;
                }
            }
        }
    } // for orders.total
};

bool CVirtualStops::M_OrderClose(int ticket, double lots, double price,
                               int slippage, color arrow_color = CLR_NONE)
{
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    bool result = OrderClose(ticket, lots, price, slippage, arrow_color);
    if( result ) {
        // If not opened
        if( M_OrderType() != OP_BUY && M_OrderType() != OP_SELL ) {
            m_ordersHistory.Add(m_ordersList.DetachCurrent());
            COrder* closed = m_ordersHistory.GetCurrentNode();
            closed.Draw();
            return true;
        }
        // Get market price
        double _closePrice = 0.0;
        if( M_OrderType() == OP_BUY ) {
            _closePrice = MarketInfo(M_OrderSymbol(), MODE_BID);
        } else if( M_OrderType() == OP_SELL ) {
            _closePrice = MarketInfo(M_OrderSymbol(), MODE_ASK);
        }
        // Check slippage
        if( MathAbs(price - _closePrice) > (slippage * MarketInfo(Symbol(), MODE_TICKVALUE)) ) {
            Print(__FUNCTION__ + ": Error = Incorrect price.");
        }
        // Close order
        if( M_OrderLots() <= lots ) { // close all volume
            m_currentOrder.m_closePrice = _closePrice;
            m_currentOrder.m_closeTime = TimeCurrent();
            m_ordersHistory.Add(m_ordersList.DetachCurrent());
            COrder* closedOrder = m_ordersHistory.GetCurrentNode();
            closedOrder.Draw();
        } else { // close part
            m_currentOrder.m_volume -= lots;
            m_ordersHistory.Add(new COrder(m_currentOrder.m_symbol, m_currentOrder.m_type,
                                            lots, m_currentOrder.m_openPrice,
                                            m_slippage, m_currentOrder.m_stopLoss,
                                            m_currentOrder.m_takeProfit, m_currentOrder.m_comment,
                                            m_currentOrder.m_magicNumber, m_currentOrder.m_expiration));
            COrder* closedOrder = m_ordersHistory.GetCurrentNode();
            closedOrder.m_openTime = m_currentOrder.m_openTime;
            closedOrder.m_closePrice = _closePrice;
            closedOrder.m_closeTime = TimeCurrent();
            closedOrder.Draw();
        }
    } else {
        Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
    }
    return result;
};

bool CVirtualStops::M_OrderCloseBy(int ticket, int opposite, color arrow_color = CLR_NONE)
{
    COrder *orderOpened, *orderClosed;
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    orderClosed = m_currentOrder;
    M_OrderSelect(opposite, SELECT_BY_TICKET);
    orderOpened = m_currentOrder;
    // do real
    bool result = OrderCloseBy(ticket, opposite, arrow_color);
    if( result ) { // do virt
        // GOTO: virt to histlist
    }
    return result;
};

double CVirtualStops::M_OrderClosePrice() const
{
    return OrderClosePrice();
};

datetime CVirtualStops::M_OrderCloseTime() const
{
    return OrderCloseTime();
};

string CVirtualStops::M_OrderComment(const string newComment = "")
{
    if( m_currentOrder != NULL ) {
        if( newComment != "" ) { // For log with virtual trade
            m_currentOrder.m_comment = newComment;
        }
        return m_currentOrder.m_comment;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return "";
};

double CVirtualStops::M_OrderCommission() const
{
    return OrderCommission();
};

bool CVirtualStops::M_OrderDelete(int ticket, color arrow_color = CLR_NONE)
{
    M_OrderSelect(ticket, SELECT_BY_TICKET);
    bool result = OrderDelete(ticket, arrow_color);
    if( result ) {
        M_OrderComment(M_OrderComment() + "_[del]");
        m_ordersHistory.Add(m_ordersList.DetachCurrent());
    }
    return result;
};

datetime CVirtualStops::M_OrderExpiration() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_expiration;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

double CVirtualStops::M_OrderLots() const
{
    return OrderLots();
};

int CVirtualStops::M_OrderMagicNumber() const
{
    return OrderMagicNumber();
};

bool CVirtualStops::M_OrderModify(int ticket, double price, double stoploss,
                                double takeprofit, datetime expiration, color arrow_color = CLR_NONE)
{
    // M_OrderSelect(ticket, SELECT_BY_TICKET); // caution!
    bool result = false;
    int _realOrder = OrderType();
    if( _realOrder != OP_BUY && _realOrder != OP_SELL ) {
        if( OrderOpenPrice() != price ) {
            result = OrderModify(ticket, price, 0, 0, 0, arrow_color);
        }
    }
    if( result ) {
        m_currentOrder.m_stopLoss = stoploss;
        m_currentOrder.m_takeProfit = takeprofit;
        if( m_currentOrder.m_type != _realOrder ) {
            m_currentOrder.m_type = _realOrder;
            m_currentOrder.m_openPrice = OrderOpenPrice();
            m_currentOrder.m_openTime = OrderOpenTime();
            m_currentOrder.m_closePrice = OrderClosePrice();
            m_currentOrder.m_closeTime = OrderCloseTime();
        }
        if( m_currentOrder.m_type != OP_BUY && m_currentOrder.m_type != OP_SELL ) {
            m_currentOrder.m_openPrice = price;
            m_currentOrder.m_expiration = expiration;
        }
        m_currentOrder.Draw();
    }
    return result;
};

double CVirtualStops::M_OrderOpenPrice() const
{
    return OrderOpenPrice();
};

datetime CVirtualStops::M_OrderOpenTime() const
{
    return OrderOpenTime();
};

void CVirtualStops::M_OrderPrint() const
{
    OrderPrint();
};

double CVirtualStops::M_OrderProfit() const
{
    return OrderProfit();
};

bool CVirtualStops::M_OrderSelect(int index, int select, int pool = MODE_TRADES)
{
    // Find real order
    bool result = OrderSelect(index, select, pool);
    // Finf virtual order
    for( int idx = 0; idx < m_ordersList.Total(); idx++ ) {
        m_currentOrder = m_ordersList.GetNodeAtIndex(idx);
        if( m_currentOrder.m_ticket == M_OrderTicket() ) {
            return result;
        }
    }
    for( int idx = 0; idx < m_ordersHistory.Total(); idx++ ) {
        m_currentOrder = m_ordersHistory.GetNodeAtIndex(idx);
        if( m_currentOrder.m_ticket == M_OrderTicket() ) {
            return result;
        }
    }
    m_currentOrder = NULL;
    Print(__FUNCTION__ + ": Error = Virtual Order not found.");
    return result;
};

int CVirtualStops::M_OrderSend(string symbol, int cmd, double volume,
                             double price, int slippage, double stoploss,
                             double takeprofit, string comment = NULL, int magic = 0,
                             datetime expiration = 0, color arrow_color = clrNONE)
{
    if( cmd == OP_BUY || cmd == OP_BUYLIMIT || cmd == OP_BUYSTOP ) {
        if( (stoploss > 0.0 && price <= stoploss) ||
            (takeprofit > 0.0 && price >= takeprofit) ) {
                Print(__FUNCTION__ + ": Error = Wrong stop levels.");
        }
    } else {
        if( (stoploss > 0.0 && price >= stoploss) ||
            (takeprofit > 0.0 && price <= takeprofit) ) {
                Print(__FUNCTION__ + ": Error = Wrong stop levels.");
        }
    }
    int _ticket = OrderSend(symbol, cmd, volume, NormalizeDouble(price, Digits),
                            slippage, 0, 0, comment, magic, 0, arrow_color);
    if( _ticket >= 0 ) {
        m_ordersList.Add(new COrder(symbol, cmd, volume, NormalizeDouble(price, Digits),
                                    slippage, stoploss, takeprofit, comment,
                                    magic, expiration));
        m_currentOrder = m_ordersList.GetCurrentNode();
        m_currentOrder.m_ticket = _ticket;
        m_currentOrder.Draw();
    }
    return _ticket;
};

int CVirtualStops::M_OrdersHistoryTotal() const
{
    return OrdersHistoryTotal();
};

double CVirtualStops::M_OrderStopLoss() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_stopLoss;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

int CVirtualStops::M_OrdersTotal() const
{
    return OrdersTotal();
};

double CVirtualStops::M_OrderSwap() const
{
    return OrderSwap();
};

string CVirtualStops::M_OrderSymbol() const
{
    return OrderSymbol();
};

double CVirtualStops::M_OrderTakeProfit() const
{
    if( m_currentOrder != NULL ) {
        return m_currentOrder.m_takeProfit;
    }
    Print(__FUNCTION__ + ": Error = Current order not found.");
    return 0;
};

int CVirtualStops::M_OrderTicket() const
{
    return OrderTicket();
};

int CVirtualStops::M_OrderType() const
{
    return OrderType();
};

/*
//=====================/ isDayTimeFilter /====================================/
//! Фильтрация по времени
bool SessionIsOpened(ulong start_session, ulong stop_session)
{
	ulong curr      = TimeCurrent() % 86400;
	start_session   = start_session % 86400;
	stop_session    = stop_session % 86400;
	return ((curr >= start_session) && (curr < stop_session)) || !((curr>= start_session) ||(curr < stop_session));
};
//========================/ CloseOrders /=====================================/
//! Закрывает все открытые ордера в терминале
//! @return Возвращает количество закрытых ордеров
int CloseOrders(//! Маска выбора типов
				EOrderTypeMask mask=omAll,
				//! Магическое число
				int magic=0,
				//! Инструмент
				string symbol=NULL)
{
	int i;
	int close_cnt=0;
	mask|=omPoolTrades;
	for(i=OrdersTotal()-1; i>=0; i--) {
		if(!isOrderFilter(GetTicket(i,omPoolTrades),mask,magic,symbol))
			continue;
		if(CloseOrder(OrderTicket())==false)
			continue;
		close_cnt++;
	}//for
	return close_cnt;
};
*/
// ====================================================================================================

// Вот, кажется нашёл решение, очень простая формула получилась. 
// Узнаём плечо по каждому инструменту, в не зависимости от того что написано в AccountLaverage и не зависимо от размера контракта. 
// Работает для метода расчёта форекс:

// MarketInfo(Symbol(),MODE_TICKVALUE) * Bid / MarketInfo(Symbol(),MODE_MARGINREQUIRED) / MarketInfo(Symbol(),MODE_POINT)

//  - �������� ��������, ���� ������� ������ ��� ���(�� �� ����� ������ ��� ���, �� ��� ��� �������� ���� �� ���� �����), �� ��� ���� � ����������� ������ ������� - ������� �� ������� �� ��������. ����� �������� ������ ������ ��� � ���� �� ����������. ��� ����������� � ����� �����?

// =======================================================================================================
