//+---------------------------------------------------------------------------+
//|                                                        MASx_ML-Trader.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017-2018, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Expert for trаde with the ML-Assistant."
#property version       "2.10"
// #property icon          "ico/ml-trader.ico";
#property strict

#include                "MASh_Include.mqh"
#include                "MASh_Indicators.mqh"
#include                "MASh_IO.mqh"
#include                "MASh_Market.mqh"



//+---------------------------------------------------------------------------+
//|   D E F I N E S                                                           |
//+---------------------------------------------------------------------------+
enum TRAIL_TYPE {
    TRAIL_NONE = 0,
    TRAIL_STOP,
    TRAIL_TAKE,
    TRAIL_STOP_AND_TAKE
};


//+---------------------------------------------------------------------------+
//|   G L O B A L   V A R I A B L E S                                         |
//+---------------------------------------------------------------------------+
//---
input string        SECTION1 = "___ M O N E Y   M A N A G M E N T ___";//.
input int           ORDER_RISK = 2;             // Max risk per one order (%)
input int           MONTH_RISK = 6;             // Max risk per month (%)
input double        SIGNAL_GATE = 0.8;          // Gate for signal range
input TIME_PERIODS  EXP_PERIOD = ONE_DAY;       // Expiration period
input TRAIL_TYPE    TRAIL = TRAIL_STOP;         // Type of trailing stop levels

input string        SECTION2 = "___ S T O P   L E V E L S ___";//.
input double        STOP_MEAN = 3.0;            // Mean deviation (Factor) for ordering a protect

input string        SECTION3 = "___ P R O F I T   L E V E L S ___";//.
input int           TAKEPROFIT_PT = 20;         // Takeprofit points

input string        SECTION4 = "___ S Y S T E M ___";//.
input ORDER_TYPE    TRADE_TYPE = VIRTUAL_TRADE; // Trades type
input string        COMMENT = "ML-Trader";      // Comment
input int           SLIPPAGE = 3;               // Slippage
input int           MAGIC = 252525;             // Magic number
input string        DIRECTORY = "ML-Assistant"; // Path to all files (including prediction file)
input string        PREFIX = "";                // Prefix (PrefixSYMBOLPERIOD_x.csv)
input string        POSTFIX = "";               // Postfix (SYMBOLPERIODPostfix_x.csv)
input BOOL          ON_SCREENSHOT = Disable;    // A screenshot of an open order
input double        PREDICT_FACTOR = 1.0;       // Predict data multiplier
//---
int                 PREDICT_SIZE, PREDICT_DEPTH;
CMarket*            M;
double              buyBuff[], sellBuff[];
string              predictFile;
datetime            timeOffset;
double              newSignal;
bool                newBarFlag, newPredictFlag;
datetime            predictSavedTime;


//+---------------------------------------------------------------------------+
//|   M A I N   F U N C T I O N S                                             |
//+---------------------------------------------------------------------------+
int OnInit()
{
    timeOffset = (datetime)GetOffsetFromServerTimeZone();
    if( !GlobalVariableCheck() ) {
        return INIT_FAILED;
    }
    predictFile = StringConcatenate(DIRECTORY, "/", PREFIX, Symbol(), Period(), POSTFIX, "_yy.csv");
    ArrayResize(buyBuff, PREDICT_SIZE);
    ArrayResize(sellBuff, PREDICT_SIZE);
    M = GetTradeObject(TRADE_TYPE, DIRECTORY, SLIPPAGE, MAGIC);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    predictSavedTime = (datetime)FileGetInteger(predictFile, FILE_MODIFY_DATE) - timeOffset;
    if( iTime(Symbol(), Period(), 0) <= predictSavedTime ) {
        newPredictFlag = true;
    }
    if( NewBar() ) {
        newBarFlag = true;
    }
    if( newBarFlag && newPredictFlag ) {
        // I
        newSignal = PredictedSignal();
        // II
        ManageOpenedOrders(newSignal, SIGNAL_GATE);
        // III
        CalculateNewOrder(newSignal, SIGNAL_GATE);
        // Reset flags
        newPredictFlag = false;
        newBarFlag = false;
    }
    M.M_OnTick();
}

void OnDeinit(const int reason)
{
    delete M;
}


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
double PredictedSignal()
{
    Print(__FUNCTION__ + "");
    if( FileGetInteger(predictFile, FILE_EXISTS) ) { //-- Re-Checked_14-02-2018
        ReadPredictionFile(predictFile, PREDICT_SIZE, buyBuff, sellBuff, PREDICT_FACTOR);
        if( PREDICT_DEPTH > 0 ) {
            // Check past, present and future predicted signal
            double signalPast = buyBuff[PREDICT_DEPTH+1] + sellBuff[PREDICT_DEPTH+1];
            double signalPresent = buyBuff[PREDICT_DEPTH] + sellBuff[PREDICT_DEPTH];
            double signalFuture = buyBuff[PREDICT_DEPTH-1] + sellBuff[PREDICT_DEPTH-1];
            if( signalPresent > 0.0 && signalFuture >= 0.0 ) {
                if( signalPast <= 0.0 ) {
                    return signalPresent;
                } 
            } else if( signalPresent < 0.0 && signalFuture <= 0.0 ) {
                if( signalPast >= 0.0 ) {
                    return signalPresent;
                }
            }
        } else if( PREDICT_DEPTH == 0 ) {
            // Check past and present predicted signal
            double signalPast = buyBuff[PREDICT_DEPTH+1] + sellBuff[PREDICT_DEPTH+1];
            double signalPresent = buyBuff[PREDICT_DEPTH] + sellBuff[PREDICT_DEPTH];
            if( signalPresent > 0.0 ) {
                if( signalPast <= 0.0 ) {
                    return signalPresent;
                }
            } else if( signalPresent < 0.0 ) {
                if( signalPast >= 0.0 ) {
                    return signalPresent;
                }
            }
        }
    }
    return 0.0;
}

int CalculateNewOrder(const double signal, const double signalLimit = 0.5)
{
    Print(__FUNCTION__ + ": Signal = " + (string)signal);
    if( MathAbs(signal) < signalLimit || signal == 0.0 ) { // signal is small
        return -1;
    }
    int orderType;
    if( signal > 0.0 ) {
        orderType = OP_BUY;
    } else {
        orderType = OP_SELL;
    }
    // Search for an entry point.
    // safety zone 2-3 screen
    double orderLimitPrice = 0.0, orderTakeProfit = -1.0, orderStopLoss = -1.0;
    if( orderType == OP_BUY ) { // GOTO : Analize price, and find entry position
        orderLimitPrice = MarketInfo(Symbol(), MODE_ASK);
    } else if( orderType == OP_SELL ) {
        orderLimitPrice = MarketInfo(Symbol(), MODE_BID);
    }
    orderTakeProfit = GetTakeProfit(0, orderType);
    orderStopLoss   = GetStopLoss(0, orderType);
    // Checking position
    if( orderType == OP_BUY ) {
        if( orderTakeProfit > 0.0 ) {
            if( orderLimitPrice >= orderTakeProfit ) {
                return -2; // Wrong position
            }
        }
        if( orderStopLoss > 0.0 ) {
            if( orderLimitPrice <= orderStopLoss ) {
                return -2; // Wrong position
            }
        }
    } else if( orderType == OP_SELL ) {
        if( orderTakeProfit > 0.0 ) {
            if( orderLimitPrice <= orderTakeProfit ) {
                return -2; // Wrong position
            }
        }
        if( orderStopLoss > 0.0 ) {
            if( orderLimitPrice >= orderStopLoss ) {
                return -2; // Wrong position
            }
        }
    }
    // Risk Management
    double riskBalancePerOrder  = GetAccountBalance(TRADE_TYPE) * ORDER_RISK * 0.01;
    double riskBalancePerMonth  = GetBalanceFirstNum(TRADE_TYPE) * MONTH_RISK * 0.01;
    double riskBuyLot           = GetRiskBuyOneLot(orderLimitPrice, orderStopLoss);
    double orderLot             = GetLotSize(riskBuyLot, riskBalancePerOrder);
    if( riskBuyLot * orderLot >= riskBalancePerOrder ) { // The risk of buying one order.
        Print(__FUNCTION__ + ": Risk Management: Balance risk=$" + (string)riskBalancePerOrder + 
                "; Buy risk of one lot=$" + (string)(riskBuyLot*orderLot));
        return -3;
    }
    if( GetOpenedOrdersRisk(M) + riskBuyLot * orderLot >= riskBalancePerMonth ) { // Risk of open orders on the balance sheet at the beginning of the month.
        Print(__FUNCTION__ + ": Risk Management: Balance month risk=$" + (string)riskBalancePerMonth + 
                "; Opened month risk=$" + (string)(GetOpenedOrdersRisk(M)+riskBuyLot*orderLot));
        return -3;
    }
    // Open Limit Order
    Print(__FUNCTION__ + ": Open send(lot=" + (string)orderLot + ", price=" + (string)orderLimitPrice + ")");
    datetime orderExpiration = TimeCurrent() + EXP_PERIOD;
    // if( orderType == OP_BUY ) {
    //     orderType = OP_BUYLIMIT;
    // } else if( orderType == OP_SELL ) {
    //     orderType = OP_SELLLIMIT;
    // }
    string text = COMMENT + "_sgnl=" + (string)signal;
    int orderTicket = M.M_OrderSend(Symbol(), orderType, orderLot, orderLimitPrice, SLIPPAGE,
                                    orderStopLoss, orderTakeProfit, text, MAGIC, orderExpiration);
    if( orderTicket < 0 ) {
        Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
    } else if( ON_SCREENSHOT ) {
        string imgFile = StringConcatenate(DIRECTORY, "/img/", (string)TimeCurrent(), ".png");
        ChartScreenShot(0, imgFile, 640, 480);
    }
    return orderTicket;
}

int ManageOpenedOrders(const double signal = 0.0, const double signalLimit = 0.5)
{
    Print(__FUNCTION__ + "");
    int         oTicket, oType;
    double      oLots, oOpenPrice, oStopLoss, oTakeProfit;
    datetime    oExpiration;
    string      oComment;
    for( int idx = 0; idx < M.M_OrdersTotal(); idx++ ) {
        Print(__FUNCTION__ + ": Select order ");
        if( !M.M_OrderSelect(idx, SELECT_BY_POS) ) {
            Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
            continue;
        }
        if( M.M_OrderSymbol() != Symbol() || StringFind(M.M_OrderComment(), COMMENT) < 0 ) {
            continue;
        }
        oTicket     = M.M_OrderTicket();
        oType       = M.M_OrderType();
        oLots       = M.M_OrderLots();
        oOpenPrice  = M.M_OrderOpenPrice();
        oTakeProfit = M.M_OrderTakeProfit();
        oStopLoss   = M.M_OrderStopLoss();
        oExpiration = M.M_OrderExpiration();
        oComment    = M.M_OrderComment();
        // Check revers signal
        Print(__FUNCTION__ + ": Revers signal ");
        if( oType == OP_BUY ) {
            if( signal < -0.3 ) {
                M.M_OrderComment(oComment + "_[sgnl-]");
                if( !M.M_OrderClose(oTicket, oLots, Bid, SLIPPAGE) ) {
                    Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
                }
            }
        } else if( oType == OP_SELL ) {
            if( signal > 0.3 ) {
                M.M_OrderComment(oComment + "_[sgnl+]");
                if( !M.M_OrderClose(oTicket, oLots, Ask, SLIPPAGE) ) {
                    Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
                }
            }
        }
        // Trall stop and take levels
        Print(__FUNCTION__ + ": Trail levels ");
        if( TRAIL > TRAIL_NONE ) {
            double newTP = oTakeProfit, newSL = oStopLoss;
            if( oType == OP_BUY ) {
                if( TRAIL == TRAIL_TAKE || TRAIL == TRAIL_STOP_AND_TAKE ) {
                    if( GetTakeProfit(0, OP_BUY) > oTakeProfit ) {
                        newTP = GetTakeProfit(0, OP_BUY);
                    }
                }
                if( TRAIL == TRAIL_STOP || TRAIL == TRAIL_STOP_AND_TAKE ) {
                    if( GetStopLoss(0, OP_BUY) > oStopLoss ) {
                        newSL = GetStopLoss(0, OP_BUY);
                    }
                }
            } else if( oType == OP_SELL ) {
                if( TRAIL == TRAIL_TAKE || TRAIL == TRAIL_STOP_AND_TAKE ) {
                    if( GetTakeProfit(0, OP_SELL) < oTakeProfit ) {
                        newTP = GetTakeProfit(0, OP_SELL);
                    }
                }
                if( TRAIL == TRAIL_STOP || TRAIL == TRAIL_STOP_AND_TAKE ) {
                    if( GetStopLoss(0, OP_SELL) < oStopLoss ) {
                        newSL = GetStopLoss(0, OP_SELL);
                    }
                }
            }
            if( newTP != oTakeProfit || newSL != oStopLoss ) {
                if( !M.M_OrderModify(oTicket, oOpenPrice, newSL, newTP, oExpiration) ) {
                    Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
                }
                continue;
            }
        }
        // Check Expiration
        Print(__FUNCTION__ + ": Expiration order ");
        if( oExpiration <= TimeCurrent() ) {
            double _close = oType == OP_BUY ? Bid : (oType == OP_SELL ? Ask : 0.0);
            if( !M.M_OrderClose(oTicket, oLots, _close, SLIPPAGE) ) {
                Print(__FUNCTION__ + ": Error = " + (string)GetLastError());
            }
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
    // GOTO : Фибоначчи / ЕМА фибо / Весовые коэффициенты к уровням
    double _takeProfit = 0.0;
    if( orderType == OP_BUY ) {
        // _takeProfit = iKeltnerChannel(bar, Symbol(), Period(), 26, Higher, Modified_2, 140);
        _takeProfit = MarketInfo(Symbol(), MODE_BID) + TAKEPROFIT_PT * MarketInfo(Symbol(), MODE_POINT);
    } else if( orderType == OP_SELL ) {
        // _takeProfit = iKeltnerChannel(bar, Symbol(), Period(), 26, Lower, Modified_2, 140);
        _takeProfit = MarketInfo(Symbol(), MODE_ASK) - TAKEPROFIT_PT * MarketInfo(Symbol(), MODE_POINT);
    }
    return _takeProfit;
}

double GetStopLoss(const int bar, const int orderType)
{
    double _stopLoss = 0.0;
    if( orderType == OP_BUY ) {
        _stopLoss = StopBuyMax(bar-1, Symbol(), Period(), STOP_MEAN);
    } else if( orderType == OP_SELL ) {
        _stopLoss = StopSellMin(bar-1, Symbol(), Period(), STOP_MEAN);
        _stopLoss += MarketInfo(Symbol(), MODE_SPREAD) * MarketInfo(Symbol(), MODE_POINT);
    }
    return _stopLoss;
}


//+---------------------------------------------------------------------------+
//|   O T H E R   F U N C T I O N S                                           |
//+---------------------------------------------------------------------------+
bool GlobalVariableCheck()
{
    // GOTO : add refresh of global terminal parameters
    string glVarPredictSize, glVarPredictDepth, glVarAssistant;
    glVarAssistant = StringConcatenate("MASv_", Symbol(), Period(), "_Assistant");
    double existAssistant;
    if( GlobalVariableGet(glVarAssistant, existAssistant) ) {
        if( existAssistant <= 0 ) {
            Print("MASi_ML-Assistant not found.");
            return false;
        }
        glVarPredictSize = StringConcatenate("MASv_", Symbol(), Period(), "_PredictSize");
        PREDICT_SIZE = (int)GlobalVariableGet(glVarPredictSize);
        glVarPredictDepth = StringConcatenate("MASv_", Symbol(), Period(), "_PredictDepth");
        PREDICT_DEPTH = (int)GlobalVariableGet(glVarPredictDepth);
    }
    return true;
}
