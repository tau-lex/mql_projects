//+---------------------------------------------------------------------------+
//|                                                   MASi_KeltnerChannel.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Types of Keltner channel:"
#property description   "Original - A simple moving average from a typical price and trading range."
#property description   "Modified_1 - A exponential moving average from a typical price and average true range."
#property description   "Modified_2 - A exponential moving average from a close price and average true range."
#property description   "The idea of Chester W. Keltner."
#property version       "1.3"
#property icon          "ico/keltnerchannel.ico";
#property strict

#include                "MASh_Include.mqh"
#include                "MASh_Indicators.mqh"


//---------------------Indicators---------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5
//--- plot
#property indicator_label1  "Keltner EMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGray
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Keltner Higher"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMediumBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_label3  "Keltner Lower"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMediumBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label4  "Signal Buy"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLime
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
#property indicator_label5  "Signal Sell"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- indicator buffers
double      KPIndBuffer[];
double      KHighBuffer[], KLowBuffer[];
double      BuyBuffer[], SellBuffer[];

//-----------------Global variables-------------------------------------------+
//---
input int                   PERIOD      = 10;           // Period of indicator
input KELTNER_CHANNEL_TYPE  K_TYPE      = Modified_2;   // Type of Keltner channel
input int                   CHANNEL_PC  = 100;          // Size of channel in percent
input string                STRING      = "======= Signals =======";  // ======= Signals =======
input BOOL                  SGNL_ORIGIN = Disable;      // Original methodology
input BOOL                  SGNL_MOD    = Disable;      // Modified technique using a filter
//input BoolEnum              SGNL_SM_TR  = Disable;      // The rule of small Celtner trends
//---

//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, KPIndBuffer);
    SetIndexBuffer(1, KHighBuffer);
    SetIndexBuffer(2, KLowBuffer);
    SetIndexBuffer(3, BuyBuffer);
    SetIndexArrow(3, 236);
    SetIndexBuffer(4, SellBuffer);
    SetIndexArrow(4, 238);
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
        KPIndBuffer[idx] = iKeltnerChannel(idx, Symbol(), Period(), PERIOD, PriceIndicator, K_TYPE);
        KHighBuffer[idx] = iKeltnerChannel(idx, Symbol(), Period(), PERIOD, Higher, K_TYPE, CHANNEL_PC);
        KLowBuffer[idx]  = iKeltnerChannel(idx, Symbol(), Period(), PERIOD, Lower, K_TYPE, CHANNEL_PC);
        Signals(idx);
    }
    return rates_total;
}

//+---------------------------------------------------------------------------+
void Signals(const int bar)
{
    if( SGNL_ORIGIN ) {
        if( K_TYPE == Original ) {
            if( iHigh(Symbol(), Period(), bar) > iKeltnerChannel(bar, Symbol(), Period(), PERIOD, Higher, K_TYPE, CHANNEL_PC) ) {
                BuyBuffer[bar] = iClose(Symbol(), Period(), bar);
            }
            if( iLow(Symbol(), Period(), bar) < iKeltnerChannel(bar, Symbol(), Period(), PERIOD, Lower, K_TYPE, CHANNEL_PC) ) {
                SellBuffer[bar] = iClose(Symbol(), Period(), bar);
            }
        } else {
            if( iClose(Symbol(), Period(), bar) > iKeltnerChannel(bar, Symbol(), Period(), PERIOD, Higher, K_TYPE, CHANNEL_PC) ) {
                BuyBuffer[bar] = iClose(Symbol(), Period(), bar);
            }
            if( iClose(Symbol(), Period(), bar) < iKeltnerChannel(bar, Symbol(), Period(), PERIOD, Lower, K_TYPE, CHANNEL_PC) ) {
                SellBuffer[bar] = iClose(Symbol(), Period(), bar);
            }
        }
    }
    if( SGNL_MOD ) {
        if( ( iClose(Symbol(), Period(), bar) <
              ( iMA(Symbol(), Period(), 4, 0, MODE_EMA, PRICE_CLOSE, bar+1) -
                iATR(Symbol(), Period(), PERIOD, bar+1)*0.77*0.01*CHANNEL_PC ) ) &&
            ( iClose(Symbol(), Period(), bar) >
              iMA(Symbol(), Period(), 274, 0, MODE_EMA, PRICE_CLOSE, bar) ) ) {
            BuyBuffer[bar] = iClose( Symbol(), Period(), bar );
        }
        if( ( iClose(Symbol(), Period(), bar) >
              ( iMA(Symbol(), Period(), 4, 0, MODE_EMA, PRICE_CLOSE, bar+1) +
                iATR(Symbol(), Period(), PERIOD, bar+1)*0.77*0.01*CHANNEL_PC ) ) &&
            ( iClose(Symbol(), Period(), bar) <
              iMA(Symbol(), Period(), 274, 0, MODE_EMA, PRICE_CLOSE, bar) ) ) {
            SellBuffer[bar] = iClose( Symbol(), Period(), bar );
        }
    }
    //if( SGNL_SM_TR ) {
    //}
}

