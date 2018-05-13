//+---------------------------------------------------------------------------+
//|                                                     MASi_ThreeScreens.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "The indicator is based on the strategy of Dr. Alexander Elder."
#property description   "Send signals to buy and sell."
#property description   "The ideas of Alexander Elder, Aleksey Terentyev."
#property version       "2.1"
#property icon          "ico/threescreens.ico";
#property strict

#include                "MASh_Include.mqh"

//---------------------Indicators---------------------------------------------+
#property indicator_separate_window
//#property indicator_height  50
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_buffers 4
#property indicator_plots   4
//--- plot
#property indicator_label1  "Buy"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrDarkGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrMaroon
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
#property indicator_label3  ""
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrDimGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3
#property indicator_label4  "Sell"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrDimGray
#property indicator_style4  STYLE_SOLID
#property indicator_width4  3
//--- indicator buffers
double      GreenBuffer[], RedBuffer[];
double      Gray1Buffer[], Gray2Buffer[];

//-----------------Global variables-------------------------------------------+
//---
input TSType    INDICATOR   = ThreeScreens_v2_0;    // Chose Indicator for work
input int       EMA_SCRN2   = 13;                   // EMA Fast
input int       EMA_SCRN1   = 26;                   // EMA Slow
input int       MACD_FAST   = 12;                   // MACD Fast
input int       MACD_SLOW   = 26;                   // MACD Slow
input int       MACD_SIGNAL = 9;                    // MACD Signal
input BoolEnum  ON_GREYBAR  = Disable;              // Neutral signal
//---
//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer( 0, GreenBuffer );
    SetIndexBuffer( 1, RedBuffer );
    if( ON_GREYBAR ) {
        SetIndexBuffer( 2, Gray1Buffer );
        SetIndexBuffer( 3, Gray2Buffer );
    }
    IndicatorShortName( GetIndicatorString(INDICATOR) );
    if( EMA_SCRN1 <= 1 || EMA_SCRN2 <= 1 || 
         MACD_FAST <= 1 || MACD_SLOW <= 1 || MACD_SIGNAL <= 1 || MACD_FAST >= MACD_SLOW ) {
        Print( "Wrong input parameters" );
        return INIT_FAILED;
    }
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
    double tmp = 0.0;
    for( int idx = limit-1; idx >= 0; idx-- ) {
        GreenBuffer[idx] = 0.0;
        RedBuffer[idx] = 0.0;
        tmp = iThreeScreens( idx, Symbol(), Period(), EMA_SCRN1, EMA_SCRN2, MACD_FAST, MACD_SLOW, MACD_SIGNAL, INDICATOR ); 
        if( tmp > 0 ) {
            GreenBuffer[idx] = tmp;
        } else if( tmp < 0 ) {
            RedBuffer[idx] = tmp;
        } else if( ON_GREYBAR ) {   // Size of gray bars
            Gray1Buffer[idx] = 0.5; 
            Gray2Buffer[idx] = -0.5;
        }
    }
    return rates_total;
}

