//+---------------------------------------------------------------------------+
//|                                                       MASs_WebRequest.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "The script helps to..."
#property version       "1.0"
// #property icon          "ico/ml-assistant.ico";
#property strict

#import "wininet.dll"
    int InternetAttemptConnect(int x);
    int InternetOpenW(string sAgent, int lAccessType, string sProxyName="", string sProxyBypass="", int lFlags=0);
    int InternetOpenUrlW(int webHandle, string sUrl, string sHeaders="", int lHeadersLength=0, int lFlags=0, int lContext=0);
    int InternetReadFile(int hFile, int &sBuffer[], int lNumBytesToRead, int &lNumberOfBytesRead[]);
    int InternetCloseHandle(int hInet);
#import

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1


//+----------------Global variables-------------------------------------------+
//---
// Pricing 1
const string URL_STRING = "https://widget.sentryd.com/widget/sentry/api/Pricing";
// Pricing 2
//const string URL_STRING = "curl \"https://widget.sentryd.com/widget/sentry/api/Pricing\" --2.0 -H \"Host: widget.sentryd.com\" -H \"User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0\" -H \"Accept: */*\" -H \"Accept-Language: ru\" --compressed -H \"Content-Type: application/x-www-form-urlencoded\" -H \"Authorization: Basic Y3VycmVuY3lfd2lkZ2V0OmN1cnJlbmN5X3dpZGdldA==\" -H \"Referer: https://widget.sentryd.com/widget/\" -H \"Cookie: __cfduid=d6079c52973994ce4b0600612fdae68311498587258; _ga=GA1.3.747599166.1498587260; __atuvc=2\"%\"7C26; _gid=GA1.3.532466592.1503514309; _hjIncludedInSample=1\" -H \"DNT: 1\" -H \"Connection: keep-alive\" --data \"Type=SelectedProducts&UID=46EF224A-BF58-B1EB-7D15-5EDC7E48E540&POSTAccessCode=sentryPricingApi&POSTAccessPassword=sentrypricingapi_235\"";
// Pricing 3
//const string URL_STRING = "curl \"https://widget.sentryd.com/widget/sentry/api/Pricing\" --2.0 -H \"Host: widget.sentryd.com\" -H \"User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0\" -H \"Accept: */*\" -H \"Accept-Language: ru\" --compressed -H \"Content-Type: application/x-www-form-urlencoded\" -H \"Authorization: Basic Y3VycmVuY3lfd2lkZ2V0OmN1cnJlbmN5X3dpZGdldA==\" -H \"Referer: https://widget.sentryd.com/widget/\" -H \"Cookie: __cfduid=d6079c52973994ce4b0600612fdae68311498587258; _ga=GA1.3.747599166.1498587260; __atuvc=2\"%\"7C26; _gid=GA1.3.532466592.1503514309; _hjIncludedInSample=1\" -H \"DNT: 1\" -H \"Connection: keep-alive\" --data \"Type=SelectedProducts&UID=46EF224A-BF58-B1EB-7D15-5EDC7E48E540&POSTAccessCode=sentryPricingApi&POSTAccessPassword=sentrypricingapi_235\"";
// Pricing 4
//const string URL_STRING = "curl \"https://widget.sentryd.com/widget/sentry/api/Pricing\" --2.0 -H \"Host: widget.sentryd.com\" -H \"User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0\" -H \"Accept: */*\" -H \"Accept-Language: ru\" --compressed -H \"Content-Type: application/x-www-form-urlencoded\" -H \"Authorization: Basic Y3VycmVuY3lfd2lkZ2V0OmN1cnJlbmN5X3dpZGdldA==\" -H \"Referer: https://widget.sentryd.com/widget/\" -H \"Cookie: __cfduid=d6079c52973994ce4b0600612fdae68311498587258; _ga=GA1.3.747599166.1498587260; __atuvc=2\"%\"7C26; _gid=GA1.3.532466592.1503514309; _hjIncludedInSample=1\" -H \"DNT: 1\" -H \"Connection: keep-alive\" --data \"Type=SelectedProducts&UID=46EF224A-BF58-B1EB-7D15-5EDC7E48E540&POSTAccessCode=sentryPricingApi&POSTAccessPassword=sentrypricingapi_235\"";

int OnInit()
{
    if( !IsDllsAllowed() ) {
        Print("Отметьте галочку разрешить DLL");
        return INIT_FAILED;
    }
    string ansverStr = GetWebRequest( StringConcatenate(URL_STRING, IntegerToString(TimeCurrent()*1000)) );
    if( ansverStr != "" ) {
        int handle = FileOpen("WebRequest.txt", FILE_TXT | FILE_WRITE);
        if( handle > 0 ) {
            FileWrite( handle, ansverStr );
            FileClose( handle );
            Print( "Файл записан: .../files/WebRequest.txt" );
        } 
    }
    return INIT_FAILED;
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
    ExpertRemove();
    return rates_total;
}

string GetWebRequest(string url)
{
    if( !IsDllsAllowed() ) {
        Print( "Необходимо в настройках разрешить использование DLL" );
        return "";
    }
    int rv = InternetAttemptConnect(0);
    if( rv != 0 ) {
        Print( "Ошибка при вызове InternetAttemptConnect()" );
        return "";
    }
    int webHandle = InternetOpenW("Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:57.0) Gecko/20100101 Firefox/57.0", 0, "", "", 0);
    if( webHandle <= 0 ) {
        Print("Ошибка при вызове InternetOpenW()");
        return "";
    }
    int urlHandle = InternetOpenUrlW( webHandle, url, "", 0, 0, 0 );
    if( urlHandle <= 0 ) {
        Print( "Ошибка при вызове InternetOpenUrlW()" );
        InternetCloseHandle( webHandle );
        return "";
    }      
    int cBuffer[256];
    int dwBytesRead[1]; 
    string result = "";
    while( !IsStopped() ) {
        bool bResult = InternetReadFile( urlHandle, cBuffer, 1024, dwBytesRead );
        if( dwBytesRead[0] == 0 ) {
            break;
        }
        string text = "";   
        string text0 = "";   
        for( int idx = 0; idx < 256; idx++ ) {
            text0 = CharToStr( (char)(cBuffer[idx] & 0x000000FF) );
            if (text0!="\r") {
                text = text + text0;
            } else {
                dwBytesRead[0]--;
            }
            if( StringLen(text) == dwBytesRead[0] ) {
                break;
            }
            text0 = CharToStr( (char)(cBuffer[idx] >> (8 & 0x000000FF)) );
            if( text0 != "\r" ) {
                text += text0;
            } else {
                dwBytesRead[0]--;
            }
            if( StringLen(text) == dwBytesRead[0] ) {
                break;
            }
            text0 = CharToStr( (char)(cBuffer[idx] >> (16 & 0x000000FF)) );
            if( text0 != "\r" ) {
                text += text0;
            } else {
                dwBytesRead[0]--;
            }
            if( StringLen(text) == dwBytesRead[0] ) {
                break;
            }
            text0 = CharToStr( (char)(cBuffer[idx] >> (24 & 0x000000FF)) );
            if( text0 != "\r" ) {
                text += text0;
            } else {
                dwBytesRead[0]--;
            }
            if( StringLen(text) == dwBytesRead[0] ) {
                break;
            }
        }
        result += text;
        Sleep(1);
    }
    InternetCloseHandle( webHandle );
    return result;
} 
