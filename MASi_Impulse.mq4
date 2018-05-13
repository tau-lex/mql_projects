//+---------------------------------------------------------------------------+
//|                                                          MASi_Impulse.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Works on any time scale. Send signals to buy and sell."
#property description   "The idea of Alexander Elder."
#property version       "1.2"
#property icon          "ico/impulsesystem.ico";
#property strict

#include                "MASh_Include.mqh"

//---------------------Indicators---------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots   12
//--- plot
#property indicator_label1  "OpenB"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrDeepSkyBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
#property indicator_label2  "CloseB"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrDeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
#property indicator_label3  "HighB"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrDeepSkyBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label4  "LowB"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrDeepSkyBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label5  "OpenG"
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_color5  clrGreen
#property indicator_style5  STYLE_SOLID
#property indicator_width5  3
#property indicator_label6  "CloseG"
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color6  clrGreen
#property indicator_style6  STYLE_SOLID
#property indicator_width6  3
#property indicator_label7  "HighG"
#property indicator_type7   DRAW_HISTOGRAM
#property indicator_color7  clrGreen
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1
#property indicator_label8  "LowG"
#property indicator_type8   DRAW_HISTOGRAM
#property indicator_color8  clrGreen
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1
#property indicator_label9  "OpenR"
#property indicator_type9   DRAW_HISTOGRAM
#property indicator_color9  clrRed
#property indicator_style9  STYLE_SOLID
#property indicator_width9  3
#property indicator_label10 "CloseR"
#property indicator_type10  DRAW_HISTOGRAM
#property indicator_color10 clrRed
#property indicator_style10 STYLE_SOLID
#property indicator_width10 3
#property indicator_label11 "HighR"
#property indicator_type11  DRAW_HISTOGRAM
#property indicator_color11 clrRed
#property indicator_style11 STYLE_SOLID
#property indicator_width11 1
#property indicator_label12 "LowR"
#property indicator_type12  DRAW_HISTOGRAM
#property indicator_color12 clrRed
#property indicator_style12 STYLE_SOLID
#property indicator_width12 1
//--- indicator buffers
double      OBBuffer[], CBBuffer[], HBBuffer[], LBBuffer[];
double      OGBuffer[], CGBuffer[], HGBuffer[], LGBuffer[];
double      ORBuffer[], CRBuffer[], HRBuffer[], LRBuffer[];

//-----------------Global variables-------------------------------------------+
//---
input int   EMA = 13;           // EMA 
input int   MACD_FAST = 12;     // MACD Fast
input int   MACD_SLOW = 26;     // MACD Slow
input int   MACD_SIGNAL = 9;    // MACD Signal
//---

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer( 0, OBBuffer ); SetIndexBuffer( 1, CBBuffer );
    SetIndexBuffer( 2, HBBuffer ); SetIndexBuffer( 3, LBBuffer );
    SetIndexBuffer( 4, OGBuffer ); SetIndexBuffer( 5, CGBuffer );
    SetIndexBuffer( 6, HGBuffer ); SetIndexBuffer( 7, LGBuffer );
    SetIndexBuffer( 8, ORBuffer ); SetIndexBuffer( 9, CRBuffer );
    SetIndexBuffer( 10, HRBuffer ); SetIndexBuffer( 11, LRBuffer );
    IndicatorShortName( "Impulse (" + IntegerToString(EMA) + ", " + IntegerToString(MACD_FAST) + ", " +
                        IntegerToString(MACD_SLOW) + ", " + IntegerToString(MACD_SIGNAL) + " )" );
    if( EMA <= 1 || MACD_FAST <= 1 || MACD_SLOW <= 1 || MACD_SIGNAL <= 1 || MACD_FAST >= MACD_SLOW ) {
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
    if( rates_total <= MACD_SIGNAL ) {
        return rates_total;
    }
    int limit = rates_total - prev_calculated;
    if( prev_calculated > 0 ) {
        limit++;
    }
    ResizeBar();
    for( int i = 0; i < limit; i++ ) {
        double tmp = iImpulse( i, Symbol(), PERIOD_CURRENT, EMA, MACD_FAST, MACD_SLOW, MACD_SIGNAL );
        if( tmp > 0 ) {
            ClearBuffer( i );
            OGBuffer[i] = iOpen( NULL, 0, i ); CGBuffer[i] = iClose( NULL, 0, i );
            HGBuffer[i] = iHigh( NULL, 0, i ); LGBuffer[i] = iLow( NULL, 0, i );
        } else if( tmp < 0 ) {
            ClearBuffer( i );
            ORBuffer[i] = iOpen( NULL, 0, i ); CRBuffer[i] = iClose( NULL, 0, i );
            HRBuffer[i] = iHigh( NULL, 0, i ); LRBuffer[i] = iLow( NULL, 0, i );
        } else {
            ClearBuffer( i );
            OBBuffer[i] = iOpen( NULL, 0, i ); CBBuffer[i] = iClose( NULL, 0, i );
            HBBuffer[i] = iHigh( NULL, 0, i ); LBBuffer[i] = iLow( NULL, 0, i );
        }
    }
    return rates_total;
}

void ResizeBar()
{
    static int tmpS, tmpT;
    int scale, typeBar, size = 1;
    scale   = (int)ChartGetInteger( 0, CHART_SCALE );
    typeBar = (int)ChartGetInteger( 0, CHART_MODE );
    if( scale == tmpS && typeBar == tmpT ) { 
        return;
    }
    if( typeBar == CHART_CANDLES ) {
        size = scale > 3 ? 5 : (scale == 0 ? 1 : scale);
    }
    SetIndexStyle( 0, DRAW_HISTOGRAM, EMPTY, size );
    SetIndexStyle( 1, DRAW_HISTOGRAM, EMPTY, size );
    SetIndexStyle( 4, DRAW_HISTOGRAM, EMPTY, size );
    SetIndexStyle( 5, DRAW_HISTOGRAM, EMPTY, size );
    SetIndexStyle( 8, DRAW_HISTOGRAM, EMPTY, size );
    SetIndexStyle( 9, DRAW_HISTOGRAM, EMPTY, size );
    tmpS = scale; tmpT = typeBar;
}

void OnChartEvent(const int id,         // идентификатор события   
                  const long& lparam,   // параметр события типа long 
                  const double& dparam, // параметр события типа double 
                  const string& sparam) // параметр события типа string 
{
    if( id == CHARTEVENT_CHART_CHANGE ) {
        ResizeBar();
        ChartRedraw();
    }
}

void ClearBuffer(const int bar = 0)
{
    OGBuffer[bar] = EMPTY_VALUE; HGBuffer[bar] = EMPTY_VALUE; LGBuffer[bar] = EMPTY_VALUE;
    ORBuffer[bar] = EMPTY_VALUE; HRBuffer[bar] = EMPTY_VALUE; LRBuffer[bar] = EMPTY_VALUE;
    OBBuffer[bar] = EMPTY_VALUE; HBBuffer[bar] = EMPTY_VALUE; LBBuffer[bar] = EMPTY_VALUE;
}

