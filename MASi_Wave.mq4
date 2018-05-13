//+---------------------------------------------------------------------------+
//|                                                             MASi_Wave.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Raghee's Cicle indicator (aka Wave)."
#property description   "Indicator of the market cycle."
#property description   "The idea of Raghee Horner."
#property version       "1.4"
#property icon          "ico/wave.ico";
#property strict

#include                "MASh_Include.mqh"

//---------------------Indicators---------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 15
#property indicator_plots   15
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
#property indicator_label13 "Wave Close"
#property indicator_type13  DRAW_LINE
#property indicator_color13 clrDeepSkyBlue
#property indicator_style13 STYLE_DASH
#property indicator_width13 1
#property indicator_label14 "Wave High"
#property indicator_type14  DRAW_LINE
#property indicator_color14 clrGreen
#property indicator_style14 STYLE_DASH
#property indicator_width14 1
#property indicator_label15 "Wave Low"
#property indicator_type15  DRAW_LINE
#property indicator_color15 clrRed
#property indicator_style15 STYLE_DASH
#property indicator_width15 1
//--- indicator buffers
double      OBBuffer[], CBBuffer[], HBBuffer[], LBBuffer[];
double      OGBuffer[], CGBuffer[], HGBuffer[], LGBuffer[];
double      ORBuffer[], CRBuffer[], HRBuffer[], LRBuffer[];
double      EmaCBuffer[], EmaHBuffer[], EmaLBuffer[];

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
input BoolEnum          ON_EMA = Enable;        // Moving avegage line
input BoolEnum          ON_PRICES = Disable;    // Prices flags
input IndicatorAlert    ON_ALERT = TurnedOff;   // Type of alert about changes candles
//---

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, OBBuffer); SetIndexBuffer(1, CBBuffer);
    SetIndexBuffer(2, HBBuffer); SetIndexBuffer(3, LBBuffer);
    SetIndexBuffer(4, OGBuffer); SetIndexBuffer(5, CGBuffer);
    SetIndexBuffer(6, HGBuffer); SetIndexBuffer(7, LGBuffer);
    SetIndexBuffer(8, ORBuffer); SetIndexBuffer(9, CRBuffer);
    SetIndexBuffer(10, HRBuffer); SetIndexBuffer(11, LRBuffer);
    SetIndexBuffer(12, EmaCBuffer);
    SetIndexBuffer(13, EmaHBuffer); SetIndexBuffer(14, EmaLBuffer);
    IndicatorShortName("Wave ( " + IntegerToString(EMA) + " )");
    if( EMA <= 1 ) {
        Print("Wrong input parameters");
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
    if( limit >= Bars(Symbol(), Period()) ) {
        limit = Bars(Symbol(), Period()) - EMA;
    }
    if( prev_calculated > 0 ) {
        limit++;
    }
    ResizeBar();
    static double tmp;
    for( int idx = limit; idx >= 0; idx-- ) {
        tmp = iWave(idx, Symbol(), Period(), EMA);
        if( tmp > 0 ) {
            ClearBuffer(idx);
            OGBuffer[idx] = iOpen(NULL, 0, idx); CGBuffer[idx] = iClose(NULL, 0, idx);
            HGBuffer[idx] = iHigh(NULL, 0, idx); LGBuffer[idx] = iLow(NULL, 0, idx);
        } else if( tmp < 0 ) {
            ClearBuffer(idx);
            ORBuffer[idx] = iOpen(NULL, 0, idx); CRBuffer[idx] = iClose(NULL, 0, idx);
            HRBuffer[idx] = iHigh(NULL, 0, idx); LRBuffer[idx] = iLow(NULL, 0, idx);
        } else {
            ClearBuffer(idx);
            OBBuffer[idx] = iOpen(NULL, 0, idx); CBBuffer[idx] = iClose(NULL, 0, idx);
            HBBuffer[idx] = iHigh(NULL, 0, idx); LBBuffer[idx] = iLow(NULL, 0, idx);
        }
        if( ON_EMA ) {
            EmaHBuffer[idx] = iMA(Symbol(), Period(), EMA, 0, MODE_EMA, PRICE_HIGH, idx);
            EmaLBuffer[idx] = iMA(Symbol(), Period(), EMA, 0, MODE_EMA, PRICE_LOW, idx);
            EmaCBuffer[idx] = iMA(Symbol(), Period(), EMA, 0, MODE_EMA, PRICE_CLOSE, idx);
        }
    }
    if( ON_PRICES ) {
        static string name = "wave_price_green";
        if( ObjectFind(name) >= 0 ) {
            ObjectDelete(name);
        }
        if( !ObjectCreate(0, name, OBJ_ARROW_RIGHT_PRICE, 0, Time[0], iMA(Symbol(), Period(), EMA, 0, MODE_EMA, PRICE_HIGH, 0)) ) {
            Print( __FUNCTION__, ": Error = ", GetLastError() );
            return rates_total;
        }
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        name = "wave_price_red";
        if( ObjectFind(name) >= 0 ) {
            ObjectDelete(name);
        }
        if( !ObjectCreate(0, name, OBJ_ARROW_RIGHT_PRICE, 0, Time[0], iMA(Symbol(), Period(), EMA, 0, MODE_EMA, PRICE_LOW, 0)) ) {
            Print( __FUNCTION__, ": Error = ", GetLastError() );
            return rates_total;
        }
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    }
    if( ON_ALERT ) {
        int candles[4];
        candles[0] = OGBuffer[0] != EMPTY_VALUE ? 1 : (ORBuffer[0] != EMPTY_VALUE ? -1 : 0);
        candles[1] = OGBuffer[1] != EMPTY_VALUE ? 1 : (ORBuffer[1] != EMPTY_VALUE ? -1 : 0);
        candles[2] = OGBuffer[2] != EMPTY_VALUE ? 1 : (ORBuffer[2] != EMPTY_VALUE ? -1 : 0);
        candles[3] = OGBuffer[3] != EMPTY_VALUE ? 1 : (ORBuffer[3] != EMPTY_VALUE ? -1 : 0);
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

//+---------------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if( ON_PRICES ) {
        ObjectDelete("wave_price_green");
        ObjectDelete("wave_price_red");
    }
}

//+---------------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam,
                  const double& dparam, const string& sparam)
{
    if( id == CHARTEVENT_CHART_CHANGE ) {
        ResizeBar();
        ChartRedraw();
    }
}

//+---------------------------------------------------------------------------+
void ResizeBar()
{
    static int tmpS, tmpT;
    int scale, typeBar, size = 1;
    scale   = (int)ChartGetInteger(0, CHART_SCALE);
    typeBar = (int)ChartGetInteger(0, CHART_MODE);
    if( scale == tmpS && typeBar == tmpT ) { return; }
    if( typeBar == CHART_CANDLES ) {
        size = scale > 3 ? 5 : (scale == 0 ? 1 : scale);
    }
    SetIndexStyle(0, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(1, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(4, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(5, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(8, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(9, DRAW_HISTOGRAM, EMPTY, size);
    tmpS = scale; tmpT = typeBar;
}

//+---------------------------------------------------------------------------+
void ClearBuffer(const int bar = 0)
{
    OGBuffer[bar] = EMPTY_VALUE; HGBuffer[bar] = EMPTY_VALUE; LGBuffer[bar] = EMPTY_VALUE; CGBuffer[bar] = EMPTY_VALUE;
    ORBuffer[bar] = EMPTY_VALUE; HRBuffer[bar] = EMPTY_VALUE; LRBuffer[bar] = EMPTY_VALUE; CRBuffer[bar] = EMPTY_VALUE;
    OBBuffer[bar] = EMPTY_VALUE; HBBuffer[bar] = EMPTY_VALUE; LBBuffer[bar] = EMPTY_VALUE; CBBuffer[bar] = EMPTY_VALUE;
}

