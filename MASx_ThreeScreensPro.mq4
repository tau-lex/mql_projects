//+---------------------------------------------------------------------------+
//|                                                  MASx_ThreeScreensPro.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   ""
#property description   "The ideas of Alexander Elder, Aleksey Terentyev."
#property version       "2.7"
#property strict

#include                "MASh_Include.mqh"

#define   TEST


//+---------------------------------------------------------------------------+
//|   G L O B A L   V A R I A B L E S                                         |
//+---------------------------------------------------------------------------+
//---
input int       EMA_FAST = 13;              // EMA Fast
input int       EMA_SLOW = 26;              // EMA Slow
input int       MACD_FAST = 12;             // MACD Fast
input int       MACD_SLOW = 26;             // MACD Slow
input int       MACD_SIGNAL = 9;            // MACD Signal
input double    SIGNAL_GATE = 0.5;          // Gate for signal range
input double    STOP_MEAN = 3.0;            // Mean deviation (Factor) for ordering a protect
input int       ORDER_RISK = 2;             // Max risk per one order (%)
input int       MONTH_RISK = 6;             // Max risk per month (%)
input OrderType TRADE_TYPE = VIRTUAL;       // Trades type
input string    COMMENT = "MASx_TSPro";     // Comment
input int       SLIPPAGE = 3;               // Slippage
input string    DIRECTORY = "TSPro";        // Path to all files ($_MT4_dir_$/MQL4/Files/.../)
//---
const int       SEARCH_LEN      = 120;      // Lenght of peacks search
const int       SEARCH_LEN_Z    = 90;       // Lenght of zero check
//---
double          buffMACDScrn1[], buffMACDHistScrn1[];
double          buffMACDScrn2[], buffMACDHistScrn2[];


//+---------------------------------------------------------------------------+
//|   M A I N   F U N C T I O N S                                             |
//+---------------------------------------------------------------------------+
int OnInit()
{
    ArrayResize(buffMACDScrn1, 200);
    // ArrayResize(buffSignalScrn1, Bars);
    ArrayResize(buffMACDHistScrn1, 200);
    ArrayResize(buffMACDScrn2, 200);
    // ArrayResize(buffSignalScrn2, Bars);
    ArrayResize(buffMACDHistScrn2, 200);
    if( EMA_SLOW <= 1 || EMA_FAST <= 1 || MACD_FAST <= 1 || MACD_SLOW <= 1 || 
            MACD_SIGNAL <= 1 || MACD_FAST >= MACD_SLOW ) {
        Print( "Wrong input parameters" );
        return INIT_FAILED;
    }
    M_OrdersInitialize(TRADE_TYPE, DIRECTORY, clrLimeGreen, clrOrangeRed);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    static double signal;
    if( NewBar() ) {
        // I
        signal = CalculateStrategy();
        // II
        CalculateOrder(signal);
        // III
        ManageOpenedOrders(signal);
        // _DEBUG_
        Print("_DEBUG_ | signal: "+signal);
        Print("_DEBUG_ | Opened/History: "+_ORDERS_LIST.Total()+"/"+_ORDERS_HISTORY.Total());
        Print("_DEBUG_+-----------------------+");
    }
    M_OrdersOnTick();
}

void OnDeinit(const int reason)
{
    M_OrdersDeinitialize(DIRECTORY);
}


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
double CalculateStrategy()
{
    // Update indicators data
    // CalculateMACD();
    double signalsArray[3];
    for( int idx = 0; idx < 3; idx++ ) {
        signalsArray[idx] = iImpulse(idx, Symbol(), Period(), EMA_FAST, MACD_FAST, MACD_SLOW, MACD_SIGNAL);
        // signalsArray[idx] = ThreeScreensMod( idx );
        // signalsArray[idx] += ThreeScreens_v1_2( idx, Symbol(), Period(), EMA_SLOW, EMA_FAST, MACD_FAST, MACD_SLOW, MACD_SIGNAL );
    }
    return Mean(Arithmetic, signalsArray);
}

int CalculateOrder(const double signal, const double signalLimit = 0.5)
{
    if( MathAbs(signal)-signalLimit <= 0 ) {
        return -1;
    }
    int orderType = signal > 0.0 ? OP_BUY : OP_SELL;
    // Поиск уровней и точек входа
    double orderLimitPrice = 0.0, orderTakeProfit = -1.0, orderStopLoss = -1.0;
    if( orderType == OP_BUY ) {
        orderLimitPrice = MarketInfo(Symbol(), MODE_ASK);
    } else if( orderType == OP_SELL ) {
        orderLimitPrice = MarketInfo(Symbol(), MODE_BID);
    }
    orderTakeProfit = GetTakeProfit(0, orderType);
    orderStopLoss   = GetStopLoss(0, orderType);
    // Управление риском
    //// список ордеров / подсчет риска / решение
    double riskBalanceOrder = AccountBalance() * ORDER_RISK * 0.01;
    double riskBalanceMonth = GetBalanceFirstNum() * MONTH_RISK * 0.01;
    double riskBuyLot       = GetRiskBuyLot(orderLimitPrice, orderStopLoss);
    double orderLot         = GetLotSize(riskBuyLot, riskBalanceOrder);
    double openedRiskSum    = 0.0, openedCommision = 0.0;
    for( int idx = 0; idx < M_OrdersTotal(); idx++ ) {
        if( M_OrderSelect(idx, SELECT_BY_POS) ) {
            int     openedType      = M_OrderType();
            double  openedOpenPrice = M_OrderOpenPrice();
            double  openedStopLoss  = M_OrderStopLoss();
            if( openedType == OP_BUY || openedType == OP_SELL ) {
                openedRiskSum += MathAbs(openedOpenPrice - openedStopLoss);
                openedCommision += M_OrderCommission() + M_OrderSwap();
            }
        } else {
            Print(__FUNCTION__ + ": Error = " + IntegerToString(GetLastError()) );
        }
    }
    openedRiskSum = openedCommision + Convert(openedRiskSum,
                                                StringSubstr(Symbol(), 3, 3),
                                                AccountCurrency());
    Print("_DEBUG_ | orderLimitPrice/orderStopLoss: "+orderLimitPrice+"/"+orderStopLoss);
    Print("_DEBUG_ | riskBuyLot/riskBalanceOrder/riskBalanceMonth: "+riskBuyLot+"/"+riskBalanceOrder+"/"+riskBalanceMonth);
    Print("_DEBUG_ | orderLot: "+orderLot);

    if( openedRiskSum + riskBuyLot * orderLot >= riskBalanceMonth ) {
        Print("_DEBUG_ | Risk > 6% per month: "+(openedRiskSum+riskBuyLot*orderLot));
        return -2;
    }
    if( riskBuyLot * orderLot >= riskBalanceOrder ) {
        Print("_DEBUG_ | Risk > 2% per order "+(riskBuyLot*orderLot));
        return -2;
    }
    // Открытие лимитного ордера
    datetime    orderExpiration = TimeCurrent() + 86400; // 86400 sec = 1 day
    if( orderType == OP_BUY ) {
        orderType = OP_BUYLIMIT;
    } else if( orderType == OP_SELL ) {
        orderType = OP_SELLLIMIT;
    }
    int orderTicket = M_OrderSend(Symbol(), orderType, orderLot, orderLimitPrice, SLIPPAGE,
                                  orderStopLoss, orderTakeProfit, COMMENT, 0, orderExpiration);
    Print("_DEBUG_ | New order ticket: "+orderTicket);
    if( orderTicket < 0 ) {
        Print(__FUNCTION__ + ": Error = " + IntegerToString(GetLastError()) );
    }
    return orderTicket;
}

int ManageOpenedOrders(const double signal, const double signalLimit = 0.5)
{
    int         oTicket, oType;
    double      oLots, oOpenPrice, oStopLoss, oTakeProfit;
    datetime    oExpiration;
    for( int idx = 0; idx < M_OrdersTotal(); idx++ ) {
        if( !M_OrderSelect(idx, SELECT_BY_POS) ) {
            Print(__FUNCTION__ + ": " + "OrderSelect(): " + IntegerToString(GetLastError()) );
        }
        if( M_OrderSymbol() != Symbol() ||
            M_OrderComment() != COMMENT ) {
                continue;
        }
        oTicket     = M_OrderTicket();
        oType       = M_OrderType();
        oLots       = M_OrderLots();
        oOpenPrice  = M_OrderOpenPrice();
        oTakeProfit = M_OrderTakeProfit();
        oStopLoss   = M_OrderStopLoss();
        oExpiration = M_OrderExpiration();
        // Проверка уровней защиты
        if( oType == OP_BUY ) {
            if( oStopLoss >= Bid || Bid >= oTakeProfit ) {
                if( M_OrderClose(oTicket, oLots, Bid, SLIPPAGE) ) {
                    Print(__FUNCTION__ + ": " + "OrderClose()(1): " + IntegerToString(GetLastError()) );
                }
                Print("_DEBUG_ | close order: "+oTicket);
                continue;
            }
            if( signal < -MathAbs(signalLimit) ) {
                if( M_OrderClose(oTicket, oLots, Bid, SLIPPAGE) ) {
                    Print(__FUNCTION__ + ": " + "OrderClose()(2): " + IntegerToString(GetLastError()) );
                }
            }
        } else if( oType == OP_SELL ) {
            if( oTakeProfit >= Ask || Ask >= oStopLoss ) {
                if( M_OrderClose(oTicket, oLots, Ask, SLIPPAGE) ) {
                    Print(__FUNCTION__ + ": " + "OrderClose()(3): " + IntegerToString(GetLastError()) );
                }
                Print("_DEBUG_ | close order: "+oTicket);
                continue;
            }
            if( signal > MathAbs(signalLimit) ) {
                if( M_OrderClose(oTicket, oLots, Ask, SLIPPAGE) ) {
                    Print(__FUNCTION__ + ": " + "OrderClose()(4): " + IntegerToString(GetLastError()) );
                }
            }
        }
        // Проверка обновлений уровней защиты
        double newTP = oTakeProfit, newSL = oStopLoss;
        if( oType == OP_BUY ) {
            // if( GetTakeProfit(0, OP_BUY) > oTakeProfit ) {
            //     newTP = GetTakeProfit(0, OP_BUY);
            // }
            if( GetStopLoss(0, OP_BUY) > oStopLoss ) {
                newSL = GetStopLoss(0, OP_BUY);
            }
        } else if( oType == OP_SELL ) {
            // if( GetTakeProfit(0, OP_SELL) < oTakeProfit ) {
            //     newTP = GetTakeProfit(0, OP_SELL);
            // }
            if( GetStopLoss(0, OP_SELL) < oStopLoss ) {
                newSL = GetStopLoss(0, OP_SELL);
            }
        }
        if( newTP != oTakeProfit || newSL != oStopLoss ) {
            if( !M_OrderModify(oTicket, oOpenPrice, newSL, newTP, oExpiration) ) {
                Print(__FUNCTION__ + ": " + "OrderModify(): " + IntegerToString(GetLastError()) );
            }
            continue;
        }
        // Проверка срока действия ордера
        if( oExpiration <= TimeCurrent() ) {
            if( !M_OrderClose(oTicket, 0, 0, 0) ) {
                Print(__FUNCTION__ + ": " + "OrderClose()(5): " + IntegerToString(GetLastError()) );
            }
            Print("_DEBUG_ | close order(exp): "+oTicket);
            continue;
        }
    }
    return 0;
}


//+---------------------------------------------------------------------------+
//|   L E V E L S   F U N C T I O N S                                         |
//+---------------------------------------------------------------------------+
double GetTakeProfit(const int bar, const int orderType)
{
    if( orderType == OP_BUY ) {
        return iKeltnerChannel(bar, Symbol(), Period(), 26, Higher, Modified_2, 130);
    } else if( orderType == OP_SELL ) {
        double spread = 0.0;
        spread = MarketInfo(Symbol(), MODE_SPREAD) * MarketInfo(Symbol(), MODE_POINT);
        return iKeltnerChannel(bar, Symbol(), Period(), 26, Lower, Modified_2, 130) + spread;
    }
    return -1.0;
}

double GetStopLoss(const int bar, const int orderType)
{
    if( orderType == OP_BUY ) {
        return StopBuyMax(bar, Symbol(), Period(), STOP_MEAN);
    } else if( orderType == OP_SELL ) {
        return StopSellMin(bar, Symbol(), Period(), STOP_MEAN);
    }
    return -1.0;
}


//+---------------------------------------------------------------------------+
//|   M A C D   D I V E R G E N C E   F U N C T I O N S                       |
//+---------------------------------------------------------------------------+
double ThreeScreensMod(const int bar)
{
    double buyPrice = MarketInfo( Symbol(), MODE_BID );
    double sellPrice = MarketInfo( Symbol(), MODE_ASK );
    double tmpArray3[3];
    double impulseScrn1, impulseScrn2;
    double emaFast0Scrn1, emaFast1Scrn1, emaSlow0Scrn1, emaSlow1Scrn1;
    double emaFast0Scrn2, emaFast1Scrn2, emaSlow0Scrn2, emaSlow1Scrn2;
    double divergenceScrn1, divergenceScrn2;
    double trendForce = 0.0;
    
    ArraySetAsSeries( buffMACDScrn1, true );
    ArraySetAsSeries( buffMACDScrn2, true );
    ArraySetAsSeries( buffMACDHistScrn1, true );
    ArraySetAsSeries( buffMACDHistScrn2, true );
    // Calculate Screen #1
    tmpArray3[0] = iImpulse( bar,   Symbol(), Period(), 19*5, MACD_FAST*5, MACD_SLOW*5, MACD_SIGNAL*5 );
    tmpArray3[1] = iImpulse( bar+2, Symbol(), Period(), 19*5, MACD_FAST*5, MACD_SLOW*5, MACD_SIGNAL*5 );
    tmpArray3[2] = iImpulse( bar+4, Symbol(), Period(), 19*5, MACD_FAST*5, MACD_SLOW*5, MACD_SIGNAL*5 );
    impulseScrn1 = Mean( Arithmetic, tmpArray3 );
    emaFast0Scrn1 = iMA( Symbol(), Period(), EMA_FAST*5, 0, MODE_EMA, PRICE_CLOSE, bar );
    emaFast1Scrn1 = iMA( Symbol(), Period(), EMA_FAST*5, 0, MODE_EMA, PRICE_CLOSE, bar+4 );
    emaSlow0Scrn1 = iMA( Symbol(), Period(), EMA_SLOW*5, 0, MODE_EMA, PRICE_CLOSE, bar );
    emaSlow1Scrn1 = iMA( Symbol(), Period(), EMA_SLOW*5, 0, MODE_EMA, PRICE_CLOSE, bar+4 );
    divergenceScrn1 = SearchDivergence( bar, buffMACDHistScrn1, buffMACDScrn1 );
    // Calculate Screen #2
    impulseScrn2 = iImpulse( bar, Symbol(), Period(), 13, MACD_FAST, MACD_SLOW, MACD_SIGNAL );
    emaFast0Scrn2 = iMA( Symbol(), Period(), EMA_FAST, 0, MODE_EMA, PRICE_CLOSE, bar );
    emaFast1Scrn2 = iMA( Symbol(), Period(), EMA_FAST, 0, MODE_EMA, PRICE_CLOSE, bar+4 );
    emaSlow0Scrn2 = iMA( Symbol(), Period(), EMA_SLOW, 0, MODE_EMA, PRICE_CLOSE, bar );
    emaSlow1Scrn2 = iMA( Symbol(), Period(), EMA_SLOW, 0, MODE_EMA, PRICE_CLOSE, bar+4 );
    divergenceScrn2 = SearchDivergence( bar, buffMACDHistScrn2, buffMACDScrn2 );
    // Logics calculate
    if( emaSlow1Scrn1 - emaSlow0Scrn1 < 0 ) {
        trendForce += 0.7;
    } else if( emaSlow1Scrn1 - emaSlow0Scrn1 > 0 ) {
        trendForce -= 0.7;
    }

    return divergenceScrn1 + divergenceScrn2;
}

int CalculateMACD(const int bar = 0)
{
    ArraySetAsSeries( buffMACDScrn1, true );
    ArraySetAsSeries( buffMACDScrn2, true );
    ArraySetAsSeries( buffMACDHistScrn1, true );
    ArraySetAsSeries( buffMACDHistScrn2, true );
    static int limit = 200-1;
    for( int idx = limit; idx <= 0; idx-- ) {
        buffMACDScrn1[idx] = iMACD( Symbol(), Period(), MACD_FAST*5, MACD_SLOW*5, MACD_SIGNAL*5, PRICE_CLOSE, MODE_MAIN, idx );
        buffMACDScrn2[idx] = iMACD( Symbol(), Period(), MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE, MODE_MAIN, idx ); 
        // buffMACDHistScrn1[idx] = iMACDHist( Symbol(), Period(), MACD_FAST*5, MACD_SLOW*5, MACD_SIGNAL*5, PRICE_CLOSE, MODE_EMA, idx );
        // buffMACDHistScrn2[idx] = iMACDHist( Symbol(), Period(), MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE, MODE_EMA, idx );
        buffMACDHistScrn1[idx] = iOsMA( Symbol(), Period(), MACD_FAST*5, MACD_SLOW*5, MACD_SIGNAL*5, PRICE_CLOSE, idx );
        buffMACDHistScrn2[idx] = iOsMA( Symbol(), Period(), MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE, idx );
    }
    return 0;
}

double SearchDivergence(const int bar, const double &histogram[],
                        const double &macdLine[] )
{
    double result = 0.0;
    if( CatchBearishDivergence( bar, histogram ) ) {
        result -= 1.0;
    }
    if( CatchBullishDivergence( bar, histogram ) ) {
        result += 1.0;
    }
    if( CatchBearishDivergence( bar, macdLine ) ) {
        result -= 1.0;
    }
    if( CatchBullishDivergence( bar, macdLine ) ) {
        result += 1.0;
    }
    return result;
}

bool CatchBullishDivergence(const int bar, const double &array[],
                            const bool zeroLine = false)
{
    int troughIdx0 = bar;
    if( !IsTrough( troughIdx0, array, zeroLine ) ) {
        return false;
    }
    int troughIdx1 = LastTroughIndex( troughIdx0, array, zeroLine );
    if( troughIdx1 < 0 ) {
        return false;
    }
    int lowIdx0 = ArrayMinValueIndex( Low, bar > 0 ? troughIdx0-1 : 0, 3 );
    int lowIdx1 = ArrayMinValueIndex( Low, troughIdx1-1, 3 );
    if( lowIdx0 < 0 || lowIdx1 < 0 ) {
        return false;
    }
    bool result = false;
    // ON_CLASSIC
    if( array[troughIdx1] < array[troughIdx0] ) {
        if( Low[lowIdx1] > Low[lowIdx0] ) {
            result = true;
        }
    }
    // ON_HIDDEN
    if( array[troughIdx1] > array[troughIdx0] ) {
        if( Low[lowIdx1] < Low[lowIdx0] ) {
            result = true;
        }
    }
    // ON_EXPAND
    double delta = ( MathMin( Open[lowIdx1], Close[lowIdx1] ) - Low[lowIdx1] +
                     MathMin( Open[lowIdx0], Close[lowIdx0] ) - Low[lowIdx0] )
                   / 2.0;
    if( array[troughIdx1] < array[troughIdx0] ) {
        if( MathAbs(Low[lowIdx1] - Low[lowIdx0]) < delta ) {
            result = true;
        }
    }
    return result;
}

bool CatchBearishDivergence(const int bar, const double &array[],
                            const bool zeroLine = false)
{
    int peakIdx0 = bar;
    if( !IsPeak( peakIdx0, array, zeroLine ) ) {
        return false;
    }
    int peakIdx1 = LastPeakIndex( peakIdx0, array, zeroLine );
    if( peakIdx1 < 0 ) {
        return false;
    }
    int highIdx0 = ArrayMaxValueIndex( High, bar > 0 ? peakIdx0-1 : 0, 3 );
    int highIdx1 = ArrayMaxValueIndex( High, peakIdx1-1, 3 );
    if( highIdx0 < 0 || highIdx1 < 0 ) {
        return false;
    }
    bool result = false;
    // ON_CLASSIC
    if( array[peakIdx1] > array[peakIdx0] ) {
        if( High[highIdx1] < High[highIdx0] ) {
            result = true;
        }
    }
    // ON_HIDDEN
    if( array[peakIdx1] < array[peakIdx0] ) {
        if( High[highIdx1] > High[highIdx0] ) {
            result = true;
        }
    }
    // ON_EXPAND
    double delta = ( High[highIdx1] - MathMax( Open[highIdx1], Close[highIdx1] ) +
                     High[highIdx0] - MathMax( Open[highIdx0], Close[highIdx0] ) )
                   / 2.0;
    if( array[peakIdx1] > array[peakIdx0] ) {
        if( MathAbs(High[highIdx1] - High[highIdx0]) < delta ) {
            result = true;
        }
    }
    return result;
}

bool IsPeak(const int bar, const double &array[],
            const bool zeroLine = false)
{   
    if( bar >= Bars - 3 ) {
        return false;
    }
    if( bar > 0 ) {
        if( array[bar] - array[bar-1] < 0 ) {
            return false;
        }
        if( bar > 1 ) {
            if( array[bar] - array[bar-2] < 0 ) { //-1 <= -2
                return false;
            }
        }
    }
    if( array[bar] - array[bar+1] < 0 ) {
        return false;
    }
    if( array[bar] - array[bar+2] < 0 ) { // +1 <= +2
        return false;
    }
    if( zeroLine ) {
        if( array[bar] <= 0 ) {
            return false;
        }
        for( int idx = bar+1; idx < bar+SEARCH_LEN_Z && idx < Bars-2; idx++ ) {
            if( array[idx] < 0 ) {
                return true;
            }
            if( array[bar] - array[idx] < 0 ) {
                return false;
            }
        }
    } else {
        if( array[bar] <= 0 ) {
            return false;
        }
        return true;
    }
    return false;
}

int LastPeakIndex(const int bar, const double &array[], const bool zeroLine = true)
{
    if( bar >= Bars - 3 ) {
        return -1;
    }
    bool zeroFlag = false;
    for( int idx = bar+3; idx < bar+SEARCH_LEN && idx < Bars-2; idx++ ) {
        if( zeroLine ) {
            if( !zeroFlag ) {
                continue;
            }
            if( array[idx] <= 0 ) {
                zeroFlag = true;
                continue;
            }
        }
        if( ( array[idx] - array[idx+1] < 0 ) || 
            ( array[idx] - array[idx-1] < 0 ) ) {
            continue;
        }
        if( ( array[idx] - array[idx+2] < 0 ) || 
            ( array[idx] - array[idx-2] < 0 ) ) {
            continue;
        }
        return idx;
    }
    return -1;
}

bool IsTrough(const int bar, const double &array[],
              const bool zeroLine = false)
{
    if( bar >= Bars - 3 ) {
        return false;
    }
    if( bar > 0 ) {
        if( array[bar] - array[bar-1] > 0 ) {
            return false;
        }
        if( bar > 1 ) {
            if( array[bar] - array[bar-2] > 0 ) { //-1 > -2
                return false;
            }
        }
    }
    if( array[bar] - array[bar+1] > 0 ) {
        return false;
    }
    if( array[bar] - array[bar+2] > 0 ) { //+1 >= +2
        return false;
    }
    if( zeroLine ) {
        if( array[bar] >= 0 ) {
            return false;
        }
        for( int idx = bar+1; idx < bar+SEARCH_LEN_Z && idx < Bars-2; idx++ ) {
            if( array[idx] > 0 ) {
                return true;
            }
            if( array[bar] - array[idx] > 0 ) {
                return false;
            }
        }
    } else {
        if( array[bar] >= 0 ) {
            return false;
        }
        return true;
    }
    return false;
}

int LastTroughIndex(const int bar, const double &array[], 
                    const bool zeroLine = true)
{  
    if( bar >= Bars - 3 ) {
        return -1;
    }
    bool zeroFlag = false;
    for( int idx = bar+3; idx < bar+SEARCH_LEN && idx < Bars-2; idx++ ) {
        if( zeroLine ) {
            if( !zeroFlag ) {
                continue;
            }
            if( array[idx] >= 0 ) {
                zeroFlag = true;
                continue;
            }
        }
        if( ( array[idx] - array[idx+1] > 0 ) || 
            ( array[idx] - array[idx-1] > 0 ) ) {
            continue;
        }
        if( ( array[idx] - array[idx+2] > 0 ) || 
            ( array[idx] - array[idx-2] > 0 ) ) {
            continue;
        }
        return idx;
    }
    return -1;
}


//+---------------------------------------------------------------------------+
//|   O T H E R   F U N C T I O N S                                           |
//+---------------------------------------------------------------------------+


