//+---------------------------------------------------------------------------+
//|                                                     MASx_ThreeScreens.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Alexander Elder strategy."
#property description   "Send signals to buy and sell."
#property description   "The ideas of Alexander Elder, Ivan Khristoforov, Aleksey Terentyev."
#property version       "1.1"
#property strict

#include                "MASh_Include.mqh"

//-----------------Global variables-------------------------------------------+
//---
input int       EMA_D1 = 26;        // EMA Display #1. For a impulse signal
input int       EMA_D2 = 26;        // EMA Display #2. For a Price channel
input int       MACD_FAST = 12;     // MACD Fast
input int       MACD_SLOW = 26;     // MACD Slow
input int       MACD_SIGNAL = 9;    // MACD Signal
input int       PROFIT_CHANNEL = 1000;// Price channel (Points) for ordering a profit
input int       STOP_MEAN = 3;      // Mean deviation (Factor) for ordering a protect
input int       ORDER_RISK = 2;     // Max risk per one order (%)
input int       MONTH_RISK = 6;     // Max risk per month (%)
//---
double          currentStop = 0.0;
double          currentTake = 0.0;
int             currentType = 0;    // 0 - None, 1 - Buy, 2 - Sell

//+---------------------------------------------------------------------------+
int OnInit()
{
    if( EMA_D1 <= 1 || EMA_D2 <= 1 || MACD_FAST <= 1 || MACD_SLOW <= 1 || 
            MACD_SIGNAL <= 1 || MACD_FAST >= MACD_SLOW ) {
        Print( "Wrong input parameters" );
        return( INIT_FAILED );
    }
    return( INIT_SUCCEEDED );
}

//+---------------------------------------------------------------------------+
void OnTick()
{
    int count = OrdersTotal();
    if( count > 0 ) {
        int tickets[];
        ArrayResize( tickets, count );
        for( int idx = 0; idx < count; idx++ ) {
            if( OrderSelect( idx, SELECT_BY_POS ) )
                tickets[idx] = OrderTicket();
            else
                PrintFormat( "Order not select : %d", GetLastError() );
        }
        for( int idx = 0; idx < count; idx++ ) {
            if( StopContact( tickets[idx] ) || ProfitContact( tickets[idx] ) ) {
                ClosePosition( tickets[idx] );
            } else {
                UpdateStopLevel( tickets[idx] );
            }
        }
    } else {
        currentType = 0;
        double signal0 = ThreeScreens_v1_2( 0, Symbol(), Period(), EMA_D1, MACD_FAST, MACD_SLOW, MACD_SIGNAL );
        double signal1 = ThreeScreens_v1_2( 1, Symbol(), Period(), EMA_D1, MACD_FAST, MACD_SLOW, MACD_SIGNAL );
        double signal2 = ThreeScreens_v1_2( 2, Symbol(), Period(), EMA_D1, MACD_FAST, MACD_SLOW, MACD_SIGNAL );
        if( fabs( signal0 ) > 0.2 && CalculateRisk( signal0, EMA_D2 ) > 0.6 ) {
            OpenPosition( signal0, EMA_D2 );
        }
        if( fabs( signal1 ) > 0.2 && CalculateRisk( signal1, EMA_D2 ) > 0.6 ) {
            OpenPosition( signal1, EMA_D2 );
        }
        if( fabs( signal2 ) > 0.2 && CalculateRisk( signal2, EMA_D2 ) > 0.6 ) {
            OpenPosition( signal2, EMA_D2 );
        }
    }
}

//+---------------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
    return;
}

//+---------------------------------------------------------------------------+
double CalculateRisk(const double signal, const int pEMA, 
                     const string symbol = NULL, const int period = PERIOD_CURRENT)
{
    double profit, stop, profitSize = 0.0, stopSize = 0.0, profitRisk = 0.0;
    double ema = iMA( symbol, period, pEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    if( signal > 0.0 ) {
        profit = ema + (PROFIT_CHANNEL * Point);
        stop = StopBuyMax( 0, STOP_MEAN );
        profitSize = fabs( Ask - profit );
        stopSize = fabs( Ask - stop );
    } else if( signal < 0.0 ) {
        profit = ema - (PROFIT_CHANNEL * Point);
        stop = StopSellMin( 0, STOP_MEAN );
        profitSize = fabs( Bid - profit );
        stopSize = fabs( Bid - stop );
    }
    profitRisk = ( profitSize + stopSize ) / 100 * profitSize;
    return profitRisk;
};

int OpenPosition(const double signal, const int pEMA, 
                 const string symbol = NULL, const int period = PERIOD_CURRENT)
{
    int ticket;
    double profit, stop, profitSize, stopSize;
    double ema = iMA( symbol, period, pEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
    if( signal > 0.0 ) {
        profit = ema + (PROFIT_CHANNEL * Point);
        stop = StopBuyMax( 0, STOP_MEAN );
        //profitSize = fabs( Ask - profit );
        profitSize = 0.0;
        stopSize = fabs( Ask - stop );
        ticket = OrderSend( Symbol(), OP_BUY, 0.01, 
                            Ask, 3, stop, profit );
        if( ticket > 0 ) {
            if( OrderSelect( ticket, SELECT_BY_TICKET ) )
                Print( "BUY order opened: ",OrderOpenPrice() );
        } else {
            Print( "Error opening BUY order: ",GetLastError() );
        }
        currentType = 1;
    } else if( signal < 0.0 ) {
        profit = ema - (PROFIT_CHANNEL * Point);
        stop = StopSellMin( 0, STOP_MEAN );
        //profitSize = fabs( Bid - profit );
        profitSize = 0.0;
        stopSize = fabs( Bid - stop );
        ticket = OrderSend( Symbol(), OP_SELL, 0.01,
                            Bid, 3, stop, profit );
        if( ticket > 0 ) {
            if( OrderSelect( ticket, SELECT_BY_TICKET ) )
                Print( "SELL order opened: ", OrderOpenPrice() );
        } else {
            Print( "Error opening SELL order: ", GetLastError() );
        }
        currentType = 2;
    }
    currentStop = stopSize;
    return 0;
};

bool ProfitContact(const int order)
{
    return false;
};

bool StopContact(const int order)
{
    return false;
};

bool ClosePosition(const int order)
{
    
    return false;
};

bool UpdateStopLevel(const int order)
{
    if( currentType == 0 ) {
        return false;
    }
    if( currentType == 1 ) {
        
    }
    return false;
};


