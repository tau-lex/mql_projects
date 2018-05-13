//+---------------------------------------------------------------------------+
//|                                                       MASi_AdaptiveMA.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "The indicator averages several MAs in one line."
#property description   "It also allows averaging in accordance with the weighting factors."
#property version       "1.4"
#property icon          "ico/adaptivema.ico"
#property strict

#include                "MASh_Include.mqh"

//---------------------Indicators---------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot
#property indicator_label1  "AdaptiveMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- indicator buffers
double      MainBuffer[];

//-----------------Global variables-------------------------------------------+
//---
input string                MA_PERIODS  = "14, 30, 180, 360";       // Moving average periods
input BOOL                  ON_WEIGHTS  = Disable;                  // Use weighting factors
// input MeanType              MA_MEANTYPE = Arithmetic;               //
input string                MA_WEIGHTS  = "1, 1.618, 2.618, 4.236"; // Weights of moving average
input ENUM_MA_METHOD        MA_METHOD   = MODE_EMA;                 // Moving Average type
input ENUM_APPLIED_PRICE    PRICE       = PRICE_CLOSE;              // Price type
//---
string                      emaArrayStr[], wghtArrayStr[];
int                         emaCount, emaArray[], wghtCount;
double                      wghtArray[];

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer( 0, MainBuffer );
    // strings to arrays
    emaCount = StringSplit( MA_PERIODS, ',', emaArrayStr );
    ArrayResize( emaArray, emaCount );
    for( int idx = 0; idx < emaCount; idx++ ) {
        emaArray[idx] = StringToInteger(emaArrayStr[idx]);
    }
    if( ON_WEIGHTS ) {
        wghtCount = StringSplit( MA_WEIGHTS, ',', wghtArrayStr );
        ArrayResize( wghtArray, wghtCount );
        for( int idx = 0; idx < wghtCount; idx++ ) {
            wghtArray[idx] = StringToDouble( wghtArrayStr[idx] );
        }
        if( emaCount != wghtCount ) {
            Print( "Invalid weights count" );
            return INIT_FAILED;
        }
        for( int idx = 0; idx < wghtCount; idx++ ) {
            if( wghtArray[idx] == 0.0 ) {
                Print( "Invalid weights" );
                return INIT_FAILED;
            }
        }
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
    if( ON_WEIGHTS ) {
        for( int idx = limit-1; idx >= 0; idx-- ) {
            MainBuffer[idx] = iAdaptiveMA( idx, Symbol(), Period(), emaArray, wghtArray, MA_METHOD, PRICE, ArithmeticW ); // MA_MEANTYPE
        }
    } else {
        for( int idx = limit-1; idx >= 0; idx-- ) {
            MainBuffer[idx] = iAdaptiveMA( idx, Symbol(), Period(), emaArray, wghtArray, MA_METHOD, PRICE, Arithmetic ); // MA_MEANTYPE  Square Geometric
        }
    }
    return rates_total;
}

//+---------------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

