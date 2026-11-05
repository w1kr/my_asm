/****************************************************************************

    Модуль main.c

    Пример работы с кнопками.

    Маткин Илья Александрович       23.10.2013
                                    30.10.2026

****************************************************************************/



#include <windows.h>
#include <stdio.h>
#include <time.h>
#include <FCNTL.H>
#include <io.h>
#include <malloc.h>

#include <commctrl.h>


//----------------------------------------


#pragma comment(linker,"\"/manifestdependency:type='win32' \
name='Microsoft.Windows.Common-Controls' version='6.0.0.0' \
processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

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
#define BT_8        208
#define BT_9        209
#define BT_10       210

HINSTANCE hIns;             // описатель приложения

HWND hButton1;
HWND hButton2;
HWND hButton3;
HWND hButton4;
HWND hButton5;
HWND hButton6;
HWND hButton7;
HWND hButton8;
HWND hButton9;
HWND hButton10;

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

    if (CreateMainWindow() == NULL)
        return 0;

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
ATOM RegisterClassMainWindow (void){

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
    WndClass.lpszClassName  = AppWindowName;            // имя класса
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
                          AppWindowName,
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
void CreateControlWindowsMain (HWND hwnd){

    hButton1 = CreateWindow (TEXT("button"), TEXT("button1"),
                            WS_CHILD | WS_VISIBLE,
                            10, 0,
                            100, 30,
                            hwnd, (HMENU)BT_1, hIns, NULL);

    hButton2 = CreateWindow (TEXT("button"), TEXT("button2"),
                            WS_CHILD | WS_VISIBLE | BS_3STATE,
                            10, 50,
                            100, 30,
                            hwnd, (HMENU)BT_2, hIns, NULL);

    hButton3 = CreateWindow (TEXT("button"), TEXT("button3"),
                            WS_CHILD | WS_VISIBLE | BS_AUTO3STATE ,
                            10, 100,
                            100, 30,
                            hwnd, (HMENU)BT_3, hIns, NULL);

    hButton4 = CreateWindow (TEXT("button"), TEXT("button4"),
                            WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
                            10, 150,
                            100, 30,
                            hwnd, (HMENU)BT_4, hIns, NULL);

    hButton5 = CreateWindow (TEXT("button"), TEXT("button5"),
                            WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON ,
                            10, 200,
                            100, 30,
                            hwnd, (HMENU)BT_5, hIns, NULL);

    hButton6 = CreateWindow (TEXT("button"), TEXT("button6"),
                            WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON ,
                            10, 250,
                            100, 30,
                            hwnd, (HMENU)BT_6, hIns, NULL);

    hButton7 = CreateWindow (TEXT("button"), TEXT("button7"),
                            WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON ,
                            10, 300,
                            100, 30,
                            hwnd, (HMENU)BT_7, hIns, NULL);

	hButton8 = CreateWindow (TEXT("button"), TEXT("button8"),
                            WS_CHILD | WS_VISIBLE | BS_SPLITBUTTON,
                            10, 350,
                            100, 30,
                            hwnd, (HMENU)BT_8, hIns, NULL);

    hButton9 = CreateWindow (TEXT("button"), TEXT("button9"),
                            WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX | BS_PUSHLIKE,
                            10, 400,
                            100, 30,
                            hwnd, (HMENU)BT_9, hIns, NULL);

    hButton10 = CreateWindow (TEXT("button"), TEXT("button10"),
                            WS_CHILD | WS_VISIBLE | BS_COMMANDLINK,
                            10, 450,
                            110, 40,
                            hwnd, (HMENU)BT_10, hIns, NULL);

    return;
}


//--------------------



LRESULT ProcessingWmCommand (HWND hwnd, WPARAM wParam) {

DWORD state;

    // в параметре wParam идентификатор нажатой кнопки
    switch (LOWORD (wParam)) {

        case BT_1:
            MessageBox (hwnd, TEXT("Button1 down"), NULL, MB_OK);
            break;

        case BT_2:
            // получаем состояние кнопки
            state = SendMessage (hButton2, BM_GETCHECK, 0, 0);
            if (state == BST_UNCHECKED) {
                MessageBox (hwnd, TEXT("Button2 unchecked"), NULL, MB_OK);
                SetWindowText (hButton2, TEXT("checked"));
                }
            else if (state == BST_CHECKED) {
                MessageBox (hwnd, TEXT("Button2 checked"), NULL, MB_OK);
                SetWindowText (hButton2, TEXT("indeterminate"));
                }
            else if (state == BST_INDETERMINATE) {
                MessageBox (hwnd, TEXT("Button2 indeterminate"), NULL, MB_OK);
                SetWindowText (hButton2, TEXT("unchecked"));
                }
            // изменяем состояние на следующее
            SendMessage (hButton2, BM_SETCHECK, (state + 1) % 3, 0);
            break;

        case BT_3:
            state = SendMessage (hButton3, BM_GETCHECK, 0, 0);
            if (state == BST_UNCHECKED) {
                MessageBox (hwnd, TEXT("Button3 unchecked"), NULL, MB_OK);
                }
            else if (state == BST_CHECKED) {
                MessageBox (hwnd, TEXT("Button3 checked"), NULL, MB_OK);
                }
            else if (state == BST_INDETERMINATE) {
                MessageBox (hwnd, TEXT("Button3 indeterminate"), NULL, MB_OK);
                }
            break;

        case BT_4:
            state = SendMessage (hButton4, BM_GETCHECK, 0, 0);
            if (state == BST_UNCHECKED) {
                MessageBox (hwnd, TEXT("Button4 unchecked"), NULL, MB_OK);
                ShowWindow (hButton3, SW_HIDE);
                }
            else if (state == BST_CHECKED) {
                MessageBox (hwnd, TEXT("Button4 checked"), NULL, MB_OK);
                ShowWindow (hButton3, SW_SHOWNORMAL);
                }
            break;

        case BT_5:
            state = SendMessage (hButton5, BM_GETCHECK, 0, 0);
            if (state == BST_UNCHECKED) {
                MessageBox (hwnd, TEXT("Button5 unchecked"), NULL, MB_OK);
                }
            else if (state == BST_CHECKED) {
                MessageBox (hwnd, TEXT("Button5 checked"), NULL, MB_OK);
                }
            break;

        case BT_6:
            MessageBox (hwnd, TEXT("Button6 checked"), NULL, MB_OK);
            break;

        case BT_7:
            MessageBox (hwnd, TEXT("Button7 checked"), NULL, MB_OK);
            break;

        case BT_8:
            MessageBox (hwnd, TEXT("Button8 down"), NULL, MB_OK);
            break;

        case BT_9:
            state = SendMessage (hButton9, BM_GETCHECK, 0, 0);
            if (state == BST_UNCHECKED) {
                //MessageBox (hwnd, TEXT("Button9 unchecked"), NULL, MB_OK);
                }
            else if (state == BST_CHECKED) {
                //MessageBox (hwnd, TEXT("Button9 checked"), NULL, MB_OK);
                }
            break;

        case BT_10:
            MessageBox (hwnd, TEXT("Button10 down"), NULL, MB_OK);
            break;

        default:
            break;
    }

    return 0;
}



//--------------------



LRESULT ProcessingWmNotify (HWND hwnd, LPARAM lParam) {


    LPNMHDR pNmHdr = (LPNMHDR)lParam;

    if (pNmHdr->idFrom == BT_8 && pNmHdr->code == BCN_DROPDOWN) {

        NMBCDROPDOWN* pDropDown = (NMBCDROPDOWN*)lParam;
        POINT pt = { pDropDown->rcButton.left, pDropDown->rcButton.bottom };
        HMENU hMenu = CreatePopupMenu ();
        HWND hButton = pNmHdr->hwndFrom;

        AppendMenu (hMenu, MF_STRING, 1001, TEXT("Entry1"));
        AppendMenu (hMenu, MF_STRING, 1002, TEXT("Entry2"));

        ClientToScreen (hButton, &pt);

        //Button_SetDropDownState (hButton, TRUE);
        //InvalidateRect(hButton, NULL, FALSE);
        //UpdateWindow (hButton);

        TrackPopupMenu (hMenu, TPM_LEFTALIGN | TPM_TOPALIGN | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, NULL);

        //Button_SetDropDownState (hButton, FALSE);

        DestroyMenu (hMenu);
        }

    return 0;
}



//--------------------


//
// Функция обработки сообщений главного окна приложения.
//
LRESULT CALLBACK WndProcMain (HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam){



    switch (iMsg){

        case WM_CREATE:

            CreateControlWindowsMain(hwnd);
            return 0 ;

        case WM_DESTROY:

            PostQuitMessage(0);
            return 0;

        // сообщение посылается при нажатии кнопок
        case WM_COMMAND:

			return ProcessingWmCommand (hwnd, wParam);

        case WM_NOTIFY:

            return ProcessingWmNotify (hwnd, lParam);

        case WM_LBUTTONDOWN:
            break;
        }

    return DefWindowProc (hwnd, iMsg, wParam, lParam);
}


//--------------------

//--------------------
