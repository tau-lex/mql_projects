//+---------------------------------------------------------------------------+
//|                                                           iSafetyZone.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017-2018, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Safety Zone."
#property description   "The idea of Aleksander Elder."
#property version       "1.1"
// #property icon          "ico/keltnerchannel.ico";
#property strict

#include                "MASh_Indicators.mqh"


//---------------------Indicators---------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot
#property indicator_label1  "Stop Buy"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrTomato
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Stop Sell"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrTomato
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- indicator buffers
double      BuyBuffer[], SellBuffer[];

//-----------------Global variables-------------------------------------------+
//---
input int       FACTOR      = 3;    // Multyplier
input int       SHIFT       = 0;   // Shift
input bool      SPREAD      = false;// Consider the spread for stop sell.
//---

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, BuyBuffer);
    SetIndexBuffer(1, SellBuffer);
    return INIT_SUCCEEDED;
}

//+---------------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int limit = rates_total - prev_calculated;
    if( prev_calculated > 0 ) {
        limit++;
    }
    for( int idx = limit-1; idx >= 0; idx-- ) {
        BuyBuffer[idx] = StopBuyMax(idx+SHIFT, Symbol(), Period(), FACTOR);
        SellBuffer[idx] = StopSellMin(idx+SHIFT, Symbol(), Period(), FACTOR);
        if( SPREAD ) {
            SellBuffer[idx] += MarketInfo(Symbol(), MODE_SPREAD) * MarketInfo(Symbol(), MODE_POINT);
        }
    }
    return rates_total;
}


