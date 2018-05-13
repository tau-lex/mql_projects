//+---------------------------------------------------------------------------+
//|                                                           _test_induk.mq4 |
//|                                          Copyright 2017, Terentev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentjew23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentew Aleksey"
#property link          "https://www.mql5.com/ru/users/terentjew23"
#property version       "1.0"
#property strict

#include                "MASh_Include.mqh"
#include                "MASh_Indicators.mqh"

//---------------------Indicators---------------------------------------------+
#property indicator_separate_window
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_buffers 2
#property indicator_plots   2
//--- plot
#property indicator_label1  "Green"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "Red"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- indicator buffers
double      GreenBuffer[];
double      RedBuffer[];

//-----------------Global variables-------------------------------------------+
//---
input ENUM_MA_METHOD        MA_METHOD   = MODE_EMA;     // MA calculate method
// input ENUM_APPLIED_PRICE    PRICE       = PRICE_CLOSE;  // Data type for calculate
//---

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer( 0, GreenBuffer );
    SetIndexBuffer( 1, RedBuffer );
    IndicatorShortName( "BouncedMA" );
    return( INIT_SUCCEEDED );
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
        double tmp = iBouncedMAFiltered(idx, Symbol(), Period(), MA_METHOD);
        if( tmp > 0 ) {
            GreenBuffer[idx] = tmp;
        } else if( tmp < 0 ) {
            RedBuffer[idx] = tmp;
        }
    }
    return rates_total;
}

//+---------------------------------------------------------------------------+
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


