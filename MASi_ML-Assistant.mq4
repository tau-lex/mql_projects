//+---------------------------------------------------------------------------+
//|                                                     MASi_ML-Assistant.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017-2018, Terentyev Aleksey"
// #property link          "https://www.mql5.com/ru/users/terentyev23"
#property link          "https://goo.gl/mkLRyq"
#property description   "The script helps to prepare data for machine learning, runs ML script with parameters, draw prediction."
#property description   "How to use the utility (RUS): https://goo.gl/mkLRyq"
#property description   "---"
#property description   "The standard values for the signals:"
#property description   "BouncedMA FilterM \t= 5 (Period (Filter))"
#property description   "BouncedMA FilterP \t= 3 (Period (Filter))"
#property description   "Sampler \t\t= 10 (Period)"
#property description   "Impulse \t\t\t= 13 or 26 (EMA), 12, 26, 9 (MACD)"
#property description   "Wave \t\t\t= 34 (EMA)"
#property version       "1.22.1"
#property icon          "ico/ml-assistant.ico";
#property strict

#include                "MASh_Include.mqh"
#include                "MASh_Indicators.mqh"
#include                "MASh_UI-Class.mqh"
#include                "MASh_IO.mqh"


//+---------------------------------------------------------------------------+
//|   D E F I N E S                                                           |
//+---------------------------------------------------------------------------+
enum STOREDDATATYPE {
    Apart = 0,
    Together = 1
};

//+---------------------------------------------------------------------------+
//|   I M P O R T                                                             |
//+---------------------------------------------------------------------------+
#import "shell32.dll"
int ShellExecuteW(int hwnd,string lpOperation,string lpFile,string lpParameters,string lpDirectory,int nShowCmd);
#import
//---- константы открытия\показа (nShowCmd)
#define SW_HIDE             0
#define SW_SHOWNORMAL       1
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2
#define SW_SHOWMAXIMIZED    3
#define SW_MAXIMIZE         3
#define SW_SHOWNOACTIVATE   4
#define SW_SHOW             5
#define SW_MINIMIZE         6
#define SW_SHOWMINNOACTIVE  7
#define SW_SHOWNA           8
#define SW_RESTORE          9
#define SW_SHOWDEFAULT      10
#define SW_FORCEMINIMIZE    11
#define SW_MAX              11


//+---------------------------------------------------------------------------+
//|   I N D I C A T O R S                                                     |
//+---------------------------------------------------------------------------+
#property indicator_separate_window
//#property indicator_height  50
#property indicator_minimum -1
#property indicator_maximum 1
#property indicator_buffers 4
#property indicator_plots   4
//--- plot
#property indicator_label1  "Signal Buy"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrDarkGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
#property indicator_label2  "Signal Sell"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrMaroon
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3
#property indicator_label3  "Predict Buy"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrLimeGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "Predict Sell"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrFireBrick
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//--- indicator buffers
double      SignalP_Buffer[], SignalN_Buffer[];
double      PredictP_Buffer[], PredictN_Buffer[];


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
extern BOOL             ON_RECORD = Disable;                // Editing signals

input string            SECTION4 = "___ M L   O P T I O N S ___";//.
extern BOOL             ON_MLAUTORUN = Disable;             // Autorun script machine learning
input string            PATH_PROGRAM = "";                  // Path to the program ('/' or \\')
input string            PATH_SCRIPT = "";                   // Path to the script ('/' or '\\')
input string            ML_PARAM_TRAIN = "";                // Startup parameters for training
input string            ML_PARAM_PREDICTION = "";           // Startup parameters for prediction
input int               ML_PRELAUNCH_TIME = 60;             // Time to start training before the new bar
input int               ML_PERIODRETRAINING = 5;            // Period of retraining (bars)
input int               ML_DEPTH = 0;                       // Depth of prediction (From bar to bar+N)
input int               ML_SIZE = 100;                      // Size history for prediction (data_xx)

input string            SECTION6 = "___ S Y S T E M ___";   //.
extern BOOL             ON_UI = Enable;                     // User Interface
input int               WINDOW_X = 20;                      // X of Left corner of window
input int               WINDOW_Y = 30;                      // Y of Left corner of window
input string            DIRECTORY = "ML-Assistant";         // Path to all files ($MT4$/MQL4/Files/.../)
input BOOL              ON_HEADERS = Disable;               // Headers for data
input STOREDDATATYPE    ON_TOGETHER_DATASET = Apart;        // File type for Features + Target data
input string            SEPARATOR = ";";                    // Csv file separator
input string            PREFIX = "";                        // Prefix (PrefixSYMBOLPERIOD_x.csv)
input string            POSTFIX = "";                       // Postfix (SYMBOLPERIODPostfix_x.csv)
input double            PREDICT_FACTOR = 1.0;               // Predict data multiplier
extern double           INDICATOR_GAIN = 1.0;               // Minimum signal threshold [0.0 - 1.0]

//--- simple global variables
const int               WINDOW_WIDTH = 190;         // 
string                  indicatorName, glVarPredictSize, glVarPredictDepth, glVarAssistant;
CWindow*                ui;
bool                    newBarFlag = false;
int                     barsCount = 0;
datetime                timeOffset;
string                  trainX, trainY;
string                  predictX, predictY;
string                  emaLevelsS[], macdLevelsS[];
int                     emaCount, emaLevels[], macdLevels[3];


//+---------------------------------------------------------------------------+
//|   M A I N   F U N C T I O N S                                             |
//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer(0, SignalP_Buffer);
    SetIndexBuffer(1, SignalN_Buffer);
    SetIndexBuffer(2, PredictP_Buffer);   SetIndexShift(2, ML_DEPTH);
    SetIndexBuffer(3, PredictN_Buffer);   SetIndexShift(3, ML_DEPTH);
    if( InitCheck() ) {
        return INIT_FAILED;
    }
    // Global variables
    indicatorName = StringConcatenate( "ML-Assistant ( ", GetIndicatorString(INDICATOR), " )" );
    IndicatorShortName(indicatorName);
    glVarPredictSize = StringConcatenate("MASv_", Symbol(), Period(), "_PredictSize");
    GlobalVariableSet(glVarPredictSize, ML_SIZE);
    glVarPredictDepth = StringConcatenate("MASv_", Symbol(), Period(), "_PredictDepth");
    GlobalVariableSet(glVarPredictDepth, ML_DEPTH);
    glVarAssistant = StringConcatenate("MASv_", Symbol(), Period(), "_Assistant");
    GlobalVariableSet(glVarAssistant, 1.0);
    // Init UI
    if( ON_UI ) {
        ui = new CWindow(WINDOW_X, WINDOW_Y, WINDOW_WIDTH, 20, "ML-Assistant");
        string items[];
        ArrayResize(items, 5);
        items[0] = "Button{Train}";
        items[1] = "Button{Predict}";
        items[2] = "Button{Read Predict}";
        items[3] = StringConcatenate("ChkBtn{Autorun:", ON_MLAUTORUN?"true":"false", "}");
        items[4] = "Button{Save Custom}";
        if( INDICATOR == Custom ) {
            ArrayResize(items, 6);
            items[5] = StringConcatenate("ChkBtn{Signal Rec.:", ON_RECORD?"true":"false", "}");
        }
        // items[3] = "checkbutton{On change:Off}";
        // items[4] = "list{enum:Indicator}";
        ui.SetItems(items);
        ui.Draw();
    }
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
    predictY = StringConcatenate(DIRECTORY, "/", PREFIX, Symbol(), Period(), POSTFIX, "_yy.csv");
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
        newBarFlag = true;
        barsCount++;
        if( ON_MLAUTORUN ) {    // Run ML predict script
            RunScript(ML_PARAM_PREDICTION);
        }
    }
    if( ON_MLAUTORUN ) {        // Run ML train script
        if( barsCount % ML_PERIODRETRAINING == 0 ) {
            if( BarTimeLeft() < ML_PRELAUNCH_TIME ) {
                RunScript(ML_PARAM_TRAIN);
                barsCount++;
            }
        }
    }
    if( newBarFlag ) {          // Read Prediction data
        datetime now = (datetime)FileGetInteger(predictY, FILE_MODIFY_DATE) - timeOffset;
        if( time[0] <= now ) {
            ReadPredictionFile(predictY, ML_SIZE, PredictP_Buffer, PredictN_Buffer,
                               PREDICT_FACTOR, SEPARATOR);
            newBarFlag = false;
        }
    }
    ui.Update();
    return rates_total;
}

void OnChartEvent(const int id, const long& lparam,
                  const double& dparam, const string& sparam)
{
    if( INDICATOR == Custom && ON_RECORD ) {
        if( id == CHARTEVENT_CLICK ) {
            int winIdx;
            datetime time;
            double price;
            if( ChartXYToTimePrice(0, (int)lparam, (int)dparam, winIdx, time, price) ) {
                if( winIdx > 0 && winIdx == WindowFind(indicatorName) ) {
                    int idx = IndexOfBar(time);
                    SignalP_Buffer[idx] = 0.0;
                    SignalN_Buffer[idx] = 0.0;
                    if( price > 0 ) {
                        SignalP_Buffer[idx] = price;
                    } else {
                        SignalN_Buffer[idx] = price;
                    }
                }
            } else {
                Print( "Convert error: " + IntegerToString(GetLastError()) );
            }
        }
    }
    if( id == CHARTEVENT_CHART_CHANGE ) {
        ResizeBar();
        ChartRedraw();
    }
    if( ON_UI ) {
        ParseUiResult(id, lparam, dparam, sparam, ui);
    }
}

void OnDeinit(const int reason)
{
    GlobalVariableDel(glVarPredictSize);
    GlobalVariableDel(glVarPredictDepth);
    GlobalVariableDel(glVarAssistant);
    if( ON_UI ) {
        delete ui;
    }
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

void RunScript(const string otherParams = "")
{
    if( IsDllsAllowed() ) {
        string params = StringConcatenate(PATH_SCRIPT, " ", PREFIX, Symbol(), Period(), POSTFIX, " ", otherParams);
        int res = ShellExecuteW(NULL, NULL, PATH_PROGRAM, params, NULL, SW_SHOWNORMAL);
        if( res == 2 ) {
            Print("Error! File not found. " + PATH_SCRIPT);
        }
        Print( "Run script: \"" + (string)params + (res == 42 ? "\" Done" : (string)res) ); 
    } else {
        Print("For autorun script, allow the use of DLL.");
    }
};


//+---------------------------------------------------------------------------+
//|   S I G N A L   F U N C T I O N S                                         |
//+---------------------------------------------------------------------------+
double iCustomSignal(const int bar,
                     const string symbol = NULL, const int period = PERIOD_CURRENT,
                     const string path = "", const bool writable = true)
{
    static bool readed = false;
    // static double _buffer[]; // GOTO: rework, add buffer
    if( !readed ) {         // read custom signals file
        // ArrayResize(_buffer, Bars);
        // ArraySetAsSeries(_buffer, true);
        if( ReadCustomSignal(SignalP_Buffer, SignalN_Buffer, path) < 0 ) {
            return 0.0;
        }
        readed = true;
    }
    static int callCount = 0;
    if( ON_RECORD ) {       // write custom signals
        if( readed ) {
            if( bar == 0 && (callCount % 50) == 0 ) {
                SaveCustomSignal(SignalP_Buffer, SignalN_Buffer, path);
            }
        }
    }
    callCount++;
    return SignalP_Buffer[bar] + SignalN_Buffer[bar];
};


//+---------------------------------------------------------------------------+
//|   U I   F U N C T I O N S                                                 |
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
    SetIndexStyle(0, DRAW_HISTOGRAM, EMPTY, size);
    SetIndexStyle(1, DRAW_HISTOGRAM, EMPTY, size);
    // SetIndexStyle(2, DRAW_HISTOGRAM, EMPTY, size-1);
    // SetIndexStyle(3, DRAW_HISTOGRAM, EMPTY, size-1);
    tmpScale = scale; tmpType = typeBar;
};

void ParseUiResult(const int id, const long& lparam,
                   const double& dparam, const string& sparam,
                   CWindow &uiobj)
{
    int parameters[];
    int numParams = uiobj.OnEvent(id, lparam, dparam, sparam, parameters);
    if( numParams <= 0 ) {
        return;
    }
    if( parameters[0] ) {   // btn Minimize
        ui.Minimize();
    }
    if( parameters[1] ) {   // btn Close
        ON_UI = Disable;
        delete ui;
        Print("User interface disabled.");
    }
    if( parameters[2] ) {   // btn Train
        RunScript(ML_PARAM_TRAIN);
    }
    if( parameters[3] ) {   // btn Predict
        RunScript(ML_PARAM_PREDICTION);
    }
    if( parameters[4] ) {   // btn Read
        ReadPredictionFile(predictY, ML_SIZE, PredictP_Buffer, PredictN_Buffer,
                            PREDICT_FACTOR, SEPARATOR);
    }
    // chkbtn Autorun
    ON_MLAUTORUN = parameters[5] ? Enable : Disable;
    if( parameters[6] ) {   // btn Save Custom
        SaveCustomSignal(SignalP_Buffer, SignalN_Buffer, DIRECTORY);
    }
    // Custom section
    if( INDICATOR == Custom ) {
        // chkbtn Signal Rec.
        ON_RECORD = parameters[7] ? Enable : Disable;
    }
};


//+---------------------------------------------------------------------------+
//|   O T H E R   F U N C T I O N S                                           |
//+---------------------------------------------------------------------------+
bool InitCheck()
{
    timeOffset = (datetime)GetOffsetFromServerTimeZone();
    // Normalize indicator gain
    if( INDICATOR_GAIN < 0.0 ) {
        INDICATOR_GAIN = 0.0;
    } else if( INDICATOR_GAIN > 1.0 ) {
        INDICATOR_GAIN = 1.0;
    }
    // Check dll
    if( ON_MLAUTORUN ) {
        if( !IsDllsAllowed() ) {
            Print("To run the script, enable the use of the DLL.");
        // } else {
        //     RunScript(ML_PARAM_TRAIN);
        }
    }
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

