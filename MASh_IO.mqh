//+---------------------------------------------------------------------------+
//|                                                               MASh_IO.mqh |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017-2018, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property strict


//+---------------------------------------------------------------------------+
//|   S I G N A L   F U N C T I O N S                                         |
//+---------------------------------------------------------------------------+
void SaveCustomSignal(const double &positive[], const double &negative[], string path = "")
{
    if( StringLen(path) > 0 ) { path += "/"; }
    string fileName = StringConcatenate(path, Symbol(), Period(), "_custom.csv");
    int handle = FileOpen(fileName, FILE_WRITE | FILE_CSV | FILE_SHARE_WRITE, StringGetChar(";", 0));
    for( int idx = ArraySize(positive) - 1; idx >= 0; idx-- ) {
        FileWrite(handle, TimeToStr(iTime(Symbol(), Period(), idx)), DoubleToStr(positive[idx] + negative[idx], 2));
    }
    FileClose(handle);
};

int ReadCustomSignal(double &positive[], double &negative[], string path = "")
{
    double signal;
    string line;
    if( StringLen(path) > 0 ) { path += "/"; }
    string fileName = StringConcatenate(path, Symbol(), Period(), "_custom.csv");
    int idx = -1;
    int handle = FileOpen(fileName, FILE_READ | FILE_CSV | FILE_SHARE_READ, StringGetChar(";", 0));
    if( handle == INVALID_HANDLE ) {
        return -1;
    }
    while( !FileIsEnding(handle) ) {
        line = FileReadString(handle);
        if( idx < 0 ) {
            idx = IndexOfBar(StringToTime(line));
        }
        if( StringToTime(line) == iTime(Symbol(), Period(), idx) ) { // Normal read
            positive[idx] = 0.0;
            negative[idx] = 0.0;
            signal = StringToDouble(FileReadString(handle));
            if( signal > 0 ) {
                positive[idx] = signal;
            } else {
                negative[idx] = signal;
            }
            idx--;
        } else if( StringToTime(line) < iTime(Symbol(), Period(), idx) ) { // Skip skiped bar
            FileReadString(handle);
        } else if( StringToTime(line) > iTime(Symbol(), Period(), idx) ) { // Checking idx
            idx = IndexOfBar(StringToTime(line));
            line = TimeToStr(iTime(Symbol(), Period(), idx));
        }
    }
    FileClose(handle);
    return 0;
};

int ReadPredictionFile(const string filePath, const int fileLength,
                       double &positive[], double &negative[],
                       const double factor = 1.0, const string separator = ";")
{
    int handle = FileOpen(filePath, FILE_READ | FILE_CSV, StringGetChar(separator, 0));
    if( handle == INVALID_HANDLE ) {
        Print("Predict file was not opened: ", GetLastError());
        return -1;
    }
    double buffer[];
    int index = 0;
    ArrayResize(buffer, fileLength * 2);
    while( !FileIsEnding(handle) ) {
        buffer[index] = StringToDouble(FileReadString(handle)) * factor;
        index++;
        if( index >= (fileLength * 2) - 2 ) {
            ArrayResize(buffer, fileLength * 3);
        }
    }
    FileClose(handle);
    if( index != fileLength ) {
        Print("The length of the readed file = " + (string)index + ".");
    }
    index -= 1;
    for( int idx = index; idx >= 0; idx-- ) {
        positive[idx] = 0.0;
        negative[idx] = 0.0;
        if( buffer[index-idx] > 0 ) {
            positive[idx] = buffer[index-idx];
        } else if( buffer[index-idx] < 0 ) {
            negative[idx] = buffer[index-idx];
        }
    }
    return 0;
};


//+---------------------------------------------------------------------------+
//|   H I S T O R Y   F U N C T I O N S                                       |
//+---------------------------------------------------------------------------+
void ReadHistoryLine(const int handle,
                     string &b0, string &b1, string &b2, string &b3,
                     string &b4, string &b5, string &b6, string &b7,
                     string &b8, string &b9, string &b10, string &b11, string &b12)
{
    b0 = FileReadString(handle); b1 = FileReadString(handle); b2 = FileReadString(handle); b3 = FileReadString(handle);
    b4 = FileReadString(handle); b5 = FileReadString(handle); b6 = FileReadString(handle); b7 = FileReadString(handle);
    b8 = FileReadString(handle); b9 = FileReadString(handle); b10 = FileReadString(handle); b11 = FileReadString(handle);
    b12 = FileReadString(handle);
};

void ReadHistoryLine(const int handle,
                     datetime &openTime, int &orderType, double &volume, string &symbol,
                     double &openPrice, double &stopPrice, double &takePrice,
                     datetime &closeTime, double &closePrice, double &commission,
                     double &swap, double &profit, string &comment)
{
    string _orderType;
    // read
    openTime = FileReadDatetime(handle); _orderType = FileReadString(handle);
    volume = FileReadNumber(handle); symbol = FileReadString(handle);
    openPrice = FileReadNumber(handle); stopPrice = FileReadNumber(handle);
    takePrice = FileReadNumber(handle); closeTime = FileReadDatetime(handle);
    closePrice = FileReadNumber(handle); commission = FileReadNumber(handle);
    swap = FileReadNumber(handle); profit = FileReadNumber(handle);
    comment = FileReadString(handle);
    // type check
    if( _orderType == "Buy" ) {
        orderType = OP_BUY;
    } else if( _orderType == "Buy Limit" ) {
        orderType = OP_BUYLIMIT;
    } else if( _orderType == "Buy Stop" ) {
        orderType = OP_BUYSTOP;
    } else if( _orderType == "Sell" ) {
        orderType = OP_SELL;
    } else if( _orderType == "Sell Limit" ) {
        orderType = OP_SELLLIMIT;
    } else if( _orderType == "Sell Stop" ) {
        orderType = OP_SELLSTOP;
    }
};

uint WriteHistoryLine(const int handle,
                      string &b0, string &b1, string &b2, string &b3,
                      string &b4, string &b5, string &b6, string &b7,
                      string &b8, string &b9, string &b10, string &b11, string &b12)
{
    return FileWriteString(handle, StringConcatenate(b0, ";", b1, ";", b2, ";", b3, ";",
                                                     b4, ";", b5, ";", b6, ";", b7, ";",
                                                     b8, ";", b9, ";", b10, ";", b11, ";", b12, "\r\n") );
};

uint WriteHistoryLine(const int handle,
                      datetime &openTime, int &orderType, double &volume, string &symbol,
                      double &openPrice, double &stopPrice, double &takePrice,
                      datetime &closeTime, double &closePrice, double &commission,
                      double &swap, double &profit, string &comment)
{
    string _orderType;
    switch( orderType ) {
        case OP_BUY:        _orderType = "Buy";
        case OP_BUYLIMIT:   _orderType = "Buy Limit";
        case OP_BUYSTOP:    _orderType = "Buy Stop";
        case OP_SELL:       _orderType = "Sell";
        case OP_SELLLIMIT:  _orderType = "Sell Limit";
        case OP_SELLSTOP:   _orderType = "Sell Stop";
        default:            _orderType = "";
    }
    FileWriteString(handle, TimeToString(openTime)); FileWriteString(handle, ";");
    FileWriteString(handle, _orderType); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(volume, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, symbol); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(openPrice, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(stopPrice, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(takePrice, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, TimeToString(closeTime)); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(closePrice, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(commission, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(swap, _Digits+1)); FileWriteString(handle, ";");
    FileWriteString(handle, DoubleToString(profit, _Digits+1)); FileWriteString(handle, ";");
    return FileWriteString(handle, StringConcatenate(comment, "\r\n") );
};

