#ifndef MAS_MASTERWINDOWS
#define MAS_MASTERWINDOWS
//+---------------------------------------------------------------------------+
//|                                                    MASh_MasterWindows.mqh |
//|                                                    Market Analysis System |
//|                                    Copyright 2016-2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright "Copyright 2016-2017, Terentyev Aleksey"
#property link      "https://www.mql5.com/ru/users/terentyev23"
#property strict

//+---------------------------------------------------------------------------+
//| MasterWindow Includes (Edited)                                            |
//|                                                     MasterWindows Library |
//|                                                          Copyright DC2008 |
//|                                       http://www.mql5.com/ru/users/dc2008 |
//+---------------------------------------------------------------------------+
#define  MAX_WIN    50
#define  MIN_WIN    48
#define  CLOSE_WIN  208
#define  PAGE_UP    112
#define  PAGE_DOWN  113
#define  TIME_SLEEP 50
#define  DELTA      1
#define  B_WIN      150 // ширина окна по умолчанию

struct WinCell
{  
    color             TextColor;
    color             BGColor;
    color             BGEditColor;
    ENUM_BASE_CORNER  Corner;
    int               H;
    int               Corn; // направление смещения (1;-1)
};

class CCell
{
private:
protected:
    bool              on_event;
    ENUM_OBJECT       type;
public:
    WinCell           Property;
    string            name;
    
    void CCell()
    {
        Property.TextColor = clrWhite;
        Property.BGColor = clrSteelBlue;
        Property.BGEditColor = clrDimGray;
        Property.Corner = CORNER_LEFT_UPPER;
        Property.Corn = 1;
        Property.H = 18;
        on_event = false;
    }
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize)
    {
        on_event = true;
    }
    virtual void OnEvent(const int id, const long &lparam, 
                         const double &dparam, const string &sparam)
    {
        if( on_event ) {
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK 
                        && StringFind(sparam, ".Button", 0) > 0 ) {
                if( ObjectGetInteger(0, sparam, OBJPROP_STATE) == 1 ) {
                    Sleep( TIME_SLEEP );    // если кнопка залипла
                    ObjectSetInteger( 0, sparam, OBJPROP_STATE, 0 );
                    ChartRedraw();
                }
            }
        }
    }
};

class CCellText : public CCell
{
public:
    void CCellText()
    {
        type = OBJ_EDIT;
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta,
                      int m_bsize, string m_text)
    {
        name = m_name + ".Text";
        if( ObjectFind( name ) >= 0 )
            ObjectDelete( name );
        if( ObjectCreate(0, name, type, 0, 0, 0, 0, 0) == false )
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        ObjectSetInteger( 0, name, OBJPROP_COLOR, Property.TextColor );
        ObjectSetInteger( 0, name, OBJPROP_BGCOLOR, Property.BGColor );
        ObjectSetInteger( 0, name, OBJPROP_READONLY, true );
        ObjectSetInteger( 0, name, OBJPROP_CORNER, Property.Corner );
        ObjectSetInteger( 0, name, OBJPROP_XDISTANCE, m_xdelta );
        ObjectSetInteger( 0, name, OBJPROP_YDISTANCE, m_ydelta );
        ObjectSetInteger( 0, name, OBJPROP_XSIZE, m_bsize );
        ObjectSetInteger( 0, name, OBJPROP_YSIZE, Property.H );
        ObjectSetString(  0, name, OBJPROP_FONT, "Arial" );
        ObjectSetString(  0, name, OBJPROP_TEXT, m_text );
        ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 10 );
        ObjectSetInteger( 0, name, OBJPROP_SELECTABLE, 0 );
        on_event = true;
    }
};

class CCellEdit : public CCell
{
public:
    void CCellEdit()
    {
        type = OBJ_EDIT;
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, 
                      int m_bsize, string m_text, bool m_read)
    {
        name = m_name + ".Edit";
        if( ObjectFind( name ) >= 0 )
            ObjectDelete( name );
        if( ObjectCreate(0, name, type, 0, 0, 0, 0, 0) == false )
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        ObjectSetInteger( 0, name, OBJPROP_COLOR, Property.TextColor );
        ObjectSetInteger( 0, name, OBJPROP_BGCOLOR, Property.BGEditColor );
        ObjectSetInteger( 0, name, OBJPROP_READONLY, m_read );
        ObjectSetInteger( 0, name, OBJPROP_CORNER, Property.Corner );
        ObjectSetInteger( 0, name, OBJPROP_XDISTANCE, m_xdelta );
        ObjectSetInteger( 0, name, OBJPROP_YDISTANCE, m_ydelta );
        ObjectSetInteger( 0, name, OBJPROP_XSIZE, m_bsize );
        ObjectSetInteger( 0, name, OBJPROP_YSIZE, Property.H );
        ObjectSetString(  0, name, OBJPROP_FONT, "Arial" );
        ObjectSetString(  0, name, OBJPROP_TEXT, m_text );
        ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 10 );
        ObjectSetInteger( 0, name, OBJPROP_SELECTABLE, 0 );
        on_event = true;
    }
};

class CCellButton : public CCell
{
public:
    void CCellButton()
    {
        type = OBJ_BUTTON;
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta,
                      int m_bsize, string m_button)
    {
        name = m_name + ".Button";
        if( ObjectFind( name ) >= 0 )
            ObjectDelete( name );
        if( ObjectCreate(0, name, type, 0, 0, 0, 0, 0) == false )
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        ObjectSetInteger( 0, name, OBJPROP_COLOR, Property.TextColor );
        ObjectSetInteger( 0, name, OBJPROP_BGCOLOR, Property.BGColor );
        ObjectSetInteger( 0, name, OBJPROP_CORNER, Property.Corner );
        ObjectSetInteger( 0, name, OBJPROP_XDISTANCE, m_xdelta );
        ObjectSetInteger( 0, name, OBJPROP_YDISTANCE, m_ydelta );
        ObjectSetInteger( 0, name, OBJPROP_XSIZE, m_bsize );
        ObjectSetInteger( 0, name, OBJPROP_YSIZE, Property.H );
        ObjectSetString(  0, name, OBJPROP_FONT, "Arial" );
        ObjectSetString(  0, name, OBJPROP_TEXT, m_button );
        ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 10 );
        ObjectSetInteger( 0, name, OBJPROP_SELECTABLE, 0 );
        on_event = true;
    }
};

class CCellButtonType : public CCell
{
public:
    void CCellButtonType()
    {
        type = OBJ_BUTTON;
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_type)
    {
        if( m_type <= 0 )
            m_type = 0;
        name = m_name + ".Button" + (string)m_type;
        if( ObjectFind( name ) >= 0 )
            ObjectDelete( name );
        if( ObjectCreate(0, name, type, 0, 0, 0, 0, 0) == false )
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        ObjectSetInteger( 0, name, OBJPROP_COLOR, Property.TextColor );
        ObjectSetInteger( 0, name, OBJPROP_BGCOLOR, Property.BGColor );
        ObjectSetInteger( 0, name, OBJPROP_CORNER, Property.Corner );
        ObjectSetInteger( 0, name, OBJPROP_XDISTANCE, m_xdelta );
        ObjectSetInteger( 0, name, OBJPROP_YDISTANCE, m_ydelta );
        ObjectSetInteger( 0, name, OBJPROP_XSIZE, Property.H );
        ObjectSetInteger( 0, name, OBJPROP_YSIZE, Property.H );
        ObjectSetInteger( 0, name, OBJPROP_SELECTABLE, 0 );
        if( m_type == 0 ) {         // Кнопка Hide
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(MIN_WIN) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Webdings" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 12 );
        }
        if( m_type == 1 ) {         // Кнопка Close
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(CLOSE_WIN) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Wingdings 2" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 8 );
        }
        if( m_type == 2 ) {         // Кнопка Return
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(MAX_WIN) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Webdings" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 12 );
        }
        if( m_type == 3 ) {         // Кнопка Plus
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(41) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Wingdings 3" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 11 );
        }
        if( m_type == 4 ) {         // Кнопка Minus
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(165) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Wingdings 3" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 11 );
        }
        if( m_type == 5 ) {         // Кнопка PageUp
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(34) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Wingdings 3" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 11 );
        }
        if( m_type == 6 ) {         // Кнопка PageDown
            ObjectSetString(  0, name, OBJPROP_TEXT, CharToString(42) );
            ObjectSetString(  0, name, OBJPROP_FONT, "Wingdings 3" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 11 );
        }
        if( m_type > 6 ) {          // empty
            ObjectSetString(  0, name, OBJPROP_TEXT, "" );
            ObjectSetString(  0, name, OBJPROP_FONT, "Arial" );
            ObjectSetInteger( 0, name, OBJPROP_FONTSIZE, 13 );
        }
        on_event = true;
    }
};

class CRow
{
protected:
    bool        on_event;
public:
    string      name;
    WinCell     Property;
    
    void CRow()
    {
        Property.TextColor = clrWhite;
        Property.BGColor = clrSteelBlue;
        Property.BGEditColor = clrDimGray;
        Property.Corner = CORNER_LEFT_UPPER;
        Property.Corn = 1;
        Property.H = 18;
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize)
    {
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if(on_event) { }
    }
};

class CRowType1 : public CRow
{
public:
    CCellText       Text;
    CCellButtonType Hide,Close;
    
    void CRowType1()
    {
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_type, string m_text)
    {
        int X, B;
        Text.Property  = Property;
        Hide.Property  = Property;
        Close.Property = Property;
        if( m_type <= 0 ) {
            name = m_name + ".RowType1(0)";
            B = m_bsize - 2 * ( Property.H + DELTA );
            Text.Draw( name, m_xdelta, m_ydelta, B, m_text );
            X = m_xdelta + Property.Corn * ( B + DELTA );
            Hide.Draw( name, X, m_ydelta, 0 );
            X = X + Property.Corn * ( Property.H + DELTA );
            Close.Draw( name, X, m_ydelta, 1 );
        } else if( m_type == 1 ) {
            name = m_name + ".RowType1(1)";
            B = m_bsize - ( Property.H + DELTA );
            Text.Draw( name, m_xdelta, m_ydelta, B, m_text );
            X = m_xdelta + Property.Corn * ( B + DELTA );
            Close.Draw( name, X, m_ydelta, 1 );
        } else if( m_type == 2 ) {
            name = m_name + ".RowType1(2)";
            B = m_bsize - ( Property.H + DELTA );
            Text.Draw( name, m_xdelta, m_ydelta, B, m_text );
            X = m_xdelta + Property.Corn * ( B + DELTA );
            Hide.Draw( name, X, m_ydelta, 0 );
        } else if( m_type >= 3 ) {
            name = m_name + ".RowType1(3)";
            B = m_bsize;
            Text.Draw( name, m_xdelta, m_ydelta, B, m_text );
        }
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) {
            Text.OnEvent(  id, lparam, dparam, sparam );
            Hide.OnEvent(  id, lparam, dparam, sparam );
            Close.OnEvent( id, lparam, dparam, sparam );
        }
    }
};

class CRowType2 : public CRow
{
public:
    CCellText           Text;
    CCellEdit           Edit;
    
    void CRowType2()
    {
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_tsize,
                        string m_text, string m_edit)
    {
        int X, B;
        Text.Property = Property;
        Edit.Property = Property;
        name = m_name + ".RowType2";
        Text.Draw( name, m_xdelta, m_ydelta, m_tsize, m_text );
        B = m_bsize - m_tsize - DELTA;
        X = m_xdelta + Property.Corn * ( m_tsize + DELTA );
        Edit.Draw( name, X, m_ydelta, B, m_edit, false );
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) {
            Text.OnEvent( id, lparam, dparam, sparam );
            Edit.OnEvent( id, lparam, dparam, sparam );
        }
    }
};

class CRowType3 : public CRow
{
public:
    CCellText           Text;
    CCellEdit           Edit;
    CCellButtonType     Plus, Minus;
    
    void CRowType3()
    {
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_tsize,
                        string m_text, string m_edit)
    {
        int X, B;
        Text.Property  = Property;
        Edit.Property  = Property;
        Plus.Property  = Property;
        Minus.Property = Property;
        name = m_name + ".RowType3";
        Text.Draw( name, m_xdelta, m_ydelta, m_tsize, m_text );
        B = m_bsize - ( m_tsize + DELTA ) - 2 * ( Property.H + DELTA );
        X = m_xdelta + Property.Corn * ( m_tsize + DELTA );
        Edit.Draw( name, X, m_ydelta, B, m_edit, true );
        X = X + Property.Corn * ( B + DELTA );
        Plus.Draw( name, X, m_ydelta, 3 );
        X = X + Property.Corn * ( Property.H + DELTA );
        Minus.Draw( name, X, m_ydelta, 4 );
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) {
            Text.OnEvent(  id, lparam, dparam, sparam );
            Edit.OnEvent(  id, lparam, dparam, sparam );
            Plus.OnEvent(  id, lparam, dparam, sparam );
            Minus.OnEvent( id, lparam, dparam, sparam );
        }
    }
};

class CRowType4 : public CRow
{
public:
    CCellText           Text;
    CCellEdit           Edit;
    CCellButtonType     Plus, Minus, Up, Down;
    
    void CRowType4()
    {
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_tsize,
                        string m_text, string m_edit)
    {
        int X, B;
        Text.Property  = Property;
        Edit.Property  = Property;
        Plus.Property  = Property;
        Minus.Property = Property;
        Up.Property    = Property;
        Down.Property  = Property;
        name = m_name + ".RowType4";
        Text.Draw( name, m_xdelta, m_ydelta, m_tsize, m_text );
        B = m_bsize - ( m_tsize + DELTA ) - 4 * ( Property.H + DELTA );
        X = m_xdelta + Property.Corn * ( m_tsize + DELTA );
        Edit.Draw( name, X, m_ydelta, B, m_edit, true );
        X = X + Property.Corn * ( B + DELTA );
        Plus.Draw( name, X, m_ydelta, 3 );
        X = X + Property.Corn * ( Property.H + DELTA );
        Minus.Draw( name, X, m_ydelta, 4 );
        X = X + Property.Corn * ( Property.H + DELTA );
        Up.Draw( name, X, m_ydelta, 5 );
        X = X + Property.Corn * ( Property.H + DELTA );
        Down.Draw( name, X, m_ydelta, 6 );
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) {
            Text.OnEvent(  id, lparam, dparam, sparam );
            Edit.OnEvent(  id, lparam, dparam, sparam );
            Plus.OnEvent(  id, lparam, dparam, sparam );
            Minus.OnEvent( id, lparam, dparam, sparam );
            Up.OnEvent(    id, lparam, dparam, sparam );
            Down.OnEvent(  id, lparam, dparam, sparam );
        }
    }
};

class CRowType5 : public CRow
{
public:
    CCellText           Text;
    CCellButton         Button;
    
    void CRowType5()
    {
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_csize,
                        string m_text, string m_button)
    {
        int X, B;
        Text.Property   = Property;
        Button.Property = Property;
        name = m_name + ".RowType5";
        Text.Draw( name, m_xdelta, m_ydelta, m_csize, m_text );
        B = m_bsize - m_csize - DELTA;
        X = m_xdelta + Property.Corn * ( m_csize + DELTA );
        Button.Draw( name, X, m_ydelta, B, m_button );
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) {
            Text.OnEvent(   id, lparam, dparam, sparam );
            Button.OnEvent( id, lparam, dparam, sparam );
        }
    }
};

class CRowType6 : public CRow
{
public:
    CCellButton         Button;

    void CRowType6()
    {
        on_event = false;
    }
    
    virtual void Draw(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_b1size, int m_b2size,
                        string m_button1, string m_button2, string m_button3)
    {
        int X, B;
        Button.Property = Property;
        name = m_name + ".RowType6(1)";
        B = m_b1size;
        X = m_xdelta;
        Button.Draw( name, X, m_ydelta, B, m_button1 );
        name = m_name + ".RowType6(2)";
        B = m_b2size;
        X = X + Property.Corn * ( m_b1size + DELTA );
        Button.Draw( name, X, m_ydelta, B, m_button2 );
        name = m_name + ".RowType6(3)";
        B = m_bsize - ( m_b1size + DELTA ) - ( m_b2size + DELTA );
        X = X + Property.Corn * ( m_b2size + DELTA );
        Button.Draw( name, X, m_ydelta, B, m_button3 );
        on_event = true;
    }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) {
            Button.OnEvent( id, lparam, dparam, sparam );
        }
    }
};

class CWin
{
private:
    void SetXY(int m_corner)
    {
        if( (ENUM_BASE_CORNER)m_corner == CORNER_LEFT_UPPER ) {
            w_xpos = w_xdelta;
            w_ypos = w_ydelta;
            Property.Corn = 1;
        } else if( (ENUM_BASE_CORNER)m_corner == CORNER_RIGHT_UPPER ) {
            w_xpos = w_xdelta + w_bsize;
            w_ypos = w_ydelta;
            Property.Corn = -1;
        } else if( (ENUM_BASE_CORNER)m_corner == CORNER_LEFT_LOWER ) {
            w_xpos = w_xdelta;
            w_ypos = w_ydelta + w_hsize + Property.H;
            Property.Corn = 1;
        } else if( (ENUM_BASE_CORNER)m_corner == CORNER_RIGHT_LOWER ) {
            w_xpos = w_xdelta + w_bsize;
            w_ypos = w_ydelta + w_hsize + Property.H;
            Property.Corn = -1;
        } else {
            Print( "Error setting the anchor corner = ", m_corner );
            w_corner = CORNER_LEFT_UPPER;
            w_xpos = 0;
            w_ypos = 0;
            Property.Corn = 1;
        }
        if( (ENUM_BASE_CORNER)w_corner == CORNER_LEFT_UPPER ) {
            w_h_corner = CORNER_LEFT_LOWER;
        } else if( (ENUM_BASE_CORNER)w_corner == CORNER_LEFT_LOWER ) {
            w_h_corner = CORNER_LEFT_LOWER;
        } else if( (ENUM_BASE_CORNER)w_corner == CORNER_RIGHT_UPPER ) {
            w_h_corner = CORNER_RIGHT_LOWER;
        } else if( (ENUM_BASE_CORNER)w_corner == CORNER_RIGHT_LOWER ) {
            w_h_corner = CORNER_RIGHT_LOWER;
        }
    }
protected:
    bool            on_event;   // флаг обработки событий
public:
    string          name;       // имя окна
    int             w_corner;   // угол привязки
    int             w_xdelta;   // вертикальный отступ
    int             w_ydelta;   // горизонтальный отступ
    int             w_xpos;     // координата X точки привязки
    int             w_ypos;     // координата Y точки привязки
    int             w_bsize;    // ширина окна
    int             w_hsize;    // высота окна
    int             w_h_corner; // угол привязки HIDE режима
    WinCell         Property;   // свойства окна
    CRowType1       STR0;       // объявление строки класса
    CRowType2       STR1;
    CRowType4       STR2;
    
    void CWin()
    {
        Property.TextColor = clrWhite;
        Property.BGColor = clrSteelBlue;
        Property.BGEditColor = clrDimGray;
        Property.Corner = CORNER_LEFT_UPPER;
        Property.Corn = 1;
        Property.H = 18;
        on_event = false;
    }
    
    void SetWin(string m_name, int m_xdelta, int m_ydelta, int m_bsize, int m_corner)
    {
        name = m_name;
        if( (ENUM_BASE_CORNER)m_corner == CORNER_LEFT_UPPER ) {
            w_corner = m_corner;
        } else if( (ENUM_BASE_CORNER)m_corner == CORNER_RIGHT_UPPER ) {
            w_corner = m_corner;
        } else if( (ENUM_BASE_CORNER)m_corner == CORNER_LEFT_LOWER ) {
            w_corner = CORNER_LEFT_UPPER;
        } else if( (ENUM_BASE_CORNER)m_corner == CORNER_RIGHT_LOWER ) {
            w_corner = CORNER_RIGHT_UPPER;
        } else {
            Print( "Error setting the anchor corner = ", m_corner );
            w_corner = CORNER_LEFT_UPPER;
        }
        if( m_xdelta >= 0 ) {
            w_xdelta = m_xdelta;
        } else {
            Print( "The offset error X = ", m_xdelta );
            w_xdelta = 0;
        }
        if( m_ydelta >= 0 ) {
            w_ydelta = m_ydelta;
        } else {
            Print( "The offset error Y = ", m_ydelta );
            w_ydelta = 0;
        }
        if( m_bsize > 0 ) {
            w_bsize = m_bsize;
        } else {
            Print( "Error setting the window width = ", m_bsize );
            w_bsize = B_WIN;
        }
        Property.Corner = (ENUM_BASE_CORNER)w_corner;
        SetXY( w_corner );
    }
    
    virtual void Draw(int &MMint[][3], string &MMstr[][3], int count)
    {
        STR0.Property = Property;
        STR1.Property = Property;
        STR2.Property = Property;
        int X, Y, B;
        string strname;
        X = w_xpos;
        Y = w_ypos;
        B = w_bsize;
        for( int i = 0; i <= count; i++ ) {
            strname = ".STR" + (string)i;
            if( MMint[i][0] == 1 ) 
                STR0.Draw( name + strname, X, Y, B, MMint[i][1], MMstr[i][0] );
            if( MMint[i][0] == 2 ) 
                STR1.Draw( name + strname, X, Y, B, MMint[i][1], MMstr[i][0], MMstr[i][1] );
            if( MMint[i][0] == 4 ) 
                STR2.Draw( name + strname, X, Y, B, MMint[i][1], MMstr[i][0], MMstr[i][1] );
            Y = Y + Property.H + DELTA ;
        }
        ChartRedraw();
        on_event = true;
    }
    
    virtual void OnEventTick() { }
    
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event ) { }
    }
};

#endif // MAS_MASTERWINDOWS
