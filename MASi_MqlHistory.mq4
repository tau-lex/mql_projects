//+---------------------------------------------------------------------------+
//|                                                     MASi_ML-Assistant.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "The script helps to prepare data for machine learning and to read forecast files."
#property version       "1.8"
#property icon          "ico/ml-assistant.ico";
#property strict

#include                "MASh_Include.mqh"


// #property indicator_label6  "Order Buy"
// #property indicator_type6   DRAW_HISTOGRAM
// #property indicator_color6  clrLightSeaGreen
// #property indicator_style6  STYLE_SOLID
// #property indicator_width6  1
// #property indicator_label7  "Order Sell"
// #property indicator_type7   DRAW_HISTOGRAM
// #property indicator_color7  clrMediumVioletRed
// #property indicator_style7  STYLE_SOLID
// #property indicator_width7  1

// double      OrderBBuffer[], OrderSBuffer[];

// input string            SECTION5 = "___ A D D I T I O N A L Y ___";//___ A D D I T I O N A L Y ___
// input BoolEnum          ON_HISTORY = Disable;                   // Signals from mql5 order history
// input string            HISTORY_FILE = "";                      // Csv file history



//init
    // SetIndexBuffer(5, OrderBBuffer);
    // SetIndexBuffer(6, OrderSBuffer);
    // orderFile = StringConcatenate( (StringLen(DIRECTORY) > 1 ? DIRECTORY + "/" : ""), HISTORY_FILE );
    // if( StringFind( orderFile, ".csv" ) == -1 )
    //     StringConcatenate( orderFile, ".csv" ); 

//calc
    // if( ON_HISTORY ) {          // Analyse history orders
    //     // if( TICK_COUNT <= 1 ) 
    //         ReadHistoryToIndicator( Symbol(), Period(), orderFile, OrderBBuffer, OrderSBuffer );
    // }




