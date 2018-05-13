//+---------------------------------------------------------------------------+
//|                                                       MASh_Indicators.mqh |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property strict


//+---------------------------------------------------------------------------+
//|   I N C L U D E S                                                         |
//+---------------------------------------------------------------------------+
#include                <MovingAverages.mqh>
#include                "MASh_IO.mqh"
#include                "MASh_Math.mqh"
#include                "MASh_Market.mqh"


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
enum INDICATOR_TYPE {
    None                = 0,
    Custom              = 10,
    BouncedMA           = 11,
    BouncedMA_FilterM   = 12,
    BouncedMA_FilterP   = 13,
    Sampler             = 18,
    Impulse             = 20,
    // AdaptiveMA          = 21,
    MACD_Histogram      = 22,
    Wave                = 23,
    // WaveCCI             = 24,
    // ThreeScreens_1_0    = 100,
    // ThreeScreens_1_1    = 110,
    ThreeScreens_1_2    = 120,
    // ThreeScreens_1_2_1  = 121,
    ThreeScreens_1_2_2  = 122,
    // ThreeScreens_1_3    = 130,
    ThreeScreens_2_0    = 200
};

enum TS_TYPE {
    ThreeScreens_v1_0   = 100,
    ThreeScreens_v1_1   = 110,
    ThreeScreens_v1_2   = 120,
    ThreeScreens_v1_2_1 = 121,
    ThreeScreens_v1_2_2 = 122,
    ThreeScreens_v1_3   = 130,
    ThreeScreens_v2_0   = 200
};

string GetIndicatorString(const int type)
{
    switch( type ) {
        case None:                  return "None";
        case Custom:                return "Custom";
        case BouncedMA:             return "BouncedMA (by Terentyev Aleksey, 2017-2018)";
        case BouncedMA_FilterM:     return "BouncedMA (by Terentyev Aleksey, 2017-2018)";
        case BouncedMA_FilterP:     return "BouncedMA (by Terentyev Aleksey, 2017-2018)";
        case Sampler:               return "Sampler (by her.human@gmail.com, 2012-2016)";
        case Impulse:               return "Impulse System (by Alexander Elder)";
        // case AdaptiveMA:            return "AdaptiveMA";
        case MACD_Histogram:        return "MACD Original Histogram";
        case Wave:                  return "Wave (by Raghee Horner, 2007)";
        // case WaveCCI:               return "Wave+CCI";
        // case ThreeScreens_1_0:      return "ThreeScreens v1.0";
        // case ThreeScreens_1_1:      return "ThreeScreens v1.1";
        case ThreeScreens_1_2:      return "ThreeScreens v1.2";
        // case ThreeScreens_1_2_1:    return "ThreeScreens v1.2.1 beta";
        case ThreeScreens_1_2_2:    return "ThreeScreens v1.2.2 beta";
        // case ThreeScreens_1_3:      return "ThreeScreens v1.3 beta";
        case ThreeScreens_2_0:      return "ThreeScreens v2.0 alpha";
        default:                    return NULL;
    }
};


//+---------------------------------------------------------------------------+
//|   S I G N A L S                                                           |
//+---------------------------------------------------------------------------+
double iImpulse(const int bar, 
                const string symbol = NULL, const int period = PERIOD_CURRENT,
                const int pEMA = 13, const int pMACD_F = 12, 
                const int pMACD_S = 26, const int pMACD_Sig = 9)
{   // Impulse indicator.  ©Alexander Elder
    double ema1, ema0, macd1, macd0;
    ema0 = iMA(symbol, period, pEMA, 0, MODE_EMA, PRICE_CLOSE, bar);
    ema1 = iMA(symbol, period, pEMA, 0, MODE_EMA, PRICE_CLOSE, bar+1);
    if( ema1 < ema0 ) {
        macd0 = iMACDHist(symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar);
        macd1 = iMACDHist(symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar+1);
        if( macd1 < macd0 ) {
            return 1.0;     // Impulse Up
        }
    } else if( ema1 > ema0 ) {
        macd0 = iMACDHist(symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar);
        macd1 = iMACDHist(symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar+1);
        if( macd1 > macd0 ) {
            return -1.0;    // Impulse Down
        }
    }
    return 0.0;
};

double iThreeScreens(const int bar, 
                     const string symbol = NULL, const int period = PERIOD_CURRENT,
                     const int pEMA_Scrn1 = 26, const int pEMA_Scrn2 = 13,
                     const int pMACD_F = 12, const int pMACD_S = 26, const int pMACD_Sig = 9,
                     const TS_TYPE pTSVersion = ThreeScreens_v1_2)
{   
    static  int     barScrn1, periodScrn1;
    static  double  impulseScrn1;
    static  double  impulseScrn2, macdLineScrn2, macdHistScrn2;
    static  double  sgnl[4];
    periodScrn1 = PeriodMore((ENUM_TIMEFRAMES)period, true);
    switch( pTSVersion ) {
        // Three Screens system indicator.  ©Alexander Elder
        case ThreeScreens_v1_0: {
            barScrn1     = IndexOfBar( iTime(symbol, period, bar), symbol, periodScrn1 );
            impulseScrn1 = iImpulse( barScrn1, symbol, periodScrn1, pEMA_Scrn1, pMACD_F, pMACD_S, pMACD_Sig );
            if( impulseScrn1 > 0.0 ) {
                macdLineScrn2 = iMACD( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_MAIN, bar );
                if( macdLineScrn2 <= 0.0 ) {
                    impulseScrn2 = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
                    if( impulseScrn2 >= 0.0 ) {
                        return 1.0;     // Signal Buy
                    } else {
                        return 0.5;
                    }
                }
            } else if( impulseScrn1 < 0.0 ) {
                macdLineScrn2 = iMACD( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_MAIN, bar );
                if( macdLineScrn2 >= 0.0 ) {
                    impulseScrn2 = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
                    if( impulseScrn2 <= 0.0 ) {
                        return -1.0;    // Signal Sell
                    } else {
                        return -0.5;
                    }
                }
            }
            return 0.0;
        } case ThreeScreens_v1_1: {
            // Screen #1
            barScrn1        = IndexOfBar( iTime(symbol, period, bar), symbol, periodScrn1 );
            impulseScrn1    = iImpulse( barScrn1, symbol, periodScrn1, pEMA_Scrn1, pMACD_F, pMACD_S, pMACD_Sig );
            // Screen #2 (Main)
            impulseScrn2    = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            macdHistScrn2   = iMACDHist( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar );
            if( impulseScrn1 > 0.0 && macdHistScrn2 <= 0.0 ) {
                if( impulseScrn2 >= 0.0 ) {
                    return 1.0;     // Signal Buy
                } else {
                    return 0.5;
                }
            }
            if( impulseScrn1 < 0.0 && macdHistScrn2 >= 0.0 ) {
                if( impulseScrn2 <= 0.0 ) {
                    return -1.0;    // Signal Sell
                } else {
                    return -0.5;
                }
            }
            return 0.0;
        } case ThreeScreens_v1_2: {
            // Screen #1
            barScrn1        = IndexOfBar( iTime(symbol, period, bar), symbol, periodScrn1 );
            impulseScrn1    = iImpulse( barScrn1, symbol, periodScrn1, pEMA_Scrn1, pMACD_F, pMACD_S, pMACD_Sig );
            // Screen #2 (Main)
            impulseScrn2    = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            macdLineScrn2   = iMACD( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_MAIN, bar );
            macdHistScrn2   = iMACDHist( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar );
            if( impulseScrn1 > 0.0 && ( macdLineScrn2 <= 0.0 || macdHistScrn2 <= 0.0 ) ) {
                if( impulseScrn2 >= 0.0 ) {
                    return 1.0;     // Signal Buy
                } else {
                    return 0.5;
                }
            }
            if( impulseScrn1 < 0.0 && ( macdLineScrn2 >= 0.0 || macdHistScrn2 >= 0.0 ) ) {
                if( impulseScrn2 <= 0.0 ) {
                    return -1.0;    // Signal Sell
                } else {
                    return -0.5;
                }
            }
            return 0.0;
        } case ThreeScreens_v1_3: {
            // Screen #1
            double impulseBuff[3], weigth[3] = { 1.0, 0.618, 0.382 };
            impulseBuff[0]  = iImpulse( bar, symbol, period, pEMA_Scrn1*5, pMACD_F*5, pMACD_S*5, pMACD_Sig*5 );
            impulseBuff[1]  = iImpulse( bar+2, symbol, period, pEMA_Scrn1*5, pMACD_F*5, pMACD_S*5, pMACD_Sig*5);
            impulseBuff[2]  = iImpulse( bar+4, symbol, period, pEMA_Scrn1*5, pMACD_F*5, pMACD_S*5, pMACD_Sig*5);
            impulseScrn1    = Mean( ArithmeticW, impulseBuff, weigth );
            // Screen #2 (Main)
            impulseScrn2    = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            macdLineScrn2   = iMACD( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_MAIN, bar );
            macdHistScrn2   = iMACDHist( symbol, period, pMACD_F, pMACD_S, pMACD_Sig, PRICE_CLOSE, MODE_EMA, bar );
            if( impulseScrn1 > 0.0 && ( macdLineScrn2 <= 0.0 || macdHistScrn2 <= 0.0 ) ) {
                if( impulseScrn2 >= 0.0 ) {
                    return 1.0;     // Signal Buy
                } else {
                    return 0.5;
                }
            }
            if( impulseScrn1 < 0.0 && ( macdLineScrn2 >= 0.0 || macdHistScrn2 >= 0.0 ) ) {
                if( impulseScrn2 <= 0.0 ) {
                    return -1.0;    // Signal Sell
                } else {
                    return -0.5;
                }
            }
            return 0.0;
        // Three Screens + Impulse systems indicator. ©Aleksey Terentyev 2017
        } case ThreeScreens_v1_2_1: {
            sgnl[0] = iThreeScreens( bar, symbol, period, pEMA_Scrn1, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            sgnl[1] = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            sgnl[2] = iImpulse( bar, symbol, period, (int)NormalizeDouble(pEMA_Scrn2*1.618, 0), 
                                (int)NormalizeDouble(pMACD_F*1.618, 0), (int)NormalizeDouble(pMACD_S*1.618, 0), (int)NormalizeDouble(pMACD_Sig*1.618, 0) );
            sgnl[3] = iImpulse( bar, symbol, period, (int)NormalizeDouble(pEMA_Scrn2*2.618, 0),
                                (int)NormalizeDouble(pMACD_F*2.618, 0), (int)NormalizeDouble(pMACD_S*2.618, 0), (int)NormalizeDouble(pMACD_Sig*2.618, 0) );
            return Mean( Arithmetic, sgnl );
        } case ThreeScreens_v1_2_2: {
            double wght[4] = { 1.0, 0.618, 0.5, 0.382 };
            sgnl[0] = iThreeScreens( bar, symbol, period, pEMA_Scrn1, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            sgnl[1] = iImpulse( bar, symbol, period, pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
            sgnl[2] = iImpulse( bar, symbol, period, (int)NormalizeDouble(pEMA_Scrn2*1.618, 0), 
                                (int)NormalizeDouble(pMACD_F*1.618, 0), (int)NormalizeDouble(pMACD_S*1.618, 0), (int)NormalizeDouble(pMACD_Sig*1.618, 0) );
            sgnl[3] = iImpulse( bar, symbol, period, (int)NormalizeDouble(pEMA_Scrn2*2.618, 0),
                                (int)NormalizeDouble(pMACD_F*2.618, 0), (int)NormalizeDouble(pMACD_S*2.618, 0), (int)NormalizeDouble(pMACD_Sig*2.618, 0) );
            return Mean( ArithmeticW, sgnl, wght );
        // Three Screens with MA
        } case ThreeScreens_v2_0: {
            double oPrice, trueRange;
            double emaFast0Scrn1, emaSlow0Scrn1, emaSlow1Scrn1;
            emaSlow0Scrn1   = iMA( Symbol(), Period(), pEMA_Scrn1*5, 0, MODE_EMA, PRICE_CLOSE, bar );
            emaSlow1Scrn1   = iMA( Symbol(), Period(), pEMA_Scrn1*5, 0, MODE_EMA, PRICE_CLOSE, bar+4 );
            if( emaSlow1Scrn1 - emaSlow0Scrn1 < 0 ) {           // bullish trend
                oPrice      = iOpen( Symbol(), Period(), bar );
                if( oPrice - emaSlow0Scrn1 > 0 ) {
                    emaFast0Scrn1   = iMA( Symbol(), Period(), pEMA_Scrn2*5, 0, MODE_EMA, PRICE_CLOSE, bar );
                    trueRange       = iATR( Symbol(), Period(), 14, bar+1 );
                    if( oPrice - emaFast0Scrn1 < 0 || oPrice - (emaFast0Scrn1 + trueRange*0.382) < 0 ) {
                        impulseScrn2 = iImpulse( bar, Symbol(), Period(), pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
                        if( impulseScrn2 >= 0.0 ) {
                            return 1.0;     // Signal Buy
                        } else {
                            return 0.0;
                        }
                        return 0.5;
                    }
                }
            } else if( emaSlow1Scrn1 - emaSlow0Scrn1 > 0 ) {    // bearish trend
                oPrice      = iOpen( Symbol(), Period(), bar );
                if( oPrice - emaSlow0Scrn1 < 0 ) {
                    emaFast0Scrn1   = iMA( Symbol(), Period(), pEMA_Scrn2*5, 0, MODE_EMA, PRICE_CLOSE, bar );
                    trueRange       = iATR( Symbol(), Period(), 14, bar+1 );
                    if( oPrice - emaFast0Scrn1 > 0 || oPrice - (emaFast0Scrn1 - trueRange*0.382) > 0 ) {
                        impulseScrn2 = iImpulse( bar, Symbol(), Period(), pEMA_Scrn2, pMACD_F, pMACD_S, pMACD_Sig );
                        if( impulseScrn2 <= 0.0 ) {
                            return -1.0;    // Signal Sell
                        } else {
                            return 0.0;
                        }
                        return -0.5;
                    }
                }
            }
        }
    } // switch
    return EMPTY_VALUE;
};

double iWave(const int bar, 
             const string symbol = NULL, const int period = PERIOD_CURRENT,
             const int pEMA = 34)
{   // Indicator of the market cycle aka Wave. ©Raghee Horner 2007
    double emaH, emaL, close;
    emaH = iMA(symbol, period, pEMA, 0, MODE_EMA, PRICE_HIGH, bar);
    emaL = iMA(symbol, period, pEMA, 0, MODE_EMA, PRICE_LOW, bar);
    close = iClose(symbol, period, bar);
    if( close > emaH ) {
        return 1.0;
    } else if( emaL > close ) {
        return -1.0;
    }
    return 0.0;
}

double iBouncedMA(const int bar, 
                  const string symbol = NULL, const int period = PERIOD_CURRENT,
                  const int mode = MODE_EMA, const int emaPeriod = 2)
{   // Generate signals for ML ©Aleksey Terentyev 2017-2018
    if( bar >= Bars-2 || 2 >= bar ) {
        return 0.0;
    }
    double ema1, ema0, ema_1, ema_2, result = 0.0;
    ema1 = iMA(symbol, period, emaPeriod, 0, mode, PRICE_OPEN, bar+1);
    ema0 = iMA(symbol, period, emaPeriod, 0, mode, PRICE_OPEN, bar);
    ema_1 = iMA(symbol, period, emaPeriod, 0, mode, PRICE_OPEN, bar-1);
    ema_2 = iMA(symbol, period, emaPeriod, 0, mode, PRICE_OPEN, bar-2);
    if( ema0 < ema_1 ) {
        result = 1.0;
        // if( ema1 < ema0 ) {
        //     result = 0.97; // 0.5
        // }
        if( ema_1 > ema_2 ) {
            result = 0.0;
        }
    } else if( ema0 > ema_1 ) {
        result = -1.0;
        // if( ema1 > ema0 ) {
        //     result = -0.97; // -0.5
        // }
        if( ema_1 < ema_2 ) {
            result = -0.0;
        }
    }
    return result;
};

double iBouncedMAFilteredM(const int bar, 
                          const string symbol = NULL, const int period = PERIOD_CURRENT,
                          const int mode = MODE_EMA, const int emaPeriod = 2,
                          const int filterPeriod = 5)
{   // Generate signals for ML ©Aleksey Terentyev 2017-2018
    double bounce = iBouncedMA(bar, symbol, period, mode, emaPeriod);
    double filter0 = iMA(symbol, period, filterPeriod, 0, MODE_SMA, PRICE_CLOSE, bar-2);
    double filter1 = iMA(symbol, period, filterPeriod, 0, MODE_SMA, PRICE_CLOSE, bar-1);
    if( bounce > 0.0 ) {
        if( filter1 < filter0 || MathAbs(bounce) == 1.0 ) {
            return bounce;
        }
    } else if( bounce < 0.0 ) {
        if( filter1 > filter0 || MathAbs(bounce) == 1.0 ) {
            return bounce;
        }
    }
    return 0.0;
};

double iBouncedMAFilteredP(const int bar, 
                           const string symbol = NULL, const int period = PERIOD_CURRENT,
                           const int mode = MODE_EMA, const int emaPeriod = 2,
                           const int filterFactor = 3)
{   // Generate signals for ML ©Aleksey Terentyev 2018
    double bounce = iBouncedMA(bar, symbol, period, mode, emaPeriod);
    if( bar >= Bars-2*filterFactor || 2*filterFactor >= bar ) {
        return 0.0;
    }
    double ema0, ema_1, ema_2, bounceP = 0.0;
    ema0 = iMA(symbol, period, emaPeriod*filterFactor, 0, mode, PRICE_OPEN, bar);
    ema_1 = iMA(symbol, period, emaPeriod*filterFactor, 0, mode, PRICE_OPEN, bar-1*filterFactor);
    ema_2 = iMA(symbol, period, emaPeriod*filterFactor, 0, mode, PRICE_OPEN, bar-2*filterFactor);
    if( ema0 < ema_1 ) {
        bounceP = 1.0;
        if( ema_1 > ema_2 ) {
            bounceP = 0.0;
        }
    } else if( ema0 > ema_1 ) {
        bounceP = -1.0;
        if( ema_1 < ema_2 ) {
            bounceP = -0.0;
        }
    }
    if( bounceP > 0 && bounce > 0 ) {
        return bounce;
    } else if( bounceP < 0 && bounce < 0 ) {
        return bounce;
    }
    return 0.0;
};

double iSampler(const int bar, 
                const string symbol = NULL, const int period = PERIOD_CURRENT,
                const int forwardBars = 10, const int typeSignal = 1,
                const double threshold = 0.5, const int typeDiscrete = 0, 
                const int tp = 500, const int sl = 200)
{   // iSampler (by her.human@gmail.com, 2012-2016) link: https://www.mql5.com/ru/code/903
    if( bar < forwardBars ) {
        return EMPTY_VALUE;
    }
    static double maxHigh, minLow, deviationUp, deviationDown, analog;
    //--- расчет аналогового сигнала
    maxHigh = iHigh(symbol, period, iHighest(symbol, period, MODE_HIGH, forwardBars, bar));
    minLow = iLow(symbol, period, iLowest(symbol, period, MODE_LOW, forwardBars, bar));
    deviationUp = maxHigh - iOpen(symbol, period, bar);
    deviationDown = iOpen(symbol, period, bar) - minLow;
    analog = (2.0 * deviationUp) / (deviationUp + deviationDown) - 1;
    if( typeSignal == 0 ) { // return analog signal
        return analog;
    }
    //--- расчет дискретного сигнала
    if( typeDiscrete == 0 ) {
        if( analog - threshold > 0 ) { // analog > threshold
            return 1.0;
        } else if( analog + threshold < 0 ) { // analog < -threshold
            return -1.0;
        }
    } else {
        if( deviationUp - tp * Point() > 0 ) { // dev > tp*point
            if( deviationDown - sl * Point() < 0 ) { // dev < sl*point
                return 1.0;
            }
        } else if( deviationUp - sl * Point() < 0 ) { // dev < sl*point
            if( deviationDown - tp * Point() > 0 ) { // dev > tp*point
                return -1.0;
            }
        }
    }
    return 0.0;
};

void ReadHistoryToIndicator(const string symbol, const int period,
                            const string file,
                            double &positivBuff[], double &negativeBuff[],
                            const bool sorted = true)
{
    string bTime, bType, bVol, bSym, bPrice, bStop, bTake, bTime2, bPrice3, bComsn, bSwap, bProfit, bComm;
    datetime readedT;
    int handle = FileOpen( file, FILE_READ | FILE_CSV, StringGetChar(";", 0) );
    if( handle == INVALID_HANDLE ) {
        Print( "Open file error: " + (string)GetLastError() );
        return;
    }
    // Read first line
    ReadHistoryLine(handle, bTime, bType, bVol, bSym,
                    bPrice, bStop, bTake, bTime2, 
                    bPrice3, bComsn, bSwap, bProfit, bComm);
    if( StringFind(bTime, "Time") >= 0 ) { // This header. Read first data
        ReadHistoryLine(handle, bTime, bType, bVol, bSym,
                        bPrice, bStop, bTake, bTime2, 
                        bPrice3, bComsn, bSwap, bProfit, bComm);
    }
    readedT = StringToTime(bTime);
    while( !FileIsEnding(handle) )  { // Main cicle
        if( bType == "Buy" ) {
            positivBuff[iBarShift(symbol, period, readedT)] = 0.5;
        } else if( bType == "Sell" ) {
            negativeBuff[iBarShift(symbol, period, readedT)] = -0.5;
        }
        ReadHistoryLine(handle, bTime, bType, bVol, bSym,
                                bPrice, bStop, bTake, bTime2, 
                                bPrice3, bComsn, bSwap, bProfit, bComm);
        readedT = StringToTime(bTime);
    }
    FileClose(handle);
};


//+---------------------------------------------------------------------------+
//|   L E V E L S                                                             |
//+---------------------------------------------------------------------------+
double iAdaptiveMA(const int bar, 
                   const string symbol, const int period,
                   const int &maPeriods[], const double &maWeights[], 
                   const ENUM_MA_METHOD method = MODE_EMA, const ENUM_APPLIED_PRICE price = PRICE_CLOSE,
                   const MEAN_TYPE mType = Square)
{   // Indicator Adaptive MA. ©Aleksey Terentyev 2017
    const  int    size = ArraySize(maPeriods);
    static double tmpArray[];
    ArrayResize(tmpArray, size);
    for( int idx = 0; idx < size; idx++ ) {
        tmpArray[idx] = iMA(symbol, period, maPeriods[idx], 0, method, price, bar);
    }
    if( mType == Square || mType == Arithmetic || mType == Geometric || mType == Harmonic ) {
        return Mean(mType, tmpArray);
    } else if( mType == ArithmeticW || mType == GeometricW || mType == HarmonicW ) {
        return Mean(mType, tmpArray, maWeights);
    }
    return EMPTY_VALUE;
};

enum KELTNER_CHANNEL_TYPE {
    Original,
    Modified_1,
    Modified_2
};

enum KELTNER_LINE_TYPE {
    PriceIndicator,
    Higher,
    Lower
};

double iKeltnerChannel(const int bar,
                       const string symbol = NULL, const int period = PERIOD_CURRENT,
                       const int pEMA = 10,
                       const KELTNER_LINE_TYPE line = PriceIndicator,
                       const KELTNER_CHANNEL_TYPE type = Modified_2,
                       const int ch_percent = 100)
{
    ENUM_MA_METHOD emaType = MODE_EMA;
    ENUM_APPLIED_PRICE priceType = PRICE_TYPICAL;
    if( type == Modified_2 ) {
        priceType = PRICE_CLOSE;
    } else if( type == Original ) {
        emaType = MODE_SMA;
    }
    double priceInd = iMA(symbol, period, pEMA, 0, emaType, priceType, bar);
    if( line == PriceIndicator ) {
        return priceInd;
    }
    double tradingRange = 0.0;
    if( type == Modified_1 || type == Modified_2 ) {
        tradingRange = iATR(symbol, period, pEMA, bar);
    } else if( type == Original ) {
        double trRangeArray[];
        ArrayResize(trRangeArray, pEMA);
        for( int idx = 0; idx < pEMA; idx++ ) {
            trRangeArray[idx] = iHigh(symbol, period, bar+(pEMA-idx-1)) - iLow(symbol, period, bar+(pEMA-idx-1));
        }
        tradingRange = SimpleMA(pEMA-1, pEMA, trRangeArray);
    } 
    if( line == Higher ) {
        return priceInd + tradingRange * ch_percent * 0.01;
    }
    if( line == Lower ) {
        return priceInd - tradingRange * ch_percent * 0.01;
    }
    return EMPTY_VALUE;
};

double StopBuy(const int bar,
               const string symbol = NULL, const int period = PERIOD_CURRENT, 
               const double meanMulty = 3.0)
{
    if( bar <= -2 || bar + 10 >= iBars(symbol, period) ) {
        return EMPTY_VALUE;     // Out off range
    }
    double  breakDown = 0.0, sumBD = 0.0;
    int     countBD = 0;
    for( int idx = 10; idx >= 1; idx-- ) {
        breakDown = iLow(symbol, period, bar+idx+1) - iLow(symbol, period, bar+idx);
        if( breakDown > 0 ) {
            sumBD += breakDown;
            countBD++;
        }
    }
    if( countBD == 0 ) {
        return iLow(symbol, period, bar+1) - MathAbs(breakDown) * meanMulty;
    }
    return iLow(symbol, period, bar+1) - (sumBD / countBD) * meanMulty;
};

double StopBuyMax(const int bar,
                  const string symbol = NULL, const int period = PERIOD_CURRENT,
                  const double meanMulty = 3.0)
{
    if( bar <= -2 || bar + 13 >= iBars(symbol, period) ) {
        return EMPTY_VALUE;     // Out off range
    }
    double bs[3];
    bs[2] = StopBuy(bar+2, symbol, period, meanMulty);
    bs[1] = StopBuy(bar+1, symbol, period, meanMulty);
    bs[0] = StopBuy(bar, symbol, period, meanMulty);
    return MathMax(bs[0], bs[1], bs[2]);
};

double StopSell(const int bar,
                const string symbol = NULL, const int period = PERIOD_CURRENT,
                const double meanMulty = 3.0)
{
    if( bar <= -2 || bar + 10 >= iBars(symbol, period) ) {
        return EMPTY_VALUE;     // Out off range
    }
    double  breakUp = 0.0, sumBU = 0.0;
    int     countBU = 0;
    for( int idx = 10; idx >= 1; idx-- ) {
        breakUp = iHigh(symbol, period, bar+idx) - iHigh(symbol, period, bar+idx+1);
        if( breakUp > 0 ) {
            sumBU += breakUp;
            countBU++;
        }
    }
    if( countBU == 0 ) {
        return iHigh(symbol, period, bar+1) + MathAbs(breakUp) * meanMulty;
    }
    return iHigh(symbol, period, bar+1) + (sumBU / countBU) * meanMulty;
};

double StopSellMin(const int bar,
                   const string symbol = NULL, const int period = PERIOD_CURRENT,
                   const double meanMulty = 3.0)
{
    if( bar <= -2 || bar + 13 >= iBars(symbol, period) ) {
        return EMPTY_VALUE;     // Out off range
    }
    double ss[3];
    ss[2] = StopSell(bar+2, symbol, period, meanMulty);
    ss[1] = StopSell(bar+1, symbol, period, meanMulty);
    ss[0] = StopSell(bar, symbol, period, meanMulty);
    return MathMin(ss[0], ss[1], ss[2]);
};


//+---------------------------------------------------------------------------+
//|   I N D E X E S                                                           |
//+---------------------------------------------------------------------------+
double iMACDHist(const string symbol, const int timeframe,
                 const int fast_ema_period, const int slow_ema_period, const int signal_period,
                 const int applied_price, const int ma_method,
                 const int shift)
{   // Original MACD Histogram
    if( ma_method == MODE_EMA ) {
        static double bufferMACD[], bufferSignal[];
        int bSize = signal_period * 3;
        ArrayResize(bufferMACD, bSize);
        ArrayResize(bufferSignal, bSize);
        bufferSignal[bSize-1] = iMACD(symbol, timeframe, fast_ema_period, slow_ema_period, signal_period, applied_price, MODE_MAIN, shift+bSize-1);
        for( int idx = bSize-2; idx >= 0; idx-- ) {
            bufferMACD[idx] = iMACD(symbol, timeframe, fast_ema_period, slow_ema_period, signal_period, applied_price, MODE_MAIN, shift+idx);
            bufferSignal[idx] = ExponentialMA(idx, signal_period, bufferSignal[idx+1], bufferMACD);
        }
        return bufferMACD[0] - bufferSignal[0];
    } else if( ma_method == MODE_SMA ) {    // MetaQuotes MACD Histogram
        return iOsMA(symbol, timeframe, fast_ema_period, slow_ema_period, signal_period, applied_price, shift);
    }
    return EMPTY_VALUE;
};

double iDollarIndex(const int bar, const int period = PERIOD_CURRENT)
{
    static bool _firstRunFlag = true;
    static string currencies[6] = {"", "", "", "", "", ""};
    if( _firstRunFlag ) {
        string symbols[];
        int size = SymbolsList(true, symbols);
        for( int idx = 0; idx < size; idx++ ) {
            if( StringFind(symbols[idx], "EURUSD") >= 0 ) { currencies[0] = symbols[idx]; }
            if( StringFind(symbols[idx], "USDJPY") >= 0 ) { currencies[1] = symbols[idx]; }
            if( StringFind(symbols[idx], "GBPUSD") >= 0 ) { currencies[2] = symbols[idx]; }
            if( StringFind(symbols[idx], "USDCAD") >= 0 ) { currencies[3] = symbols[idx]; }
            if( StringFind(symbols[idx], "USDSEK") >= 0 ) { currencies[4] = symbols[idx]; }
            if( StringFind(symbols[idx], "USDCHF") >= 0 ) { currencies[5] = symbols[idx]; }
        }
        _firstRunFlag = false;
    }
    double usdx = 50.14348112 *
                    MathPow(iClose(currencies[0], period, bar), -0.576) *
                    MathPow(iClose(currencies[1], period, bar), 0.136) *
                    MathPow(iClose(currencies[2], period, bar), -0.119) *
                    MathPow(iClose(currencies[3], period, bar), 0.091) *
                    MathPow(StringLen(currencies[4]) > 0 ?
                                iClose(currencies[4], period, bar) :
                                8.25, 0.042) * // Average for the year
                    MathPow(iClose(currencies[5], period, bar), 0.036);
    return usdx;
};

double iEuroIndex(const int bar, const int period = PERIOD_CURRENT)
{
    static bool _firstRunFlag = true;
    static string currencies[5] = {"", "", "", "", ""};
    if( _firstRunFlag ) {
        string symbols[];
        int size = SymbolsList(true, symbols);
        for( int idx = 0; idx < size; idx++ ) {
            if( StringFind(symbols[idx], "EURUSD") >= 0 ) { currencies[0] = symbols[idx]; }
            if( StringFind(symbols[idx], "EURGBP") >= 0 ) { currencies[1] = symbols[idx]; }
            if( StringFind(symbols[idx], "EURJPY") >= 0 ) { currencies[2] = symbols[idx]; }
            if( StringFind(symbols[idx], "EURCHF") >= 0 ) { currencies[3] = symbols[idx]; }
            if( StringFind(symbols[idx], "EURSEK") >= 0 ) { currencies[4] = symbols[idx]; }
        }
        _firstRunFlag = false;
    }
    double eurx = 34.38805726 *
                    MathPow(iClose(currencies[0], period, bar), 0.3155) *
                    MathPow(iClose(currencies[1], period, bar), 0.3056) *
                    MathPow(iClose(currencies[2], period, bar), 0.1891) *
                    MathPow(iClose(currencies[3], period, bar), 0.1113) *
                    MathPow(StringLen(currencies[4]) > 0 ?
                                iClose(currencies[4], period, bar) :
                                9.6, 0.0785); // Average for the year
    return eurx;
};

enum TIMESERIES_TYPE {
    _Close,
    _Open,
    _High,
    _Low,
    _MovingAverage,
    _MACDLine,
    _MACDHist
};

double iDerivative(const int bar, 
                   const string symbol = NULL, const int period = PERIOD_CURRENT,
                   const TIMESERIES_TYPE arrayType = _Close,
                   const int delta = 1, const int emaPeriod = 10)
{
    static bool _firstRunFlag = true;
    static double buffer[];
    if( _firstRunFlag ) {
        // ? copy series to buffer
        _firstRunFlag = false;
    }
    // GOTO
    if( bar < delta ) {
        return EMPTY_VALUE;
    }
    if( delta == 0 ) {
        switch( arrayType ) {
            case _Close: return iClose(symbol, period, bar);
            case _Open: return iOpen(symbol, period, bar);
            case _High: return iHigh(symbol, period, bar);
            case _Low: return iLow(symbol, period, bar);
            case _MovingAverage: return iMA(symbol, period, emaPeriod, 0, MODE_EMA, PRICE_CLOSE, bar);
            case _MACDLine: return iMACD(symbol, period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, bar);
            case _MACDHist: return iMACDHist(symbol, period, 12, 26, 9, PRICE_CLOSE, MODE_EMA, bar);
        }
    }
    double result;
    switch( arrayType ) {
        case _Close: {
            result = iClose(symbol, period, bar);
            for( int idx = bar+delta-1; idx >= bar; idx-- ) {
                // GOTO
            }
            break;
        }
        //GOTO
    }
    return 0.0;
};

