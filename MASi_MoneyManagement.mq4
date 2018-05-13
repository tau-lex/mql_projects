//+---------------------------------------------------------------------------+
//|                                                  MASi_MoneyManagement.mq4 |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property description   "Indicator for a money management."
#property version       "1.5"
#property strict

#include                "MASh_Include.mqh"
#include                "MASh_Indicators.mqh"
#include                "MASh_Market.mqh"


//+---------------------------------------------------------------------------+
//|   I N D I C A T O R S                                                     |
//+---------------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4
//--- plot Protect Lines
#property indicator_label1  "Protect Buy"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrSaddleBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Protect Sell"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSaddleBrown
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Profit Lines
#property indicator_label3  "Profit Buy"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkOliveGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_label4  "Profit Sell"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDarkOliveGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- indicator buffers
double      ProfitBuyBuffer[], ProfitSellBuffer[];
double      ProtectBuyBuffer[], ProtectSellBuffer[];


//+---------------------------------------------------------------------------+
//|   G L O B A L   V A R I A B L E S                                         |
//+---------------------------------------------------------------------------+
//---
//input int               STYLE = 1;              // Style Risk info
input BOOL      ON_COMMENT = Enable;    // Risk info
input int       RISK = 2;               // Risk per order
input int       RISK_MN = 6;            // Risk per month
input BOOL      BUY_INFO = Disable;     // Buy order information
input BOOL      SELL_INFO = Disable;    // Sell order information
input BOOL      ON_PROFIT = Enable;     // Profit level (takeprofit)
input int       CHANNEL_PC = 140;       // Size of channel in percent
input BOOL      ON_PROTECT = Enable;    // Protect level (stoploss)
input double    MFACTOR = 3;            // Average breakout factor
//---

string          first, second, prefix;
string          currency;
double          leverage;
SYMBOL_TYPE     symbolType;
double          balance, freeMargin, balanceMonth;

double          lotMin, lotMax, lotStep;
double          lotSize, lotSecondBuy, lotSecondSell, lotCurrency, lotCurrencyStd;

double          priceBuy, priceSell;
double          tpPriceBuy, slPriceBuy, tpPriceSell, slPriceSell;

double          riskBalance;
double          riskLotBuy, riskLotSell;
double          orderLotBuy, orderLotSell;


//+---------------------------------------------------------------------------+
//|   M A I N   F U N C T I O N S                                             |
//+---------------------------------------------------------------------------+
int OnInit()
{
    SetIndexBuffer( 0, ProtectBuyBuffer );
    SetIndexBuffer( 1, ProtectSellBuffer );
    SetIndexBuffer( 2, ProfitBuyBuffer );
    SetIndexBuffer( 3, ProfitSellBuffer );
    if( !ON_COMMENT && !ON_PROTECT && !ON_PROFIT ) {
        Print( "All parameters disabled." );
        return INIT_PARAMETERS_INCORRECT;
    }
    symbolType = MarketInfo(Symbol(), MODE_PROFITCALCMODE) == 0 ? FOREX : CFD;
    Print( Period() ); // optimize + return rates_total
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
    if( prev_calculated > 0 )
        limit++;
    if( limit >= iBars(Symbol(), Period()) - 10 )
        limit -= 10;
    if( ON_PROFIT )
        for( int idx = limit; idx >= 0; idx-- ) {
            if( BUY_INFO ) {
                ProfitBuyBuffer[idx] = iKeltnerChannel( idx, Symbol(), Period(), 26, Higher, Modified_2, CHANNEL_PC );
            }
            if( SELL_INFO ) {
                ProfitSellBuffer[idx] = iKeltnerChannel( idx, Symbol(), Period(), 26, Lower, Modified_2, CHANNEL_PC );
            }
        }
    if( ON_PROTECT )
        for( int idx = limit; idx >= 0; idx-- ) {
            if( BUY_INFO ) {
                ProtectBuyBuffer[idx] = StopBuyMax( idx, Symbol(), Period(), MFACTOR );
            }
            if( SELL_INFO ) {
                ProtectSellBuffer[idx] = StopSellMin( idx, Symbol(), Period(), MFACTOR );
            }
        }
    if( ON_COMMENT ) {
        Calculate();
        Comment( GetCommentLine() );
    }
    return rates_total;
}

void OnDeinit(const int reason)
{
    Comment( "" );
};


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
void Calculate()
{
    if( symbolType == FOREX ) {
        first       = StringSubstr( Symbol(), 0, 3 );       // первый символ,   например EUR
        second      = StringSubstr( Symbol(), 3, 3 );       // второй символ,   например USD
        prefix      = StringSubstr( Symbol(), 6 );          // префикс брокера
    } else if( symbolType == CFD ) {
        first       = "";
        second      = "";
        prefix      = "";
    }
    currency        = AccountCurrency();                    // валюта депозита, например USD
    leverage        = AccountLeverage();                    // кредитное плечо, например 100
    
    balance         = AccountBalance();                     // Баланс
    freeMargin      = AccountFreeMargin();                  // Свободныя маржа 
    balanceMonth    = GetBalanceFirstNum();                 // Баланс на начало месяца
    
    lotMin          = MarketInfo( Symbol(), MODE_MINLOT );
    lotMax          = MarketInfo( Symbol(), MODE_MAXLOT );
    lotStep         = MarketInfo( Symbol(), MODE_LOTSTEP );
    
    priceBuy        = MarketInfo( Symbol(), MODE_ASK );     // Котировка на покупку
    priceSell       = MarketInfo( Symbol(), MODE_BID );     // Котировка на продажу
    lotSize         = MarketInfo( Symbol(), MODE_LOTSIZE ); // Стоимость лота в базовой валюте
    lotSecondBuy    = lotSize * priceBuy;                   // Стоимость покупки лота в валюте котировки
    lotSecondSell   = lotSize * priceSell;                  // Стоимость продажи лота в валюте котировки
    lotCurrency     = MarketInfo( Symbol(), MODE_MARGINREQUIRED ); // Стоимость лота в валюте депозита
    
    tpPriceBuy      = iKeltnerChannel( 0, Symbol(), Period(), 26, Higher, Modified_2, CHANNEL_PC );
    slPriceBuy      = StopBuyMax( 1, Symbol(), Period(), MFACTOR );
    tpPriceSell     = iKeltnerChannel( 0, Symbol(), Period(), 26, Lower, Modified_2, CHANNEL_PC );
    slPriceSell     = StopSellMin( 1, Symbol(), Period(), MFACTOR );
    
    // Размер риска относительно баланса
    riskBalance     = balance * 0.01 * RISK;
    // Размер риска относительно покупки/продажи 1 лота 
    riskLotBuy      = GetRiskBuyLot(priceBuy, slPriceBuy);
    riskLotSell     = GetRiskBuyLot(priceSell, slPriceSell);
    // Размер лота при открытии ордера на покупку/продажу
    orderLotBuy     = GetLotSize(riskLotBuy, riskBalance);
    orderLotSell    = GetLotSize(riskLotSell, riskBalance);
};

string GetCommentLine()
{
    string line1, line2, line3;
    line1 = StringConcatenate(
        "BALANCE"
        "\n        Balance = ",             balance, " ", currency,
        "\n        Free Margin = ",         freeMargin, " ", currency,
        "\n        Start Month Balance = ", balanceMonth, " ", currency,
        "\n        Leverage = ",            leverage,
        "\n"
        "ИНСТРУМЕНТ"
        "        ( Type = ",                symbolType == FOREX ? "Forex )" : "CFD )",
        "\n        Lot = ",                 lotSize, " ", first,
        "\n        Ask / Bid (Buy/Sell) = ",priceBuy, " / ", priceSell, " ", second,
        "\n        Lot price (Buy/Sell) = ",lotSecondBuy, " / ", lotSecondSell, " ", second,
        "\n        Margin Lot (buy) = ",    lotCurrency, " ", currency,
        "\n        Min/Step/Max Lot = ",    lotMin, " / ", lotStep, " / ", lotMax
        //"\n    Маржа = ",                 MarketInfo(Symbol(), MODE_MARGININIT), " / ", 
        //                                  MarketInfo(Symbol(), MODE_MARGINMAINTENANCE), " / ", 
        //                                  MarketInfo(Symbol(), MODE_MARGINHEDGED),
    );
    if( BUY_INFO ) {
        line2 += StringConcatenate(
            "\n"
            "BUY ORDER"
            "\n        Take Profit = ",     NormalizeDouble( tpPriceBuy, Digits() ),
            "\n        Stop Loss = ",       NormalizeDouble( slPriceBuy, Digits() ),
            "\n        Profit / Loss = ",   NormalizeDouble( tpPriceBuy - priceBuy, Digits() ), "/",
                                            NormalizeDouble( priceBuy - slPriceBuy, Digits() )
        );
    }
    if( SELL_INFO ) {
        line2 += StringConcatenate(
            "\n"
            "SELL ORDER"
            "\n        Take Profit = ",     NormalizeDouble( tpPriceSell, Digits() ),
            "\n        Stop Loss = ",       NormalizeDouble( slPriceSell, Digits() ),
            "\n        Profit / Loss = ",   NormalizeDouble( priceSell - tpPriceSell, Digits() ), "/",
                                            NormalizeDouble( slPriceSell - priceSell, Digits() )
        );
    }
    line3 = StringConcatenate(
        "\n"
        "RISK"
        "\n        Risk Size = ",           RISK, " %"
        "\n        Max Balace Risk = ",     riskBalance, " ", currency,
        "\n        Max Risk per Lot (Buy/Sell) = ", riskLotBuy, " / ", riskLotSell, " ", currency,
        "\n        Order Volume (Buy/Sell) = ",     orderLotBuy, " / ", orderLotSell
    );
    return line1 + line3 + line2;
};

