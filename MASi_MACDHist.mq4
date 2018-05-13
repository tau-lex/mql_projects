//+---------------------------------------------------------------------------+
//|                                                         MASi_MACDHist.mq4 |
//|                                       Copyright © 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
//|                             Idea search functions from FX5_Divergence.mq4 |
//|                                                     Copyright © 2007, FX5 |
//|                                                             hazem@uk2.net |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright © 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Moving Averages Convergence/Divergence."
#property description   "MACD line + Signal line + Histogram."
#property description   "Divergence indicator."
#property version       "1.61"
#property icon          "ico/macdhist.ico"
#property strict

#include                <MovingAverages.mqh>
#include                "MASh_Include.mqh"

//---------------------Indicators---------------------------------------------+
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   9
//--- plot
#property indicator_label1  "MACD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightSeaGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrChocolate
#property indicator_style2  STYLE_DOT
#property indicator_width2  1
#property indicator_label3  "MACD Histogram"
#property indicator_type3   DRAW_NONE
#property indicator_label4  "Histogram"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
#property indicator_label5  "Histogram"
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_color5  C'0,90,0'
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
#property indicator_label6  "Histogram"
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color6  clrRed
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2
#property indicator_label7  "Histogram"
#property indicator_type7   DRAW_HISTOGRAM
#property indicator_color7  C'142,0,0'
#property indicator_style7  STYLE_SOLID
#property indicator_width7  2
#property indicator_label8  "Bull Divergence"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrLime
#property indicator_width8  1
#property indicator_label9  "Bear Divergence"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrDarkOrange
#property indicator_width9  1
//--- indicator buffers
double          MacdBuffer[];
double          SignalBuffer[];
double          MacdHistBuffer[];
double          HistGUBuffer[], HistGDBuffer[];
double          HistRDBuffer[], HistRUBuffer[];
double          BullDivBuffer[], BearDivBuffer[];

//-----------------Global variables-------------------------------------------+
//---
input string    SECTION1        = "___ Main parameters ___";//.
input int       FastEMA         = 12;       // Fast EMA Period
input int       SlowEMA         = 26;       // Slow EMA Period
input int       SignalEMA       = 9;        // Signal SMA Period
input ENUM_APPLIED_PRICE
                PriceType       = PRICE_CLOSE; // Price type
input BoolEnum  ON_MACD         = Enable;   // MACD line
input BoolEnum  ON_SIGNAL       = Enable;   // Signal line
input string    SECTION2        = "___ Divergence parameters ___";//.
input BoolEnum  ON_DIVER_HIST   = Disable;  // MACD Histogram divergence indicator
input BoolEnum  ON_DIVER_LINE   = Disable;  // MACD Line divergence indicator
input BoolEnum  ON_CLASSIC      = Enable;   // Search classical
input BoolEnum  ON_HIDDEN       = Enable;   // Search hidden
input BoolEnum  ON_EXPAND       = Enable;   // Search extended
input BoolEnum  ON_TREND_LINES  = Enable;   // Show trend lines
input BoolEnum  ON_DIVER_SYMBOL = Enable;   // Show divergence indicator
input BoolEnum  ON_ALERT        = Enable;   // Show alerts
//---
const int       SEARCH_LEN      = 120;      // Lenght of peacks search
const int       SEARCH_LEN_Z    = 90;       // Lenght of zero check
//---
string          prefix          = "MASi_MACDHist";
string          indicatorName;

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer( 0, MacdBuffer );
    SetIndexBuffer( 1, SignalBuffer );
    SetIndexBuffer( 2, MacdHistBuffer );
    SetIndexBuffer( 3, HistGUBuffer );
    SetIndexBuffer( 4, HistGDBuffer );
    SetIndexBuffer( 5, HistRDBuffer );
    SetIndexBuffer( 6, HistRUBuffer );
    if( ON_DIVER_HIST || ON_DIVER_LINE ) {
        SetIndexBuffer( 7, BullDivBuffer );
        SetIndexBuffer( 8, BearDivBuffer );
        SetIndexArrow( 7, 246 );        // 228, 236, 246
        SetIndexArrow( 8, 248 );        // 230, 238, 248
        if( !ON_DIVER_SYMBOL ) {
            SetIndexStyle( 7, DRAW_NONE );
            SetIndexStyle( 8, DRAW_NONE );
        }
    }
    if( !ON_MACD ) {
        SetIndexStyle( 0, DRAW_NONE );
    }
    if( !ON_SIGNAL ) {
        SetIndexStyle( 1, DRAW_NONE );
    }
    IndicatorDigits( Digits + 2 );
    indicatorName = "MACD ( " + IntegerToString( FastEMA ) + ", " + 
                     IntegerToString( SlowEMA ) + ", " + IntegerToString( SignalEMA ) + " )";
    IndicatorShortName( indicatorName );
    if( FastEMA <= 1 || SlowEMA <= 1 || SignalEMA <= 1 || FastEMA >= SlowEMA ) {
        Print( "Wrong input parameters" );
        return INIT_FAILED;
    }
    return INIT_SUCCEEDED;
}
  
//+---------------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
    int limit = rates_total - prev_calculated;
    if( prev_calculated > 0 ) {
        limit += 2;
    }
    for( int idx = limit-1; idx >= 0; idx-- ) {
        MacdBuffer[idx] = iMA(NULL, 0, FastEMA, 0, MODE_EMA, PriceType, idx) -
                            iMA(NULL, 0, SlowEMA, 0, MODE_EMA, PriceType, idx);
    }
    ExponentialMAOnBuffer(rates_total, prev_calculated, 0, SignalEMA, MacdBuffer, SignalBuffer);
    for( int idx = limit-2; idx >= 0; idx-- ) {
        HistGUBuffer[idx] = EMPTY_VALUE;
        HistGDBuffer[idx] = EMPTY_VALUE;
        HistRDBuffer[idx] = EMPTY_VALUE;
        HistRUBuffer[idx] = EMPTY_VALUE;
        MacdHistBuffer[idx] = MacdBuffer[idx] - SignalBuffer[idx];
        if( MacdHistBuffer[idx] >= 0 ) {
            if( MacdHistBuffer[idx] >= MacdHistBuffer[idx+1] ) {
                HistGUBuffer[idx] = MacdHistBuffer[idx];
            } else {
                HistGDBuffer[idx] = MacdHistBuffer[idx];
            }
        } else {
            if( MacdHistBuffer[idx] <= MacdHistBuffer[idx+1] ) {
                HistRDBuffer[idx] = MacdHistBuffer[idx];
            } else {
                HistRUBuffer[idx] = MacdHistBuffer[idx];
            }
        }
    }
    if( ON_DIVER_HIST || ON_DIVER_LINE ) {
        for( int idx = limit-1; idx >= 0; idx-- ) {
            if( ON_DIVER_HIST ) {
                CatchBearishDivergence(idx, MacdHistBuffer, BearDivBuffer);
                CatchBullishDivergence(idx, MacdHistBuffer, BullDivBuffer);
            }
            if( ON_DIVER_LINE ) {
                if( ON_MACD ) {
                    CatchBearishDivergence(idx, MacdBuffer, BearDivBuffer);
                    CatchBullishDivergence(idx, MacdBuffer, BullDivBuffer);
                }
            }
        }
    }
    return rates_total - 1;
}

//+---------------------------------------------------------------------------+
void OnDeinit(const int)
{
    string label;
    for( int i = ObjectsTotal()-1; i >= 0; i-- ) {
        label = ObjectName(i);
        if( StringFind(label, prefix) >= 0 ) {
            ObjectDelete(label);
        }
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
void CatchBullishDivergence(const int bar, const double &array[],
                            double &divArray[], const bool zeroLine = false)
{
    int troughIdx0 = bar;
    if( !IsTrough( troughIdx0, array, zeroLine ) ) {
        return;
    }
    int troughIdx1 = LastTroughIndex( troughIdx0, array, zeroLine );
    if( troughIdx1 < 0 ) {
        return;
    }
    int winID   = WindowFind( indicatorName );
    int lowIdx0 = ArrayMinValueIndex( Low, bar > 0 ? troughIdx0-1 : 0, 3 );
    int lowIdx1 = ArrayMinValueIndex( Low, troughIdx1-1, 3 );
    if( lowIdx0 < 0 || lowIdx1 < 0 ) {
        return;
    }
    if( ON_CLASSIC ) {
        if( array[troughIdx1] < array[troughIdx0] ) {
            if( Low[lowIdx1] > Low[lowIdx0] ) {
                divArray[troughIdx0] = array[troughIdx0];
                if( ON_TREND_LINES ) {
                    DrawTrendLine( Time[lowIdx0], Time[lowIdx1], Low[lowIdx0], Low[lowIdx1], Green, STYLE_SOLID );
                    DrawTrendLine( Time[troughIdx0], Time[troughIdx1], array[troughIdx0], array[troughIdx1], Green, STYLE_SOLID, winID );
                }
                if( ON_ALERT ) {
                    if( bar <= 3 ) {
                        DisplayAlert( troughIdx0, "Classical bullish divergence on" );
                    }
                }
            }
        }
    }
    if( ON_HIDDEN ) {
        if( array[troughIdx1] > array[troughIdx0] ) {
            if( Low[lowIdx1] < Low[lowIdx0] ) {
                divArray[troughIdx0] = array[troughIdx0];
                if( ON_TREND_LINES ) {
                    DrawTrendLine( Time[lowIdx0], Time[lowIdx1], Low[lowIdx0], Low[lowIdx1], Green, STYLE_DOT );
                    DrawTrendLine( Time[troughIdx0], Time[troughIdx1], array[troughIdx0], array[troughIdx1], Green, STYLE_DOT, winID );
                }
                if( ON_ALERT ) {
                    if( bar <= 3 ) {
                        DisplayAlert( troughIdx0, "Hidden bullish divergence on" );
                    }
                }
            }
        }
    }
    if( ON_EXPAND ) {
        double delta = ( MathMin( Open[lowIdx1], Close[lowIdx1] ) - Low[lowIdx1] +
                         MathMin( Open[lowIdx0], Close[lowIdx0] ) - Low[lowIdx0] )
                       / 2.0;
        if( array[troughIdx1] < array[troughIdx0] ) {
            if( MathAbs(Low[lowIdx1] - Low[lowIdx0]) < delta ) {
                divArray[troughIdx0] = array[troughIdx0];
                if( ON_TREND_LINES ) {
                    DrawTrendLine( Time[lowIdx0], Time[lowIdx1], Low[lowIdx0], Low[lowIdx1], Green, STYLE_DASHDOT );
                    DrawTrendLine( Time[troughIdx0], Time[troughIdx1], array[troughIdx0], array[troughIdx1], Green, STYLE_DASHDOT, winID );
                }
                if( ON_ALERT ) {
                    if( bar <= 3 ) {
                        DisplayAlert( troughIdx0, "Expand bullish divergence on" );
                    }
                }
            }
        }
    }
}

//+---------------------------------------------------------------------------+
void CatchBearishDivergence(const int bar, const double &array[],
                            double &divArray[], const bool zeroLine = false)
{
    int peakIdx0 = bar;
    if( !IsPeak( peakIdx0, array, zeroLine ) ) {
        return;
    }
    int peakIdx1 = LastPeakIndex( peakIdx0, array, zeroLine );
    if( peakIdx1 < 0 ) {
        return;
    }
    int winID    = WindowFind( indicatorName );
    int highIdx0 = ArrayMaxValueIndex( High, bar > 0 ? peakIdx0-1 : 0, 3 );
    int highIdx1 = ArrayMaxValueIndex( High, peakIdx1-1, 3 );
    if( highIdx0 < 0 || highIdx1 < 0 ) {
        return;
    }
    if( ON_CLASSIC ) {
        if( array[peakIdx1] > array[peakIdx0] ) {
            if( High[highIdx1] < High[highIdx0] ) {
                divArray[peakIdx0] = array[peakIdx0];
                if( ON_TREND_LINES ) {
                    DrawTrendLine( Time[highIdx0], Time[highIdx1], High[highIdx0], High[highIdx1], Red, STYLE_SOLID );
                    DrawTrendLine( Time[peakIdx0], Time[peakIdx1], array[peakIdx0], array[peakIdx1], Red, STYLE_SOLID, winID );
                }
                if( ON_ALERT ) {
                    if( bar <= 3 ) {
                        DisplayAlert( peakIdx0, "Classical bearish divergence on" );
                    }
                }
            }
        }
    }
    if( ON_HIDDEN ) {
        if( array[peakIdx1] < array[peakIdx0] ) {
            if( High[highIdx1] > High[highIdx0] ) {
                divArray[peakIdx0] = array[peakIdx0];
                if( ON_TREND_LINES ) {
                    DrawTrendLine( Time[highIdx0], Time[highIdx1], High[highIdx0], High[highIdx1], Red, STYLE_DOT );
                    DrawTrendLine( Time[peakIdx0], Time[peakIdx1], array[peakIdx0], array[peakIdx1], Red, STYLE_DOT, winID );
                }
                if( ON_ALERT ) {
                    if( bar <= 3 ) {
                        DisplayAlert( peakIdx0, "Hidden bearish divergence on" );
                    }
                }
            }
        }
    }
    if( ON_EXPAND ) {
        double delta = ( High[highIdx1] - MathMax( Open[highIdx1], Close[highIdx1] ) +
                         High[highIdx0] - MathMax( Open[highIdx0], Close[highIdx0] ) )
                       / 2.0;
        if( array[peakIdx1] > array[peakIdx0] ) {
            if( MathAbs(High[highIdx1] - High[highIdx0]) < delta ) {
                divArray[peakIdx0] = array[peakIdx0];
                if( ON_TREND_LINES ) {
                    DrawTrendLine( Time[highIdx0], Time[highIdx1], High[highIdx0], High[highIdx1], Red, STYLE_DASHDOT );
                    DrawTrendLine( Time[peakIdx0], Time[peakIdx1], array[peakIdx0], array[peakIdx1], Red, STYLE_DASHDOT, winID );
                }
                if( ON_ALERT ) {
                    if( bar <= 3 ) {
                        DisplayAlert( peakIdx0, "Expand bearish divergence on" );
                    }
                }
            }
        }
    }
}

//+---------------------------------------------------------------------------+
bool IsPeak(const int bar, const double &array[],
            const bool zeroLine = false)
{   
    if( bar >= Bars - 3 ) {
        return false;
    }
    if( bar > 0 ) {
        if( array[bar] - array[bar-1] < 0 ) {
            return false;
        }
        if( bar > 1 ) {
            if( array[bar] - array[bar-2] < 0 ) { //-1 <= -2
                return false;
            }
        }
    }
    if( array[bar] - array[bar+1] < 0 ) {
        return false;
    }
    if( array[bar] - array[bar+2] < 0 ) { // +1 <= +2
        return false;
    }
    if( zeroLine ) {
        if( array[bar] <= 0 ) {
            return false;
        }
        for( int idx = bar+1; idx < bar+SEARCH_LEN_Z && idx < Bars-2; idx++ ) {
            if( array[idx] < 0 ) {
                return true;
            }
            if( array[bar] - array[idx] < 0 ) {
                return false;
            }
        }
    } else {
        if( array[bar] <= 0 ) {
            return false;
        }
        return true;
    }
    return false;
    // if( bar > 0 ) {
    //     if( array[bar]>0 && array[bar]>array[bar+1] && array[bar]>array[bar-1] ) {
    //         // for( int i = bar+1; i < Bars; i++ ) {
    //         //     if( array[i] <= 0 ) {
    //         //         return true;
    //         //     }
    //         //     if( array[i] > array[bar] ) { //  2 extremum?
    //         //         break;
    //         //     }
    //         // }
    //         if( array[bar] > array[bar+2] ) {
    //             return true;
    //         }
    //     }
    // }
    // return false;
}
//+---------------------------------------------------------------------------+
int LastPeakIndex(const int bar, const double &array[], const bool zeroLine = true)
{
    if( bar >= Bars - 3 ) {
        return -1;
    }
    bool zeroFlag = false;
    for( int idx = bar+3; idx < bar+SEARCH_LEN && idx < Bars-2; idx++ ) {
        if( zeroLine ) {
            if( !zeroFlag ) {
                continue;
            }
            if( array[idx] <= 0 ) {
                zeroFlag = true;
                continue;
            }
        }
        if( ( array[idx] - array[idx+1] < 0 ) || 
            ( array[idx] - array[idx-1] < 0 ) ) {
            continue;
        }
        if( ( array[idx] - array[idx+2] < 0 ) || 
            ( array[idx] - array[idx-2] < 0 ) ) {
            continue;
        }
        return idx;
    }
    return -1;
    // for( int i=bar+5; i < Bars-3; i++ ) {
    //     if( array[i] >= array[i+1] && array[i] > array[i+2] &&
    //         array[i] >= array[i-1] && array[i] > array[i-2]) {
    //         return i;
    //     }
    // }
    // return -1;
}

//+---------------------------------------------------------------------------+
bool IsTrough(const int bar, const double &array[],
              const bool zeroLine = false)
{
    if( bar >= Bars - 3 ) {
        return false;
    }
    if( bar > 0 ) {
        if( array[bar] - array[bar-1] > 0 ) {
            return false;
        }
        if( bar > 1 ) {
            if( array[bar] - array[bar-2] > 0 ) { //-1 > -2
                return false;
            }
        }
    }
    if( array[bar] - array[bar+1] > 0 ) {
        return false;
    }
    if( array[bar] - array[bar+2] > 0 ) { //+1 >= +2
        return false;
    }
    if( zeroLine ) {
        if( array[bar] >= 0 ) {
            return false;
        }
        for( int idx = bar+1; idx < bar+SEARCH_LEN_Z && idx < Bars-2; idx++ ) {
            if( array[idx] > 0 ) {
                return true;
            }
            if( array[bar] - array[idx] > 0 ) {
                return false;
            }
        }
    } else {
        if( array[bar] >= 0 ) {
            return false;
        }
        return true;
    }
    return false;
    // if( bar > 0 ) {
    //     if( array[bar] < 0 && ( array[bar] - array[bar-1] < 0 ) ) {
    //         // for( int i = bar+1; i < Bars; i++ ) {
    //         //     if( array[i] >= 0 ) {
    //         //         return true;
    //         //     }
    //         //     if( array[i] < array[bar] ) { //  2 extremum?
    //         //         break;
    //         //     }
    //         // }
    //         if( ( array[bar] - array[bar+2] ) < 0 &&
    //             ( array[bar] - array[bar+1] ) < 0 ) {
    //             return true;
    //         }
    //     }
    // }
    // return false;
}
//+---------------------------------------------------------------------------+
int LastTroughIndex(const int bar, const double &array[], const bool zeroLine = true)
{  
    if( bar >= Bars - 3 ) {
        return -1;
    }
    bool zeroFlag = false;
    for( int idx = bar+3; idx < bar+SEARCH_LEN && idx < Bars-2; idx++ ) {
        if( zeroLine ) {
            if( !zeroFlag ) {
                continue;
            }
            if( array[idx] >= 0 ) {
                zeroFlag = true;
                continue;
            }
        }
        if( ( array[idx] - array[idx+1] > 0 ) || 
            ( array[idx] - array[idx-1] > 0 ) ) {
            continue;
        }
        if( ( array[idx] - array[idx+2] > 0 ) || 
            ( array[idx] - array[idx-2] > 0 ) ) {
            continue;
        }
        return idx;
    }
    return -1;
    // for( int i=bar+5; i < Bars-3; i++ ) {
    //     if( ( array[i] - array[i+1] < 0 ) && 
    //         ( array[i] - array[i+2] < 0 ) &&
    //         ( array[i] - array[i-1] < 0 ) && 
    //         ( array[i] - array[i-2] < 0 ) ) {
    //         return i;
    //     }
    // }
    // return -1;
}

//+---------------------------------------------------------------------------+
void DisplayAlert(const int bar, const string message)
{
    static datetime lastAlertTime = 0;
    if( Time[bar] > lastAlertTime ) {
        lastAlertTime = Time[bar];
        Alert( message, ": ", bar, ": ", Symbol(), " | ", Period() );
    }
}

//+---------------------------------------------------------------------------+
void DrawTrendLine(const datetime time0, const datetime time1,
                   const double var0, const double var1,
                   const color lineColor, const double style,
                   int winIndex = 0)
{   //WindowFind( indicatorName );
    if( winIndex < 0 || winIndex >= WindowsTotal() ) {
        return;
    }
    string label = prefix + "_" + IntegerToString( winIndex ) + "_" + TimeToStr( time0 );
    ObjectDelete( label );
    if( !ObjectCreate( label, OBJ_TREND, winIndex, time0, var0, time1, var1 ) ) {
        Print( winIndex, " : ", GetLastError() );
    }
    ObjectSet( label, OBJPROP_RAY, 0 );
    ObjectSet( label, OBJPROP_COLOR, lineColor );
    ObjectSet( label, OBJPROP_STYLE, style );
}

//+---------------------------------------------------------------------------+
void ResizeBar()
{
    static int tmpScale, tmpType;
    int scale, typeBar, size = 1;
    scale   = (int)ChartGetInteger(0, CHART_SCALE);
    typeBar = (int)ChartGetInteger(0, CHART_MODE);
    if( scale == tmpScale ) {
        if( typeBar == tmpType ) {
            return;
        }
    }
    if( typeBar == CHART_CANDLES ) {
        size = scale > 3 ? 5 : (scale == 0 ? 1 : scale);
    }
    SetIndexStyle(3, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(4, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(5, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(6, DRAW_HISTOGRAM, EMPTY, size);
    tmpScale = scale; tmpType = typeBar;
}

//+---------------------------------------------------------------------------+
