//+---------------------------------------------------------------------------+
//|                                                           MAS_Include.mqh |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property strict


//+---------------------------------------------------------------------------+
//|      D E F I N E S                                                        |
//+---------------------------------------------------------------------------+
enum BOOL {
    Disable = 0,
    Enable  = 1
};

enum OPTIMIZATION {
    Off     = 0,
    Simple  = 2,
    Medium  = 5,
    Hard    = 10
};

enum TIME_PERIODS {
    FIVE_MINUTES = 300,
    FIFTEEN_MINUTES = 900,
    THIRTY_MINUTES = 1800,
    ONE_HOUR = 3600,
    THREE_HOURS = 10800,
    ONE_DAY = 86400,
    TWO_DAYS = 172800,
    THREE_DAYS = 259200,
    FIVE_DAYS = 432000,
    ONE_WEEK = 604800,
    TEN_DAYS = 864000
};


//+---------------------------------------------------------------------------+
//|      F U N C T I O N S                                                    |
//+---------------------------------------------------------------------------+
//+
//+---------------------------------------------------------------------------+
//|      S Y S T E M                                                          |
//+---------------------------------------------------------------------------+
bool OptimizedRun(const int skipPeriod = 0)
{   // Возвращает True через skipPeriod вызовов
    static ulong TICK_COUNT = 0;
    if( skipPeriod <= 0 ) {
        return false;
    }
    if( TICK_COUNT % skipPeriod == 0 ) {
        TICK_COUNT++;
        return true;
    }
    TICK_COUNT++;
    return false;
};


//+---------------------------------------------------------------------------+
//|      S T R I N G                                                          |
//+---------------------------------------------------------------------------+
int StrSplit(const string string_value, const ushort separator, string &result[][64])
{
    if( StringLen(string_value) <= 0 || string_value == NULL )
        return 0;
    int lastChar = 0, currentChar = 0, size = StringLen(string_value), sizeRes = 0, sepIdxs[50];
    ArrayInitialize(sepIdxs, 0);
    for( int idx = 0; idx < size; idx++) {
        if( StringGetChar(string_value, idx) == separator ) {
            sepIdxs[sizeRes] = idx;
            sizeRes += 1;
            if( sizeRes >= ArraySize(sepIdxs) )
                ArrayResize(sepIdxs, ArraySize(sepIdxs)+50);
        }
    }
    ArrayResize(result, sizeRes+1);
    if( sizeRes == 0 ) {
        result[sizeRes][0] = string_value;
        return sizeRes + 1;
    }
    for( int idx = 0; idx <= sizeRes; idx++) {
        if( idx == 0 ) {
            result[idx][0] = StringSubstr(string_value, 0, sepIdxs[idx]);
            continue;
        }
        result[idx][0] = StringSubstr(string_value, sepIdxs[idx-1]+1, sepIdxs[idx]-sepIdxs[idx-1]-1);
    }
    return sizeRes + 1;
};

double StrToDbl(const string str)
{
    int k = 1;
    double r = 0, p = 1;
    for( int idx = 0; idx < StringLen(str); idx++ ) {
        if( k < 0 )
			p = p * 10;
        if( StringGetChar(str, idx) == '.' )
            k = -k;
        else
            r = r * 10 + (StringGetChar(str, idx) - '0');
    }
    return r / p;
};

string NormalizePath(const string path)
{
    string newPath = "";
    int idx = 0;
    while( idx < StringLen(path) ) {
        newPath = StringConcatenate(newPath, StringSubstr(path, idx, 1) );
        if( StringSubstr(path, idx, 1) == "\\" && StringSubstr(path, idx+1, 1) != "\\" ) {
            newPath = StringConcatenate(newPath, "\\");
        }
        idx++;
    }
    return newPath;
};


