//+---------------------------------------------------------------------------+
//|                                                          MASh_UIClass.mqh |
//|                                         Copyright 2017, Terentyev Aleksey |
//|                                 https://www.mql5.com/ru/users/terentyev23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2017, Terentyev Aleksey"
#property link          "https://www.mql5.com/ru/users/terentyev23"
#property strict


//+---------------------------------------------------------------------------+
//|   R E S O U R C E                                                         |
//+---------------------------------------------------------------------------+
#resource                   "img_UI-Class\\background.bmp"
#resource                   "img_UI-Class\\button_on.bmp"
#resource                   "img_UI-Class\\button_off.bmp"
#resource                   "img_UI-Class\\button-win1_on.bmp"
#resource                   "img_UI-Class\\button-win1_off.bmp"
#resource                   "img_UI-Class\\button-win_on.bmp"
#resource                   "img_UI-Class\\button-win_off.bmp"
#resource                   "img_UI-Class\\check3_on.bmp"
#resource                   "img_UI-Class\\check3_off.bmp"
// #resource                   "img_UI-Class\\button-move_on.bmp"
#resource                   "img_UI-Class\\button-move_off.bmp"


//+---------------------------------------------------------------------------+
//|   D E F I N E S                                                           |
//+---------------------------------------------------------------------------+
#define TIME_SLEEP          1000
#define SUBWINDOW           0
#define FONT                "Consolas"
#define FONT_SIZE           11
#define FONT_COLOR          clrWhite
#define WND_BACKGROUND      "::img_UI-Class\\background.bmp"
#define WND_OFFSET_LEFT     18
#define WND_ROW_HEIGHT      32
#define BUTTON_ON           "::img_UI-Class\\button_on.bmp"
#define BUTTON_OFF          "::img_UI-Class\\button_off.bmp"
#define BUTTON_WIDTH        95
#define BUTTON_OFFSET_X     30
#define BUTTON_OFFSET_Y     4
#define BUTTON_MIN_ON       "::img_UI-Class\\button-win1_on.bmp"
#define BUTTON_MIN_OFF      "::img_UI-Class\\button-win1_off.bmp"
#define BUTTON_MIN_W        26
#define BUTTON_CL_ON        "::img_UI-Class\\button-win_on.bmp"
#define BUTTON_CL_OFF       "::img_UI-Class\\button-win_off.bmp"
#define BUTTON_CL_W         42
#define BUTTON_MOVE_ON      "::img_UI-Class\\button-move_off.bmp"
#define BUTTON_MOVE_OFF     "::img_UI-Class\\button-move_off.bmp"
#define BUTTON_MOVE_W       (26 + 6)
#define BTN_CHK_ON           "::img_UI-Class\\check3_on.bmp"
#define BTN_CHK_OFF          "::img_UI-Class\\check3_off.bmp"
#define BTN_CHK_WIDTH        68
#define BTN_CHK_OFFSET_X     90
#define BTN_CHK_OFFSET_Y     4


//+---------------------------------------------------------------------------+
//|   C L A S S E S                                                           |
//+---------------------------------------------------------------------------+
class CUIObject
{
protected:
    int         posX, posY;
    string      objName;
public:
    void CUIObject()
    {
        posX = 10; posY = 20;
        objName = StringConcatenate("uiobj_", GetMicrosecondCount());
    }
    void CUIObject(const int x, const int y)
    {
        posX = x; posY = y;
        objName = StringConcatenate("uiobj_", GetMicrosecondCount());
    }
    void CUIObject(const int x, const int y,
                   const string parameters)
    {
        posX = x; posY = y;
        objName = StringConcatenate( StringSubstr(parameters, 0, 5), "_", GetMicrosecondCount() );
    }
    virtual void ~CUIObject()
    {
        ObjectDelete(objName);
    }
    virtual void Clear()
    {
        ObjectDelete(objName);
    }
    virtual void Draw()
    {}
    virtual int OnEvent(const int id, const long &lparam, 
                        const double &dparam, const string &sparam,
                        int &answer)
    {
        answer = 0;
        return answer;
    }
    virtual void Update()
    {}
    virtual void Move(const int delta_x, const int delta_y)
    {
        posX += delta_x;
        posY += delta_y;
    }
};


class CLabel : public CUIObject
{
protected:
    string      text;
    int         textSize;
public:
    void CLabel() : CUIObject()
    {
        text = "Label";
        textSize = FONT_SIZE;
        objName += "lbl";
    }
    void CLabel(const int x, const int y) : CUIObject(x, y)
    {
        text = "Label";
        textSize = FONT_SIZE;
        objName += "lbl";
    }
    void CLabel(const int x, const int y,
                const string parameters,
                const int fontSize = FONT_SIZE) : CUIObject(x, y, parameters)
    {
        text = parameters;
        textSize = fontSize;
        objName += "lbl";
    }
    void Draw()
    {
        if( ObjectFind(objName) >= 0 ) {
            ObjectDelete(objName);
        }
        if( !ObjectCreate(0, objName, OBJ_LABEL, SUBWINDOW, 0, 0) ) {
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
        //--- установим приоритет на получение события нажатия мыши на графике
        ObjectSetInteger(0, objName, OBJPROP_ZORDER, 1);
        //--- установим текст
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        //--- установим шрифт текста
        ObjectSetString(0, objName, OBJPROP_FONT, FONT);
        //--- установим размер шрифта
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, textSize);
        //--- установим цвет
        ObjectSetInteger(0, objName, OBJPROP_COLOR, FONT_COLOR);
    }
    void SetFontSize(const int newSize)
    {
        textSize = newSize;
    }
};


class CButton : public CUIObject
{
private:
    CLabel*     label;
public:
    void CButton() : CUIObject()
    {
        int tempX, tempY, lenTxt;
        lenTxt = StringLen("Button");
        tempX = posX + BUTTON_WIDTH / 2 - lenTxt * 8 / 2;
        tempY = posY + BUTTON_OFFSET_Y;
        label = new CLabel(tempX, tempY, "Button");
        objName += "btn";
    }
    void CButton(const int x, const int y) : CUIObject(x, y)
    {
        int tempX, tempY, lenTxt;
        lenTxt = StringLen("Button");
        tempX = posX + BUTTON_WIDTH / 2 - lenTxt * 8 / 2;
        tempY = posY + BUTTON_OFFSET_Y;
        label = new CLabel(tempX, tempY, "Button");
        objName += "btn";
    }
    void CButton(const int x, const int y,
                 const string parameters) : CUIObject(x, y, parameters)
    {
        int tempX, tempY, lenTxt;
        lenTxt = StringLen(parameters);
        tempX = posX + BUTTON_WIDTH / 2 - lenTxt * 8 / 2;
        tempY = posY + BUTTON_OFFSET_Y;
        label = new CLabel(tempX, tempY, parameters);
        objName += "btn";
    }
    void ~CButton()
    {
        delete label;
        ObjectDelete(objName);
    }
    void Clear()
    {
        label.Clear();
        ObjectDelete(objName);
    }
    void Draw()
    {
        if( ObjectFind(objName) >= 0 ) {
            ObjectDelete(objName);
        }
        if( !ObjectCreate(0 ,objName, OBJ_BITMAP_LABEL, SUBWINDOW, 0, 0) ) {
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        }
        //--- установим картинки для режимов On и Off
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 0, BUTTON_ON) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима On! Код ошибки = ", GetLastError());
        }
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 1, BUTTON_OFF) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима Off! Код ошибки = ", GetLastError());
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0 ,objName, OBJPROP_BACK, false);
        ObjectSetInteger(0 ,objName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTED, false);
        //--- установим приоритет на получение события нажатия мыши на графике
        ObjectSetInteger(0 ,objName, OBJPROP_ZORDER, 3);
        //--- установим, в каком сотоянии находится метка (нажатом или отжатом)
        ObjectSetInteger(0 ,objName, OBJPROP_STATE, false);
        label.Draw();
    }
    int OnEvent(const int id, const long &lparam, 
                const double &dparam, const string &sparam,
                int &answer)
    {
        static bool click = false;
        answer = 0;
        if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK ) {
            if( objName == sparam ) {
                answer = (int)ObjectGetInteger(0, objName, OBJPROP_STATE);
                click = answer;
                EventChartCustom(0, 50, lparam, dparam, sparam);
            }
        } else if( (ENUM_CHART_EVENT)id == CHARTEVENT_CUSTOM+50 ) {
            if( objName == sparam ) {
                if( click ) {
                    ObjectSetInteger(0, objName, OBJPROP_STATE, 0);
                }
            }
        }
        return answer;
    }
    void Update()
    {
        // if( ObjectGetInteger(0, objName, OBJPROP_STATE) > 0 ) {
        //     ObjectSetInteger(0, objName, OBJPROP_STATE, 0);
        //     ChartRedraw();
        // }
    }
    void Move(const int delta_x, const int delta_y)
    {
        posX += delta_x;
        posY += delta_y;
        label.Move(delta_x, delta_y);
    }
};


class CButtonMinimize : public CButton
{
public:
    void CButtonMinimize() : CButton() {}
    void CButtonMinimize(const int x, const int y) : CButton(x, y) {}
    void CButtonMinimize(const int x, const int y,
                         const string parameters) : CButton(x, y, parameters) {}
    void Draw()
    {
        if( ObjectFind(objName) >= 0 ) {
            ObjectDelete(objName);
        }
        if( !ObjectCreate(0 ,objName, OBJ_BITMAP_LABEL, SUBWINDOW, 0, 0) ) {
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        }
        //--- установим картинки для режимов On и Off
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 0, BUTTON_MIN_ON) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима On! Код ошибки = ", GetLastError());
        }
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 1, BUTTON_MIN_OFF) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима Off! Код ошибки = ", GetLastError());
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0 ,objName, OBJPROP_BACK, false);
        ObjectSetInteger(0 ,objName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTED, false);
        //--- установим приоритет на получение события нажатия мыши на графике
        ObjectSetInteger(0 ,objName, OBJPROP_ZORDER, 3);
        //--- установим, в каком сотоянии находится метка (нажатом или отжатом)
        ObjectSetInteger(0 ,objName, OBJPROP_STATE, false);
    }
};


class CButtonClose : public CButton
{
public:
    void CButtonClose() : CButton() {}
    void CButtonClose(const int x, const int y) : CButton(x, y) {}
    void CButtonClose(const int x, const int y,
                      const string parameters) : CButton(x, y, parameters) {}
    void Draw()
    {
        if( ObjectFind(objName) >= 0 ) {
            ObjectDelete(objName);
        }
        if( !ObjectCreate(0 ,objName, OBJ_BITMAP_LABEL, SUBWINDOW, 0, 0) ) {
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        }
        //--- установим картинки для режимов On и Off
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 0, BUTTON_CL_ON) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима On! Код ошибки = ", GetLastError());
        }
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 1, BUTTON_CL_OFF) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима Off! Код ошибки = ", GetLastError());
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0 ,objName, OBJPROP_BACK, false);
        ObjectSetInteger(0 ,objName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTED, false);
        //--- установим приоритет на получение события нажатия мыши на графике
        ObjectSetInteger(0 ,objName, OBJPROP_ZORDER, 3);
        //--- установим, в каком сотоянии находится метка (нажатом или отжатом)
        ObjectSetInteger(0 ,objName, OBJPROP_STATE, false);
    }
};


class CButtonMove : public CButton
{
public:
    void CButtonMove() : CButton() {}
    void CButtonMove(const int x, const int y) : CButton(x, y) {}
    void CButtonMove(const int x, const int y,
                      const string parameters) : CButton(x, y, parameters) {}
    void Draw()
    {
        // if( ObjectFind(objName) >= 0 ) {
        //     ObjectDelete(objName);
        // }
        // if( !ObjectCreate(0 ,objName, OBJ_BITMAP_LABEL, SUBWINDOW, 0, 0) ) {
        //     Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        // }
        // //--- установим картинки для режимов On и Off
        // if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 0, BUTTON_MOVE_ON) ) {
        //     Print(__FUNCTION__, ": не удалось загрузить картинку для режима On! Код ошибки = ", GetLastError());
        // }
        // if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 1, BUTTON_MOVE_OFF) ) {
        //     Print(__FUNCTION__, ": не удалось загрузить картинку для режима Off! Код ошибки = ", GetLastError());
        // }
        // ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX);
        // ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        // ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        // ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        // ObjectSetInteger(0 ,objName, OBJPROP_BACK, false);
        // ObjectSetInteger(0 ,objName, OBJPROP_HIDDEN, true);
        // ObjectSetInteger(0 ,objName, OBJPROP_SELECTABLE, false);
        // ObjectSetInteger(0 ,objName, OBJPROP_SELECTED, false);
        // //--- установим приоритет на получение события нажатия мыши на графике
        // ObjectSetInteger(0 ,objName, OBJPROP_ZORDER, 3);
        // //--- установим, в каком сотоянии находится метка (нажатом или отжатом)
        // ObjectSetInteger(0 ,objName, OBJPROP_STATE, false);
    }
    int OnEvent(const int id, const long &lparam, 
                const double &dparam, const string &sparam,
                int &answer, int &delta_x, int &delta_y)
    {
        static bool move_on = false;
        answer = 0;
        // GOTO
        // if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK ) {
        //     if( move_on ) {
        //         delta_x = (int)lparam - posX;
        //         delta_y = (int)dparam - posY;
        //         move_on = false;
        //         answer = 1;
        //     }
        //     if( objName == sparam ) {
        //         move_on = true;
        //         answer = 1;
        //         // EventChartCustom(0, 51, lparam, dparam, sparam);
        //     }
        // // } else if( (ENUM_CHART_EVENT)id == CHARTEVENT_MOUSE_MOVE ) {
        // //     if( move_on ) {
        // //         delta_x = (int)lparam - posX;
        // //         delta_y = (int)dparam - posY;
        // //         answer = 1;
        // //     }
        // } 
        // // else if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK) {
        // //     if( move_on ) {
        // //         delta_x = (int)lparam - posX;
        // //         delta_y = (int)dparam - posY;
        // //         move_on = false;
        // //         answer = 1;
        // //     }
        // // }
        // Print(move_on, "/", answer, "/", id, "/", lparam, "/", (int)dparam);
        return answer;
    }
};


class CCheckButton : public CUIObject
{
private:
    bool        checked;
    CLabel*     label;
    string GetName(const string params)
    {
        return StringSubstr( params, 0, StringFind(params, ":") );
    }
    bool GetState(const string params)
    {
        int start = StringFind(params, ":") + 1;
        string state = StringSubstr(params, start);
        StringToLower(state);
        if( state == "on" || state == "true" ) {
            return true;
        } else if( state == "off" || state == "false" ) {
            return false;
        }
        return false;
    }
public:
    void CCheckButton() : CUIObject()
    {
        checked = false;
        label = new CLabel(posX, posY+BTN_CHK_OFFSET_Y, "Check button");
        objName += "chkbtn";
    }
    void CCheckButton(const int x, const int y) : CUIObject(x, y)
    {
        checked = false;
        label = new CLabel(posX, posY+BTN_CHK_OFFSET_Y, "Check button");
        objName += "chkbtn";
    }
    void CCheckButton(const int x, const int y,
                      const string parameters) : CUIObject(x, y, parameters)
    {
        checked = GetState(parameters);
        label = new CLabel(posX, posY+BTN_CHK_OFFSET_Y, GetName(parameters));
        objName += "chkbtn";
    }
    void ~CCheckButton()
    {
        delete label;
        ObjectDelete(objName);
    }
    void Clear()
    {
        label.Clear();
        ObjectDelete(objName);
    }
    void Draw()
    {
        if( ObjectFind(objName) >= 0 ) {
            ObjectDelete(objName);
        }
        if( !ObjectCreate(0 ,objName, OBJ_BITMAP_LABEL, SUBWINDOW, 0, 0) ) {
            Print("Function ", __FUNCTION__, " error ", GetLastError());
        }
        //--- установим картинки для режимов On и Off
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 0, BTN_CHK_ON) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима On! Код ошибки = ", GetLastError());
        }
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 1, BTN_CHK_OFF) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима Off! Код ошибки = ", GetLastError());
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX+BTN_CHK_OFFSET_X);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0 ,objName, OBJPROP_BACK, false);
        ObjectSetInteger(0 ,objName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTED, false);
        //--- установим приоритет на получение события нажатия мыши на графике
        ObjectSetInteger(0 ,objName, OBJPROP_ZORDER, 2);
        //--- установим, в каком сотоянии находится метка (нажатом или отжатом)
        ObjectSetInteger(0 ,objName, OBJPROP_STATE, checked);
        label.Draw();
    }
    int OnEvent(const int id, const long &lparam, 
                const double &dparam, const string &sparam,
                int &answer)
    {
        answer = (int)checked;
        if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK ) {
            if( objName == sparam ) {
                checked = ObjectGetInteger(0, objName, OBJPROP_STATE);
                answer = (int)checked;
            }
        }
        return answer;
    }
    void Move(const int delta_x, const int delta_y)
    {
        posX += delta_x;
        posY += delta_y;
        label.Move(delta_x, delta_y);
    }
};


class CWindow : public CUIObject
{
private:
    int                 sizeX, sizeY;
    CUIObject*          items[];
    CButtonMinimize*    minimize;
    CButtonClose*       close;
    CButtonMove*        move;
    bool                minimizeState;
    void CreateButtons()
    {
        int tempX = posX + sizeX - BUTTON_CL_W - 9;
        close = new CButtonClose(tempX, posY);
        minimize = new CButtonMinimize(tempX-BUTTON_MIN_W, posY);
        // move = new CButtonMove(tempX-BUTTON_MIN_W-BUTTON_MOVE_W, posY);
    }
    void DrawWindow()
    {
        if( ObjectFind(objName) >= 0 ) {
            ObjectDelete(objName);
        }
        if( !ObjectCreate(0 ,objName, OBJ_BITMAP_LABEL, SUBWINDOW, 0, 0) ) {
            Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        }
        //--- установим картинки для режимов On и Off
        if( !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 0, WND_BACKGROUND) ||
            !ObjectSetString(0 ,objName, OBJPROP_BMPFILE, 1, WND_BACKGROUND) ) {
            Print(__FUNCTION__, ": не удалось загрузить картинку для режима On/Off! Код ошибки = ",GetLastError());
        }
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, posX);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, posY);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0 ,objName, OBJPROP_BACK, false);
        ObjectSetInteger(0 ,objName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0 ,objName, OBJPROP_SELECTED, false);
        //--- установим приоритет на получение события нажатия мыши на графике
        ObjectSetInteger(0 ,objName, OBJPROP_ZORDER, 0);
        //--- установим область видимости изображения; если значения ширины или высоты
        //--- больше значений ширины и высоты (соответственно) исходного изображения, то
        //--- оно не рисуется; если значения ширины и высоты меньше размеров изображения,
        //--- то рисуется та его часть, которая соответствует этим размерам
        ObjectSetInteger(0 ,objName, OBJPROP_XSIZE, sizeX);
        ObjectSetInteger(0 ,objName, OBJPROP_YSIZE, sizeY);
        minimize.Draw();
        close.Draw();
        // move.Draw();
    }
    void DrawMinimized()
    {
        DrawWindow();
        ObjectSetInteger(0 ,objName, OBJPROP_YSIZE, WND_ROW_HEIGHT);
    }
public:
    void CWindow() : CUIObject()
    {
        sizeX = 150; sizeY = 200;
        objName += "wnd";
        minimizeState = false;
        CreateButtons();
    }
    void CWindow(const int x, const int y,
                 const int width, const int height) : CUIObject(x, y)
    {
        sizeX = width; sizeY = height;
        objName += "wnd";
        minimizeState = false;
        CreateButtons();
    }
    void CWindow(const int x, const int y,
                 const int width, const int height,
                 const string parameters) : CUIObject(x, y, parameters)
    {
        sizeX = width; sizeY = height;
        objName += "wnd";
        minimizeState = false;
        // GOTO
        // label = new CLabel(posX+15, posY+4, parameters);
        CreateButtons();
    }
    void ~CWindow()
    {
        for( int idx = 0; idx < ArraySize(items); idx++ ) {
            delete items[idx];
        }
        delete minimize;
        delete close;
        // delete move;
        ObjectDelete(objName);
    }
    void Clear()
    {
        minimize.Clear();
        close.Clear();
        // move.Clear();
        ObjectDelete(objName);
    }
    void Draw()
    {
        if( minimizeState ) {
            DrawMinimized();
        } else {
            DrawWindow();
        }
        for( int idx = 0; idx < ArraySize(items); idx++ ) {
            items[idx].Draw();
        }
    }
    void SetItems(const string &list[])
    {
        int tempX, tempY;
        CUICreator uiFactory;
        ArrayResize(items, ArraySize(list));
        for( int idx = 0; idx < ArraySize(list); idx++ ) {
            tempX = posX + WND_OFFSET_LEFT;
            tempY = posY + (idx + 1) * WND_ROW_HEIGHT + 3;
            items[idx] = uiFactory.CreateUIItem(tempX, tempY, list[idx]);
        }
        sizeY = WND_ROW_HEIGHT + 6 + ArraySize(list) * WND_ROW_HEIGHT;
    }
    int OnEvent(const int id, const long &lparam, 
                const double &dparam, const string &sparam,
                int &answers[])
    {
        // int deltaX, deltaY, move_on = 0;
        // move.OnEvent(id, lparam, dparam, sparam, move_on, deltaX, deltaY);
        // if( move_on ) {
        //     Move(deltaX, deltaY);
        // }
        ArrayResize(answers, ArraySize(items) + 2);
        minimize.OnEvent(id, lparam, dparam, sparam, answers[0]);
        close.OnEvent(id, lparam, dparam, sparam, answers[1]);
        for( int idx = 0; idx < ArraySize(items); idx++ ) {
            items[idx].OnEvent(id, lparam, dparam, sparam, answers[idx+2]);
        }
        return ArraySize(answers);
    }
    void Update()
    {
        // for( int idx = 0; idx < ArraySize(items); idx++ ) {
        //     items[idx].Update();
        // }
    }
    void Minimize()
    {
        minimizeState = !minimizeState;
        if( minimizeState ) {
            for( int idx = 0; idx < ArraySize(items); idx++ ) {
                items[idx].Clear();
            }
            Clear();
            DrawMinimized();
        } else {
            Clear();
            Draw();
        }
    }
    void Move(const int delta_x, const int delta_y)
    {
        posX += delta_x;
        posY += delta_y;
        minimize.Move(delta_x, delta_y);
        close.Move(delta_x, delta_y);
        move.Move(delta_x, delta_y);
        for( int idx = 0; idx < ArraySize(items); idx++ ) {
            items[idx].Move(delta_x, delta_y);
        }
        this.Draw();
        Print("__Debug__ - Moved");
    }
};


class CUICreator
{
public:
    CUIObject* CreateUIItem(const int x, const int y,
                            const string strItem)
    {
        string obj, parameters;
        int bktOpen, bktClose, length = StringLen(strItem);
        bktOpen = StringFind(strItem, "{");
        bktClose = StringFind(strItem, "}");
        obj = StringSubstr(strItem, 0, bktOpen);
        parameters = StringSubstr(strItem, bktOpen+1, bktClose-bktOpen-1);
        StringToLower(obj);
        if( obj == "button" || obj == "btn" ) {
            return new CButton(x, y, parameters);
        } else if( obj == "label" || obj == "lbl" ) {
            return new CLabel(x, y, parameters);
        } else if( obj == "checkbutton" || obj == "chkbtn" ) {
            return new CCheckButton(x, y, parameters);
        } else if( obj == "list" || obj == "lst" ) {
            return new CLabel(x, y, parameters);
        }
        return NULL;
    }
};


//+---------------------------------------------------------------------------+
//|   F U N C T I O N S                                                       |
//+---------------------------------------------------------------------------+
void DrawArrow(const string name,
               const datetime time, const double price,
               const uchar code, const color clr = clrGray,
               const int width = 1,
               const ENUM_LINE_STYLE style = STYLE_SOLID)
{
    if( ObjectFind(name) >= 0 ) {
        ObjectDelete(name);
    }
    if( !ObjectCreate(name, OBJ_ARROW_BUY, 0, time, price) ) {
        Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        return;
    }
    //--- установим код стрелки
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
    //--- установим способ привязки
    // ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
    //--- установим цвет стрелки
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    //--- установим размер стрелки
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    //--- установим стиль окаймляющей линии
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    //--- отобразим на переднем (false) или заднем (true) плане
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    //--- включим (true) или отключим (false) режим перемещения стрелки мышью
    //--- при создании графического объекта функцией ObjectCreate, по умолчанию объект
    //--- нельзя выделить и перемещать. Внутри же этого метода параметр selection
    //--- по умолчанию равен true, что позволяет выделять и перемещать этот объект
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    //--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
    // ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
    //--- установим приоритет на получение события нажатия мыши на графике
    // ObjectSetInteger(0, name, OBJPROP_ZORDER, z_order);
};

void DrawLine(const string name,
              const datetime time1, const double price1,
              const datetime time2, const double price2,
              const color clr = clrGray,
              const int width = 1,
              const ENUM_LINE_STYLE style = STYLE_SOLID)
{
    if( ObjectFind(name) >= 0 ) {
        ObjectDelete(name);
    }
    if( !ObjectCreate(name, OBJ_TREND, 0, time1, price1, time2, price2) ) {
        Print( "Function ", __FUNCTION__, " error ", GetLastError() );
        return;
    }
    //--- установим цвет линии
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    //--- установим стиль отображения линии
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    //--- установим толщину линии
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    //--- отобразим на переднем (false) или заднем (true) плане
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    //--- включим (true) или отключим (false) режим перемещения линии мышью
    //--- при создании графического объекта функцией ObjectCreate, по умолчанию объект
    //--- нельзя выделить и перемещать. Внутри же этого метода параметр selection
    //--- по умолчанию равен true, что позволяет выделять и перемещать этот объект
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    //--- включим (true) или отключим (false) режим продолжения отображения линии вправо
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
    //--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
    // ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
    //--- установим приоритет на получение события нажатия мыши на графике
    // ObjectSetInteger(0, name, OBJPROP_ZORDER, z_order);
};


