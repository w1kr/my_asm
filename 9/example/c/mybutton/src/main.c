/****************************************************************************

    Модуль main.c

    Пример работы с кнопками.

    Маткин Илья Александрович       23.10.2013

****************************************************************************/


#include <stdio.h>
#include <time.h>
#include <FCNTL.H>
#include <io.h>
#include <malloc.h>
#include <tchar.h>

#include <windows.h>


//----------------------------------------


//----------------------------------------
// глобальные переменные и константы

#define AppWindowName "Application"

// идентификаторы кнопок
#define BT_1        201
#define BT_2        202
#define BT_3        203
#define BT_4        204
#define BT_5        205
#define BT_6        206
#define BT_7        207

HINSTANCE hIns;             // описатель приложения

HFONT	hButtonFont;

HWND hButton1;
HWND hButton2;
HWND hButton3;
HWND hButton4;
HWND hButton5;
HWND hButton6;
HWND hButton7;


//----------------------------------------
// объявление функций

ATOM RegisterClassMainWindow (void);

HWND CreateMainWindow (void);

void CreateControlWindowsMain (HWND hwnd);

LRESULT ProcessingSizeEvent (HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam);

LRESULT CALLBACK WndProcMain (HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam);


//----------------------------------------
// описание функций


//
// Основная функция оконных приложений
//
int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow) {

MSG msg;
    
    hIns = hInstance;

    if (CreateMainWindow() == NULL) {
        return 0;
        }

    // Основной цикл обработки сообщений
    while (GetMessage (&msg, NULL, 0, 0)) {
        TranslateMessage (&msg);
        DispatchMessage (&msg);
        }

    return msg.wParam;
}


//--------------------


//
// Регистрация класса основного окна приложения
//
ATOM RegisterClassMainWindow (void) {

WNDCLASSEX WndClass;

    WndClass.cbSize         = sizeof (WndClass);        // размер структуры класса
    WndClass.style          = 0;
    WndClass.lpfnWndProc    = WndProcMain;              // адрес оконной процедуры класса
    WndClass.cbClsExtra     = 0;                        // размер дополнительной памяти класса
    WndClass.cbWndExtra     = sizeof(void*);            // размер дополнительной памяти окна
    WndClass.hInstance      = hIns;                     // описатель приложения
    WndClass.hIcon          = LoadIcon (hIns, TEXT("MainIcon"));
    WndClass.hCursor        = LoadCursor (NULL, IDC_ARROW); // курсор окна
    WndClass.hbrBackground  = (HBRUSH) GetStockObject (BLACK_BRUSH);
    WndClass.lpszMenuName   = NULL;
    WndClass.lpszClassName  = TEXT(AppWindowName);            // имя класса
    WndClass.hIconSm        = LoadIcon (hIns, TEXT("MainIcon"));

    return RegisterClassEx (&WndClass);
}


//--------------------


//
// Создание основного окна приложения
//
HWND CreateMainWindow (void) {

HWND hwnd;

    RegisterClassMainWindow();

    hwnd = CreateWindowEx (WS_EX_CONTROLPARENT | WS_EX_APPWINDOW,
                          TEXT(AppWindowName),
                          TEXT("Application"),
                          WS_OVERLAPPEDWINDOW,
                          10, 10,
                          650, 600,
                          NULL,                 // описатель родительского окна
                          NULL,                 // описатель главного меню (для главного окна)
                          hIns,NULL);

    if (hwnd == NULL) {
        MessageBox (NULL, TEXT("Ошибка создания основного окна приложения"), TEXT(""), MB_OK);
        return NULL;
        }

    // отображение окна
    ShowWindow (hwnd, SW_SHOWNORMAL);
    UpdateWindow (hwnd);

    return hwnd;
}


//--------------------


//
// Создание управляющих элементов (контролов) главного окна
//
void CreateControlWindowsMain (HWND hwnd) {

    hButton1 = CreateWindow (TEXT("button"), TEXT("button1"),
                            WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
                            100, 100,
                            100, 100,
                            hwnd, (HMENU)BT_1, hIns, NULL);

    return;
}


//--------------------


//
// Функция перерисовки кнопки из родительского окна
//
void ButtonRedrawChildWindow (LPDRAWITEMSTRUCT pdis, HWND hParent) {

HBRUSH  brush;
_TCHAR* childWindowText;
DWORD   childWindowTextLength;
HWND    hChild;
SIZE    childWindowTextPixelsSize;
RECT    rect;

    brush = CreateSolidBrush (RGB(55,55,55));
    FillRect (pdis->hDC, &pdis->rcItem, brush);
    DeleteObject (brush);

    hChild = GetDlgItem (hParent, pdis->CtlID);

    if (pdis->itemState & ODS_SELECTED) {
        brush = CreateSolidBrush (RGB(0,0,0));
        FrameRect (pdis->hDC, &pdis->rcItem, brush);
        CopyRect (&rect, &pdis->rcItem);
        rect.top -= 1;
        rect.left -= 1;
        rect.bottom -= 1;
        rect.right -= 1;
        FrameRect (pdis->hDC, &rect, brush);
        DeleteObject (brush);
        //SetTextColor (pdis->hDC, RGB(200,50,50));
        SetTextColor (pdis->hDC, RGB(170,50,50));
        }
    else {
        brush = CreateSolidBrush (RGB(50,50,50));
        FrameRect (pdis->hDC, &pdis->rcItem, brush);
        DeleteObject (brush);
        if (pdis->itemState & ODS_DISABLED)
            SetTextColor (pdis->hDC, RGB(150,150,150));
        else {
            if (pdis->itemState & ODS_FOCUS)
                //SetTextColor (pdis->hDC, RGB(150,50,50));
                SetTextColor (pdis->hDC, RGB(200,50,50));
            else							
                SetTextColor (pdis->hDC, RGB(255,255,255));
            }
        }

    SetBkColor (pdis->hDC, RGB (55,55,55));
    childWindowTextLength = GetWindowTextLength (hChild);
    childWindowText = (_TCHAR*) malloc ((childWindowTextLength + 1) * sizeof(_TCHAR));
    if (childWindowText) {
        GetWindowText (hChild, childWindowText, childWindowTextLength);

        GetTextExtentPoint32 (pdis->hDC, childWindowText, childWindowTextLength, &childWindowTextPixelsSize);
        TextOut (pdis->hDC, (pdis->rcItem.right - childWindowTextPixelsSize.cx) / 2,
                 (pdis->rcItem.bottom - childWindowTextPixelsSize.cy) / 2, childWindowText, childWindowTextLength);
        free (childWindowText);
        }

    return;
}


//--------------------


//
// Функция обработки сообщений главного окна приложения.
//
LRESULT CALLBACK WndProcMain (HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam) {

LOGFONT	lf;
LPDRAWITEMSTRUCT pdis;

    switch (iMsg) {

        case WM_CREATE:

            CreateControlWindowsMain (hwnd);

            // Создание шрифта
            lf.lfHeight			= 20;
            lf.lfWidth			= 12;
            lf.lfEscapement		= 0;
            lf.lfOrientation	= 0;
            lf.lfWeight			= FW_MEDIUM;
            lf.lfItalic			= 1;
            lf.lfUnderline		= 0;
            lf.lfStrikeOut		= 0;
            lf.lfCharSet		= ANSI_CHARSET;
            lf.lfOutPrecision	= 0;
            lf.lfClipPrecision	= 0;
            lf.lfQuality		= 0;
            lf.lfPitchAndFamily	= 0;
            hButtonFont = CreateFontIndirect (&lf);

            return 0 ;

        case WM_DESTROY:

            PostQuitMessage (0);
            return 0;

        case WM_DRAWITEM:

            pdis = (LPDRAWITEMSTRUCT)lParam;
            switch (pdis->CtlID) {
                case BT_1:
                    SelectObject (pdis->hDC, hButtonFont);
                    ButtonRedrawChildWindow (pdis, hwnd);
                    break;
                default:
                    break;
                }

            return 0;

        // сообщение посылается при нажатии кнопок
        case WM_COMMAND:

            // в параметре wParam идентификатор нажатой кнопки
            switch (LOWORD(wParam)) {

                case BT_1:
                    MessageBox (hwnd, TEXT("Button1 down"), NULL, MB_OK);
                    break;

                default:
                    break;			
                }

			return 0;

        case WM_LBUTTONDOWN:

            SetFocus (hwnd);
            break;
        }

    return DefWindowProc (hwnd, iMsg, wParam, lParam);
}


//--------------------

//--------------------
