//+---------------------------------------------------------------------------+
//|                                                     MASi_ML-DataSaver.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017-2018, Terentyev Aleksey"
// #property link          "https://www.mql5.com/ru/users/terentyev23"
#property link          "https://goo.gl/mkLRyq"
#property description   "The script helps to prepare data for machine learning."
#property description   "How to use the utility (RUS): https://goo.gl/mkLRyq"
#property description   "---"
#property description   "The standard values for the signals:"
#property description   "BouncedMA FilterM \t= 5 (Period (Filter))"
#property description   "BouncedMA FilterP \t= 3 (Period (Filter))"
#property description   "Sampler \t\t= 10 (Period)"
#property description   "Impulse \t\t\t= 13 or 26 (EMA), 12, 26, 9 (MACD)"
#property description   "Wave \t\t\t= 34 (EMA)"
#property version       "1.01"
#property icon          "ico/ml-assistant.ico";
#property strict

#include                "MASh_Include.mqh"
#include                "MASh_Indicators.mqh"


//+---------------------------------------------------------------------------+
//|   D E F I N E S                                                           |
//+---------------------------------------------------------------------------+
enum STOREDDATATYPE {
    Apart = 0,
    Together = 1
};


//+---------------------------------------------------------------------------+
//|   I N D I C A T O R S                                                     |
//+---------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot
#property indicator_label1  "Signal Buy"
#property indicator_type1   DRAW_NONE
#property indicator_label2  "Signal Sell"
#property indicator_type2   DRAW_NONE
//--- indicator buffers
double      SignalP_Buffer[], SignalN_Buffer[];


//+---------------------------------------------------------------------------+
//|   G L O B A L   V A R I A B L E S                                         |
//+---------------------------------------------------------------------------+
//---
// input string            SECTION1 = "___ G E N E R A L ___";  //___ G E N E R A L ___

input string            SECTION2 = "___ D A T A   F O R   M L   M O D E L ___";  //.
input BOOL              ON_TIME = Disable;                  // Time data (Y, M, D, DoW, DoY, h, m)
input BOOL              ON_MARKET = Enable;                 // Market data (O, H, L, C)
input BOOL              ON_EMA = Disable;                   // EMA levels
input string            EMA_LEVELS = "13, 26, 60, 130";     // EMA levels (Integer numbers separated by commas)
input BOOL              ON_MACD = Disable;                  // MACD levels (Line, Histogram)
input string            MACD_LEVELS = "12, 26, 9";          // MACD levels (Three integer numbers, separated by commas)
input BOOL              ON_ATR = Disable;                   // ATR indicator
input int               ATR_PERIOD = 14;                    // ATR period
input BOOL              ON_CCI = Disable;                   // CCI indicator
input int               CCI_PERIOD = 14;                    // CCI period
input BOOL              ON_RSI = Disable;                   // RSI indicator
input int               RSI_PERIOD = 14;                    // RSI period
input BOOL              ON_USDX = Disable;                  // USD index (USDX)
input BOOL              ON_EURX = Disable;                  // EUR index (EURX)

input string            SECTION3 = "___ S I G N A L   F O R   T A R G E T ___"; //.
input INDICATOR_TYPE    INDICATOR = BouncedMA_FilterM;      // Indicator for prediction
input int               EMA_D1 = 5;                         // EMA or Period
input int               MACD_FAST = 12;                     // MACD Fast
input int               MACD_SLOW = 26;                     // MACD Slow
input int               MACD_SIGNAL = 9;                    // MACD Signal
input int               ML_DEPTH = 0;                       // Depth of prediction (From bar to bar+N)
input int               ML_SIZE = 100;                      // Size history for prediction (data_xx)

input string            SECTION5 = "___ S Y S T E M ___";   //.
input string            DIRECTORY = "ML-Assistant";         // Path to all files ($MT4$/MQL4/Files/.../)
input BOOL              ON_HEADERS = Disable;               // Headers for data
input STOREDDATATYPE    ON_TOGETHER_DATASET = Apart;        // File type for Features + Target data
input string            SEPARATOR = ";";                    // Csv file separator
input string            PREFIX = "";                        // Prefix (PrefixSYMBOLPERIOD_x.csv)
input string            POSTFIX = "";                       // Postfix (SYMBOLPERIODPostfix_x.csv)
extern double           INDICATOR_GAIN = 0.9;               // Minimum signal threshold [0.0 - 1.0]

//--- simple global variables
string                  indicatorName, glVarPredictSize, glVarPredictDepth, glVarAssistant;
string                  trainX, trainY;
string                  predictX;
string                  emaLevelsS[], macdLevelsS[];
int                     emaCount, emaLevels[], macdLevels[3];


//+---------------------------------------------------------------------------+
//|   M A I N   F U N C T I O N S                                             |
//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, SignalP_Buffer);
    SetIndexBuffer(1, SignalN_Buffer);
    if( InitCheck() ) {
        return INIT_FAILED;
    }
    // Global variables
    indicatorName = StringConcatenate( "ML-DataSaver ( ", GetIndicatorString(INDICATOR), " )" );
    IndicatorShortName(indicatorName);
    glVarPredictSize = StringConcatenate("MASv_", Symbol(), Period(), "_PredictSize");
    GlobalVariableSet(glVarPredictSize, ML_SIZE);
    glVarPredictDepth = StringConcatenate("MASv_", Symbol(), Period(), "_PredictDepth");
    GlobalVariableSet(glVarPredictDepth, ML_DEPTH);
    glVarAssistant = StringConcatenate("MASv_", Symbol(), Period(), "_Assistant");
    GlobalVariableSet(glVarAssistant, 1.0);
    // Strings to arrays
    if( ON_EMA ) {
        emaCount = StringSplit(EMA_LEVELS, ',', emaLevelsS);
        ArrayResize(emaLevels, emaCount);
        for( int idx = 0; idx < emaCount; idx++ ) {
            emaLevels[idx] = (int)emaLevelsS[idx];
        }
    }
    if( ON_MACD ) {
        int macdCount = StringSplit(MACD_LEVELS, ',', macdLevelsS);
        if( macdCount != 3 ) {
            Alert("Warning! Count of MACD parameters non-equal three.");
        }
        for( int idx = 0; idx < 3; idx++ ) {
            macdLevels[idx] = (int)macdLevelsS[idx];
        }
    }
    // File names
    trainX = StringConcatenate(DIRECTORY, "/", PREFIX, Symbol(), Period(), POSTFIX, "_x.csv");
    trainY = StringConcatenate(DIRECTORY, "/", PREFIX, Symbol(), Period(), POSTFIX, "_y.csv");
    predictX = StringConcatenate(DIRECTORY, "/", PREFIX, Symbol(), Period(), POSTFIX, "_xx.csv");
    // Done
    return INIT_SUCCEEDED;
}

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
        if( limit < EMA_D1 ) {
            limit += EMA_D1;
        }
    }
    for( int idx = limit-1; idx >= 0; idx-- ) { // Main cycle
        double signal = 0.0;
        if( INDICATOR == Percentage_Increments ) {
            signal = iPercentageIncrements(idx, Symbol(), Period());
        } else if( INDICATOR == BouncedMA ) {
            signal = iBouncedMA(idx, Symbol(), Period(), MODE_EMA);
        } else if( INDICATOR == BouncedMA_FilterM ) {
            signal = iBouncedMAFilteredM(idx, Symbol(), Period(), MODE_EMA, 2, EMA_D1);
        } else if( INDICATOR == BouncedMA_FilterP ) {
            signal = iBouncedMAFilteredP(idx, Symbol(), Period(), MODE_EMA, 2, EMA_D1);
        } else if( INDICATOR == Sampler ) {
            signal = iSampler(idx, Symbol(), Period(), EMA_D1);
        } else if( INDICATOR == Custom ) {
            signal = iCustomSignal(idx, Symbol(), Period(), DIRECTORY);
        } else if( INDICATOR == Impulse ) {
            signal = iImpulse(idx, Symbol(), Period(), EMA_D1, MACD_FAST, MACD_SLOW, MACD_SIGNAL);
        } else if( INDICATOR == Wave ) {
            signal = iWave(idx, Symbol(), Period(), EMA_D1);
        } else if( INDICATOR == MACD_Histogram ) {
            signal = iMACDHist(Symbol(), Period(), MACD_FAST, MACD_SLOW, MACD_SIGNAL, PRICE_CLOSE, MODE_EMA, idx);
        }
        SignalP_Buffer[idx] = 0.0;
        SignalN_Buffer[idx] = 0.0;
        signal = MathAbs(signal) >= INDICATOR_GAIN ? signal : 0.0;
        if( signal > 0 ) {
            SignalP_Buffer[idx] = signal;
        } else if( signal < 0 ) {
            SignalN_Buffer[idx] = signal;
        }
    }
    if( NewBar() ) {            // Save all data
        WriteData(Symbol(), Period(), Bars-1, ML_SIZE, trainX, trainY, ML_DEPTH);
        WriteData(Symbol(), Period(), ML_SIZE-1, 0, predictX);
    }
    return rates_total;
}

void OnDeinit(const int reason)
{
    GlobalVariableDel(glVarPredictSize);
    GlobalVariableDel(glVarPredictDepth);
    GlobalVariableDel(glVarAssistant);
}


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
void WriteData(const string symbol, const int period,
               const int begin, const int end,
               const string fileX, const string fileY = "",
               const int yShift = 0)
{   // Main data file
    string  lineBuffer;
    int     digits = (int)MarketInfo(symbol, MODE_DIGITS);
    int     handleX = FileOpen(fileX, FILE_WRITE | FILE_CSV | FILE_SHARE_WRITE, StringGetChar(SEPARATOR, 0));
    if( ON_HEADERS ) {
        lineBuffer = "";
        if( ON_TIME ) {
            lineBuffer += StringConcatenate("Year", SEPARATOR, "Month", SEPARATOR, "Day", SEPARATOR,
                                            "Day of Week", SEPARATOR, "Day of Year", SEPARATOR,
                                            "Hour", SEPARATOR, "Minute" );
        }
        if( ON_MARKET ) {
            if( ON_TIME ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate("Open", SEPARATOR, "High", SEPARATOR, "Low", SEPARATOR, "Close" );
        }
        if( ON_EMA ) {
            if( ON_TIME || ON_MARKET ) { lineBuffer += SEPARATOR; }
            for( int jdx = 0; jdx < emaCount; jdx++ ) {
                lineBuffer += StringConcatenate("EMA ", emaLevelsS[jdx]);
                lineBuffer += (jdx < emaCount-1 ? SEPARATOR : "");
            }
        }
        if( ON_MACD ) {
            if( ON_TIME || ON_MARKET || ON_EMA ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate("MACD Line", SEPARATOR, "MACD Hist");
        }
        if( ON_ATR ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate("ATR ", (string)ATR_PERIOD);
        }
        if( ON_CCI ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate("CCI ", (string)CCI_PERIOD);
        }
        if( ON_RSI ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR || ON_CCI ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate("RSI ", (string)RSI_PERIOD);
        }
        if( ON_USDX ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR || ON_CCI || ON_RSI ) { lineBuffer += SEPARATOR; }
            lineBuffer += "USDX";
        }
        if( ON_EURX ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR || ON_CCI || ON_RSI || ON_USDX ) { lineBuffer += SEPARATOR; }
            lineBuffer += "EURX";
        }
        if( ON_TOGETHER_DATASET ) {
            lineBuffer += SEPARATOR;
            lineBuffer += GetIndicatorString(INDICATOR);
        }
        FileWrite(handleX, lineBuffer);
    }
    for( int idx = begin; idx >= end+yShift; idx-- ) {
        lineBuffer = "";
        if( ON_TIME ) {
            lineBuffer += StringConcatenate(IntegerToString( TimeYear( iTime(symbol, period, idx) ) ), SEPARATOR,
                                            IntegerToString( TimeMonth( iTime(symbol, period, idx) ) ), SEPARATOR,
                                            IntegerToString( TimeDay( iTime(symbol, period, idx) ) ), SEPARATOR,
                                            IntegerToString( TimeDayOfWeek( iTime(symbol, period, idx) ) ), SEPARATOR,
                                            IntegerToString( TimeDayOfYear( iTime(symbol, period, idx) ) ), SEPARATOR,
                                            IntegerToString( TimeHour( iTime(symbol, period, idx) ) ), SEPARATOR,
                                            IntegerToString( TimeMinute( iTime(symbol, period, idx) ) ));
        }
        if( ON_MARKET ) {
            if( ON_TIME ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate(DoubleToStr( iOpen(symbol, period, idx), digits ), SEPARATOR,
                                            DoubleToStr( iHigh(symbol, period, idx), digits ), SEPARATOR,
                                            DoubleToStr( iLow(symbol, period, idx), digits ), SEPARATOR,
                                            DoubleToStr( iClose(symbol, period, idx), digits ) );
        }
        if( ON_EMA ) {
            if( ON_TIME || ON_MARKET ) { lineBuffer += SEPARATOR; }
            for( int jdx = 0; jdx < emaCount; jdx++ ) {
                lineBuffer += DoubleToStr( iMA(symbol, period, emaLevels[jdx], 0, MODE_EMA, PRICE_CLOSE, idx), digits );
                lineBuffer += (jdx < emaCount-1 ? SEPARATOR : "");
            }
        }
        if( ON_MACD ) {
            if( ON_TIME || ON_MARKET || ON_EMA ) { lineBuffer += SEPARATOR; }
            lineBuffer += StringConcatenate(DoubleToStr( iMACD(symbol, period, macdLevels[0], macdLevels[1], macdLevels[2], PRICE_CLOSE, MODE_MAIN, idx), digits+2 ), SEPARATOR,
                                            DoubleToStr( iMACDHist(symbol, period, macdLevels[0], macdLevels[1], macdLevels[2], PRICE_CLOSE, MODE_EMA, idx), digits+2 ) );
        }
        if( ON_ATR ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD ) { lineBuffer += SEPARATOR; }
            lineBuffer += DoubleToStr( iATR(symbol, period, ATR_PERIOD, idx), digits+1 );
        }
        if( ON_CCI ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR ) { lineBuffer += SEPARATOR; }
            lineBuffer += DoubleToStr( iCCI(symbol, period, CCI_PERIOD, PRICE_TYPICAL, idx), digits+1 );
        }
        if( ON_RSI ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR || ON_CCI ) { lineBuffer += SEPARATOR; }
            lineBuffer += DoubleToStr( iRSI(symbol, period, RSI_PERIOD, PRICE_CLOSE, idx), digits+1 );
        }
        if( ON_USDX ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR || ON_CCI || ON_RSI ) { lineBuffer += SEPARATOR; }
            lineBuffer += DoubleToStr(iDollarIndex(idx, period), digits+1);
        }
        if( ON_EURX ) {
            if( ON_TIME || ON_MARKET || ON_EMA || ON_MACD || ON_ATR || ON_CCI || ON_RSI || ON_USDX ) { lineBuffer += SEPARATOR; }
            lineBuffer += DoubleToStr(iEuroIndex(idx, period), digits+1);
        }
        if( ON_TOGETHER_DATASET ) {
            lineBuffer += SEPARATOR;
            lineBuffer += DoubleToStr(SignalP_Buffer[idx-yShift]+SignalN_Buffer[idx-yShift], 2);
        }
        FileWrite(handleX, lineBuffer);
    }
    FileClose(handleX);
    if( ON_USDX || ON_EURX ) {
        Print("When you include dollar and/or euro indexes in the dataset, "
                "you should download the history with their cross-rates "
                "with the following currencies: GBP, JPY, CAD, CHF, SEK.");
    }
    if( fileY == "" || ON_TOGETHER_DATASET ) {
        return;
    }
    // Target data file
    int handleY = FileOpen(fileY, FILE_WRITE | FILE_CSV | FILE_SHARE_WRITE, StringGetChar(SEPARATOR, 0));
    if( ON_HEADERS ) {
        lineBuffer = GetIndicatorString(INDICATOR);
        FileWrite(handleY, lineBuffer);
    }
    for( int idx = begin-yShift; idx >= end; idx-- ) {
        lineBuffer = "";
        lineBuffer += DoubleToStr(SignalP_Buffer[idx]+SignalN_Buffer[idx], 2);
        // for( int jdx = 0; jdx <= yShift; jdx++ ) {
        //     lineBuffer += DoubleToStr(SignalP_Buffer[idx-jdx]+SignalN_Buffer[idx-jdx], digits+1);
        //     lineBuffer += (jdx != 0 ? SEPARATOR : "");
        // }
        FileWrite(handleY, lineBuffer);
    }
    FileClose(handleY);
};


//+---------------------------------------------------------------------------+
//|   S I G N A L   F U N C T I O N S                                         |
//+---------------------------------------------------------------------------+
double iCustomSignal(const int bar,
                     const string symbol = NULL, const int period = PERIOD_CURRENT,
                     const string path = "", const bool writable = true)
{
    static bool readed = false;
    if( !readed ) {         // read custom signals file
        if( ReadCustomSignal(SignalP_Buffer, SignalN_Buffer, path) < 0 ) {
            return 0.0;
        }
        readed = true;
    }
    return SignalP_Buffer[bar] + SignalN_Buffer[bar];
};


//+---------------------------------------------------------------------------+
//|   O T H E R   F U N C T I O N S                                           |
//+---------------------------------------------------------------------------+
bool InitCheck()
{
    // Check parameters
    if( EMA_D1 <= 1 ) {
        Print("Error: Wrong MA period.");
        return true;
    }
    if( MACD_FAST <= 1 || MACD_SLOW <= 1 || MACD_SIGNAL <= 1 || MACD_FAST >= MACD_SLOW ) {
        Print("Error: Wrong MACD periods.");
        return true;
    }
    if( ATR_PERIOD <= 1 || CCI_PERIOD <= 1 || RSI_PERIOD <= 1 )  {
        Print("Error: Wrong indicators periods.");
        return true;
    }
    return false;
};

