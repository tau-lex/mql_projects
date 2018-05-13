//+---------------------------------------------------------------------------+
//|                                                             MASh_Math.mqh |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property strict

//+---------------------------------------------------------------------------+
//| Includes                                                                  |
//+---------------------------------------------------------------------------+
//#include                <MovingAverages.mqh>

//+---------------------------------------------------------------------------+
//| Defines                                                                   |
//+---------------------------------------------------------------------------+
enum MEAN_TYPE {
    Square,
    Arithmetic,
    Geometric,
    Harmonic,
    ArithmeticW,
    GeometricW,
    HarmonicW,
    StandartDeviation
};

//+---------------------------------------------------------------------------+
//| Functions                                                                 |
//+---------------------------------------------------------------------------+
//+
//+---------------------------------------------------------------------------+
//| Mathematic                                                                |
//+---------------------------------------------------------------------------+
int Fibonacci(const int index)
{
    if( index == 1 || index == 2 ) 
        return 1;
    int result = 1;
    int last = 1;
    for( int idx = 3; idx <= index; idx++ ) {
        int new_last = result;
        result += last;
        last = new_last;
    }
    return result;
};

template<typename T>
double Mean(const MEAN_TYPE type, T &array[])
{   // Calculate mean value
    int size = ArraySize(array);
    if( size == 0 ) {
        Print( "Error. Mean(). Array is empty." );
        return EMPTY_VALUE;
    }
    if( size == 1 ) {
        return array[0];
    }
    double sum = 0.0;
    switch( type ) {
        case Square: {
            for( int idx = 0; idx < size; idx++ )
                sum += MathPow( (double)array[idx], 2 );
            return MathSqrt( sum / size );
        }
        case Arithmetic: {
            for( int idx = 0; idx < size; idx++ )
                sum += (double)array[idx];
            return sum / size;
        }
        case Geometric: {
            sum = 1.0;
            for( int idx = 0; idx < size; idx++ )
                sum *= (double)array[idx];
            return MathPow( sum, 1.0 / size );
        }
        case Harmonic: {
            for( int idx = 0; idx < size; idx++ )
                sum += 1.0 / (double)array[idx];
            return size / sum;
        }
        case StandartDeviation: {
            // ArraySort( array );
            for( int idx = 0; idx < size; idx++ )
                sum += (double)array[idx];
            double meanA = sum / size;
            sum = 0.0;
            for( int idx = 0; idx < size; idx++ )
                sum += MathPow( (double)array[idx] - meanA, 2 );
            return MathSqrt( sum / size );
        }
        default: return EMPTY_VALUE;
    }
};

template<typename T1, typename T2>
double Mean(const MEAN_TYPE type, T1 &array[], T2 &arrayW[])
{   // Calculate mean value
    int size = ArraySize(array), sizeW = ArraySize(arrayW);
    if( size == 0 || sizeW == 0 ) {
        Print( "Error. Mean(). Array is empty." );
        return EMPTY_VALUE;
    } else if( size != sizeW ) {
        Print( "Error. Mean(). Arrays are not equal." );
        return EMPTY_VALUE;
    }
    if( size == 1 ) {
        return array[0];
    }
    double sum = 0.0;
    switch( type ) {
        case ArithmeticW: {
            // ArraySort( array );
            double sumW = 0.0;
            for( int idx = 0; idx < size; idx++ ) {
                sum += arrayW[idx] * (double)array[idx];
                sumW += arrayW[idx];
            }
            return sum / sumW;
        }
        case GeometricW: {
            // ArraySort( array );
            double sumW = 0.0;
            for( int idx = 0; idx < size; idx++ ) {
                sum += arrayW[idx] * MathLog( (double)array[idx] );
                sumW += arrayW[idx];
            }
            return MathExp( sum / sumW );
        }
        case HarmonicW: {
            // ArraySort( array );
            double sumW = 0.0;
            for( int idx = 0; idx < size; idx++ ) {
                sum += arrayW[idx] / (double)array[idx];
                sumW += arrayW[idx];
            }
            return sumW / sum;
        }
        default: return EMPTY_VALUE;
    }
};

template<typename T>
void MathSwap(const T &l, const T &r)
{
	T swap = l;
	l = r;
	r = swap;
};

template<typename T>
T MathMax(const T var1, const T var2, const T var3)
{
	return MathMax( MathMax( var1, var2 ), var3 );
};
template<typename T>
T MathMax(const T var1, const T var2, const T var3, const T v4)
{
	return MathMax( MathMax( var1, var2, var3 ), v4 );
};
template<typename T>
T MathMax(const T var1, const T var2, const T var3, const T v4, const T v5)
{
	return MathMax( MathMax( var1, var2, var3, v4 ), v5 );
};

template<typename T>
T MathMin(const T var1, const T var2, const T var3)
{
	return MathMin( MathMin( var1, var2 ), var3 );
};
template<typename T>
T MathMin(const T var1, const T var2, const T var3, const T v4)
{
	return MathMin( MathMin( var1, var2, var3 ), v4 );
};
template<typename T>
T MathMin(const T var1, const T var2, const T var3, const T v4, const T v5)
{
	return MathMin( MathMin( var1, var2, var3, v4 ), v5 );
};

template<typename T>
T MaxValueArray(const T &array[], const int position = 0, int length = -1)
{
	if( length < 0 ) {
		length = WHOLE_ARRAY;
    }
	return array[ArrayMaximum(array, length, position)];
};

template<typename T>
T MinValueArray(const T &array[], const int position = 0, int length = -1)
{
	if( length < 0 ) {
		length = WHOLE_ARRAY;
    }
	return array[ArrayMinimum(array, length, position)];
};

template<typename T>
int ArrayMaxValueIndex(const T &array[], const int position = 0, int length = -1)
{
    int arraySize = ArraySize(array);
    if( position >= arraySize-1 || position < 0 ||
        ( position+length+1 >= arraySize && length >= 0 ) ) {
            return position; // -1
    }
	if( length < 0 ) {
		length = ArraySize(array) - position - 1;
    }
    int maxIdx = position;
    for( int idx = position; idx < position + length; idx++ ) {
        if( array[idx] - array[maxIdx] > 0 ) {
            maxIdx = idx;
        }
    }
	return maxIdx;
};

template<typename T>
int ArrayMinValueIndex(const T &array[], const int position = 0, int length = -1)
{
    int arraySize = ArraySize(array);
    if( position >= arraySize-1 || position < 0 ||
        ( position+length+1 >= arraySize && length >= 0 ) ) {
            return position; // -1
    }
	if( length < 0 ) {
		length = arraySize - position - 1;
    }
    int minIdx = position;
    for( int idx = position; idx < position + length; idx++ ) {
        if( array[idx] - array[minIdx] < 0 ) {
            minIdx = idx;
        }
    }
	return minIdx;
};

