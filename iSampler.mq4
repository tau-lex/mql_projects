//+------------------------------------------------------------------+
//|                                                    i_Sampler.mq5 |
//|                                        Copyright 2012, her.human |
//|                                              her.human@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, her.human"
#property link      "her.human@gmail.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_buffers 3
#property indicator_plots   2
//--- plot analog
#property indicator_label1  "analog"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrSpringGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot discrete
#property indicator_label2  "discrete"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrDimGray
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- input parameters
input int      bars_future=10;
input int      max_bars=10000;
input int      discrete_metod=1;
input double   porog=0.5;
input int      tp=500;
input int      sl=200;
//--- indicator buffers
double         analogBuffer[];
double         discreteBuffer[];
//--- global variable
double point;
string name;
int timesignal[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, analogBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, discreteBuffer, INDICATOR_DATA);

   point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   name = "iSampler";

   return 0;
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
    int i;
    int start = MathMin(rates_total-1, max_bars);
    for( i = start; i >= bars_future-1; i-- ) {
        analogBuffer[i - bars_future] = EMPTY_VALUE;
        discreteBuffer[i - bars_future] = EMPTY_VALUE;

        //--- расчет аналогового буфера 0    
        //--- максимум на bars_future баров вперед
        double price_high = high[ArrayMaximum(high, bars_future, i)];
        //--- минимум на bars_future баров вперед
        double price_low = low[ArrayMinimum(low, bars_future, i)];

        //--- изменение цены в плюс, относительно 0-го бара
        double deviation_plus = price_high - open[i];
        //--- изменение цены в минус, относительно 0-го бара
        double deviation_minus = open[i] - price_low;

        double value = (2.0 * deviation_plus) / (deviation_plus + deviation_minus) - 1;
        analogBuffer[i] = value;

        //--- расчет дискретного буфера 1
        switch( discrete_metod )
        {
            case 1: {
                if( value > porog ) {
                    discreteBuffer[i] = 1;
                } else if( value < -porog ) {
                    discreteBuffer[i] = -1;
                } else {
                    discreteBuffer[i] = 0;
                }
                break;
            }
            case 2: {
                if( (deviation_plus > tp * point) && (deviation_minus < sl * point) ) {
                    discreteBuffer[i] = 1;
                } else if( (deviation_plus < sl * point) && (deviation_minus > tp * point) ) {
                    discreteBuffer[i] = -1;
                } else {
                    discreteBuffer[i] = 0;
                }
                break;
            }
        }
    }
    return rates_total;
}

