//+---------------------------------------------------------------------------+
//|                                                           iTargetZone.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017-2018, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   ""
#property version       "1.0"
// #property icon          "ico/keltnerchannel.ico";
#property strict

#include                "MASh_Indicators.mqh"


//---------------------Indicators---------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot
#property indicator_label1  "Take Buy"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrOliveDrab
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Take Sell"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOliveDrab
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_type3   DRAW_NONE
//--- indicator buffers
double      BuyBuffer[], SellBuffer[], EmaBuffer[];;

//-----------------Global variables-------------------------------------------+
enum TP_TYPE {
    Channel,
    TrueRange,
    InversSafety
};
//---
input TP_TYPE       TP_MODE     = Channel;  // Take Profit as ...
input ENUM_MA_METHOD MODE       = MODE_EMA; // MA type
input int           MA_PERIOD   = 10;       // MA period
input int           CHANNEL_SIZE= 50;       // Channel range
input double        FACTOR      = 2;        // True Range multyplier
input int           SHIFT       = -1;       // Shift
input bool          SPREAD      = false;    // Consider the spread for take sell.
//---

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, BuyBuffer);
    SetIndexBuffer(1, SellBuffer);
    SetIndexBuffer(2, EmaBuffer);
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
    double channelRange = 0.0;
    for( int idx = limit-1; idx >= -SHIFT; idx-- ) {
        // EmaBuffer[idx] = iMA(Symbol(), Period(), MA_PERIOD, 0, MODE, PRICE_CLOSE, idx+SHIFT);
        // switch( TP_MODE ) {
        //     case Channel: {
        //         channelRange = CHANNEL_SIZE * MarketInfo(Symbol(), MODE_POINT);
        //         break;
        //     } case TrueRange: {
        //         channelRange = FACTOR * iATR(Symbol(), Period(), MA_PERIOD, idx+SHIFT);
        //         break;
        //     } case InversSafety: {
        //         channelRange = 0.0;
        //     }
        // }
        // BuyBuffer[idx] = EmaBuffer[idx+SHIFT] + channelRange;
        // SellBuffer[idx] = EmaBuffer[idx+SHIFT] - channelRange;
        BuyBuffer[idx] = StopBuyMax(idx, Symbol(), Period(), 5.0);
        SellBuffer[idx] = StopSellMin(idx, Symbol(), Period(), 5.0);
        if( SPREAD ) {
            SellBuffer[idx] += MarketInfo(Symbol(), MODE_SPREAD) * MarketInfo(Symbol(), MODE_POINT);
        }
    }
    return rates_total;
}


