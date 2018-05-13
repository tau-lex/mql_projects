//+---------------------------------------------------------------------------+
//|                                                         MASi_WaveHist.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Raghee's Cicle indicator (aka Wave)."
#property description   "Indicator of the market cycle."
#property description   "The idea of Raghee Horner."
#property version       "1.4"
#property icon          "ico/wavehist.ico";
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
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
#property indicator_label3  ""
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrDimGray
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3
#property indicator_label4  ""
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrDimGray
#property indicator_style4  STYLE_SOLID
#property indicator_width4  3
//--- indicator buffers
double      GreenBuffer[], RedBuffer[];
double      Gray1Buffer[], Gray2Buffer[];

//-----------------Global variables-------------------------------------------+
enum IndicatorAlert {
    TurnedOff = 0,
    AllCandles = 1,
    NeutralCandles = 2,
    PositivCandles = 3,
    NegativeCandles = 4,
    PositivAndNegative = 5
};
//---
input int               EMA = 34;               // EMA
input BoolEnum          ON_GREYBAR = Disable;   // Neutral signal
input IndicatorAlert    ON_ALERT = TurnedOff;   // Type of alert about changes candles
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
    IndicatorShortName( "Wave ( " + IntegerToString(EMA) + " )" );
    if( EMA <= 1 ) {
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
    if( limit >= Bars(Symbol(), Period()) ) { limit = Bars(Symbol(), Period()) - EMA; }
    if( prev_calculated > 0 ) {
        limit++;
    }
    for( int idx = 0; idx < limit; idx++ ) {
        GreenBuffer[idx] = 0.0;
        RedBuffer[idx] = 0.0;
        if( ON_GREYBAR ) {
            Gray1Buffer[idx] = 0.0; 
            Gray2Buffer[idx] = 0.0;
        }
        double tmp = iWave(idx, Symbol(), Period(), EMA);
        if( tmp > 0 ) {
            GreenBuffer[idx] = tmp;
        } else if( tmp < 0 ) {
            RedBuffer[idx] = tmp;
        } else if( ON_GREYBAR ) {   // Size of gray bars
            Gray1Buffer[idx] = 0.5; 
            Gray2Buffer[idx] = -0.5;
        }
    }
    if( ON_ALERT ) {
        int candles[4];
        candles[0] = GreenBuffer[0] ? 1 : (RedBuffer[0] ? -1 : 0);
        candles[1] = GreenBuffer[1] ? 1 : (RedBuffer[1] ? -1 : 0);
        candles[2] = GreenBuffer[2] ? 1 : (RedBuffer[2] ? -1 : 0);
        candles[3] = GreenBuffer[3] ? 1 : (RedBuffer[3] ? -1 : 0);
        if( candles[1] == candles[2] && candles[2] == candles[3] ) {
            if( candles[0] != candles[1] ) {
                string msg1 = "Warning! Possibly changes market stage.", msg2;
                if( candles[0] > candles[1] ) {
                    msg2 = "Perhaps an upward trend.";
                } else if( candles[0] < candles[1] ) {
                    msg2 = "Perhaps a downward trend.";
                } else {
                    msg2 = "Perhaps consolidation.";
                }
                switch( ON_ALERT ) {
                    case TurnedOff: { break; }
                    case AllCandles: { Alert(msg1, "\r\n", msg2); break; }
                    case NeutralCandles: { Alert(msg1, "\r\n", msg2); break; }
                    case PositivCandles: { Alert(msg1, "\r\n", msg2); break; }
                    case NegativeCandles: { Alert(msg1, "\r\n", msg2); break; }
                    case PositivAndNegative: { Alert(msg1, "\r\n", msg2); break; }
                    default: break;
                }
            }
        }
    }
    return rates_total;
}

