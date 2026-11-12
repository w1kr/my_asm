;
; Модуль main.asm.
;
; Демонстрирует пример перемещения фигур на шахматной доске.
;
; Маткин Илья Александрович 01.12.2013
;

;----------------------------------------

.686
.model flat, stdcall
option casemap:none

;----------------------------------------

include c:\masm32\include\kernel32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc

include Strings.mac
include chess.inc

;----------------------------------------

FILE struct
    _ptr    DWORD       ?
    _cnt    DWORD       ?
    _base   DWORD       ?
    _flag   DWORD       ?
    _file   DWORD       ?
    _charbuf DWORD      ?
    _bufsiz DWORD       ?
    _tmpfname DWORD     ?
FILE ends

__iob_func proto c

_O_TEXT equ 4000h

_IONBF  equ 0004h

;----------------------------------------

; строковая константа с именем окна
AppWindowName equ <"Application">

;----------------------------------------


.data

glChar dd 0

.data?

PUBLIC boardCenters
boardCenters POINT 64 dup(<>)

hIns HINSTANCE ?

HwndMainWindow HWND ?

.const

.code

;----------------------------------------

RegisterClassMainWindow proto

CreateMainWindow proto

WndProcMain proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

ShowFigures proto hwnd:HWND

InstallFigures proto hwnd:HWND

InitBoardCenters proto

FindNearestBoardCenter proto x:dword, y:dword, nearestX:ptr dword, nearestY:ptr dword

;----------------------------------------

__acrt_iob_func proto c :dword

;
; Функция создания консоли
;
CreateExtraConsole proc stdcall

    local stdin:DWORD
    local stdout:DWORD
    local stderr:DWORD

    invoke AllocConsole
    .if eax == 0
        ret
    .endif

    invoke __acrt_iob_func, 0
    mov [stdin], eax
    invoke __acrt_iob_func, 1
    mov [stdout], eax
    invoke __acrt_iob_func, 2
    mov [stderr], eax
    
    invoke SetConsoleTitle, $CTA0("Debug console")
    
    invoke GetStdHandle, STD_INPUT_HANDLE
    invoke crt__open_osfhandle, eax, _O_TEXT
    invoke crt__fdopen, eax, $CTA("r\0")
    invoke crt_memcpy, [stdin], eax, sizeof (FILE)
    
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    invoke crt__open_osfhandle, eax, _O_TEXT
    invoke crt__fdopen, eax, $CTA("w\0")
    invoke crt_memcpy, [stdout], eax, sizeof (FILE)
    
    invoke GetStdHandle, STD_ERROR_HANDLE
    invoke crt__open_osfhandle, eax, _O_TEXT
    invoke crt__fdopen, eax, $CTA("w\0")
    invoke crt_memcpy, [stderr], eax, sizeof (FILE)
    
    invoke crt_setvbuf, [stdout], NULL, _IONBF, 0
    .if eax
        xor eax, eax
        ret
    .endif
    
    invoke crt_setvbuf, [stderr], NULL, _IONBF, 0
    .if eax
        xor eax, eax
        ret
    .endif
    
    mov eax, 1
    ret

CreateExtraConsole endp

;--------------------

WinMain proc stdcall hInstance:HINSTANCE, hPrevInstance:HINSTANCE, szCmdLine:PSTR, iCmdShow:DWORD

    local msg: MSG

    mov eax, [hInstance]
    mov [hIns], eax

    invoke CreateExtraConsole
    invoke crt_printf, $CTA("Hello, World\n\0")

    invoke CreateMainWindow
    mov [HwndMainWindow], eax
    .if [HwndMainWindow] == 0
        xor eax, eax
        ret
    .endif
	
    .while TRUE
        invoke GetMessage, addr msg, NULL, 0, 0
            .break .if eax == 0

        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg

    .endw

    mov eax, [msg].wParam
    ret

WinMain endp

;--------------------

;
; Регистрация класса основного окна приложения
;
RegisterClassMainWindow proc

    local WndClass:WNDCLASSEX	; структура класса

    ; заполняем поля структуры
    mov WndClass.cbSize, sizeof (WNDCLASSEX)	; размер структуры класса
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcMain		; адрес оконной процедуры класса
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, 0
    mov eax, [hIns]
    mov WndClass.hInstance, eax					; описатель приложения
    invoke LoadIcon, hIns, $CTA0("MainIcon")	; иконка приложения
    mov WndClass.hIcon, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    invoke GetStockObject, BLACK_BRUSH			; кисть для фона
    mov WndClass.hbrBackground, eax
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0(AppWindowName)	; имя класса
    invoke LoadIcon, hIns, $CTA0("MainIcon")
    mov WndClass.hIconSm, eax

    invoke RegisterClassEx, addr WndClass
    ret

RegisterClassMainWindow endp

;--------------------

;
; Создание основного окна приложения
;
CreateMainWindow proc

    local hwnd:HWND

    ; регистрация класса основного окна
    invoke RegisterClassMainWindow

    ; создание окна зарегестрированного класса
    invoke CreateWindowEx, 
        WS_EX_CONTROLPARENT or WS_EX_APPWINDOW, ; расширенный стиль окна
        $CTA0(AppWindowName),	; имя зарегестрированного класса окна
        $CTA0("Application"),	; заголовок окна
        WS_OVERLAPPEDWINDOW,	; стиль окна
        10,	    ; X-координата левого верхнего угла
        10,	    ; Y-координата левого верхнего угла
        650,    ; ширина окна
        650,    ; высота окна
        NULL,   ; описатель родительского окна
        NULL,   ; описатель главного меню (для главного окна)
        [hIns], ; идентификатор приложения
        NULL
    mov [hwnd], eax
    
    .if [hwnd] == 0
        invoke MessageBox, NULL, $CTA0("Ошибка создания основного окна приложения"), NULL, MB_OK
        xor eax, eax
        ret
    .endif
        
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    
    mov eax, [hwnd]
    ret

CreateMainWindow endp

;--------------------

;
; Функция обработки сообщений главного окна приложения.
; Вызывается системой при поступлении сообщения для главного окна
; с соответствующими параметрами.
;
; Агрументы:
;
; hwnd      описатель окна, получившего сообщение
; iMsg      идентификатор (номер) сообщения
; wParam    параметр сообщения
; lParam    параметр сообщения
;
WndProcMain proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local pen:HPEN
    local ps:PAINTSTRUCT
	
	local row:dword
	local col:dword
	local rect:RECT
	local lightBrush:HBRUSH
	local darkBrush:HBRUSH
	
	local centerX:dword
	local centerY:dword
	local nearestX:dword
	local nearestY:dword
	local targetX:dword
	local targetY:dword

    .if [iMsg] == WM_CREATE
        ; создание окна
		
		invoke InitBoardCenters
        invoke InstallFigures, [hwnd]
        
        xor eax, eax
        ret
    .elseif [iMsg] == WM_DESTROY
        ; закрытие окна
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .elseif [iMsg] == WM_PAINT
	
		invoke BeginPaint, [hwnd], addr ps
		mov [hdc], eax
		
		invoke CreateSolidBrush, 0F0E4CCh
		mov [lightBrush], eax
		
		invoke CreateSolidBrush, 079563Dh
		mov [darkBrush], eax
		
		mov [row], 0
		.while [row] < 8
			mov [col], 0
			.while [col] < 8
				; left
				mov eax, [col]
				imul eax, CELL_SIZE
				add eax, BOARD_X
				mov [rect].left, eax
				; top
				mov eax, [row]
				imul eax, CELL_SIZE
				add eax, BOARD_Y
				mov [rect].top, eax
				; right
				mov eax, [rect].left
				add eax, CELL_SIZE
				mov [rect].right, eax
				; bottom
				mov eax, [rect].top
				add eax, CELL_SIZE
				mov [rect].bottom, eax
				
				mov eax, [row]
				add eax, [col]
				and eax, 1		; choose color
				
				.if eax == 0
					invoke FillRect, [hdc], addr rect, [lightBrush]
				.else
					invoke FillRect, [hdc], addr rect, [darkBrush]
				.endif
				
				inc [col]
			.endw
			inc [row]
		.endw
		
		invoke DeleteObject, [lightBrush]
		invoke DeleteObject, [darkBrush]
		
		invoke EndPaint, [hwnd], addr ps
		
		xor eax, eax
		ret
		
	.elseif [iMsg] == WM_CHESS_SNAP
		
		mov eax, [lParam]
		mov ecx, [eax]
		mov [centerX], ecx
		mov ecx, [eax + 4]
		mov [centerY], ecx
		
		.if [centerX] >= BOARD_X && [centerX] < BOARD_X + BOARD_SIZE && \
			[centerY] >= BOARD_Y && [centerY] < BOARD_Y + BOARD_SIZE
			
			invoke FindNearestBoardCenter, [centerX], [centerY], addr nearestX, addr nearestY
			
			mov eax, [nearestX]
			sub eax, CHESS_CENTER
			mov [targetX], eax
			
			mov eax, [nearestY]
			sub eax, CHESS_CENTER
			mov [targetY], eax

			invoke MoveWindow, [wParam], [targetX], targetY, CHESS_WIDTH, CHESS_HEIGHT, TRUE
		.endif
		
		xor eax, eax
		ret
		
    .endif
    
    ; Необработанные сообщения направляются в функцию
    ; обработки по умолчанию.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret

WndProcMain endp

;--------------------

ShowFigures proc hwnd:HWND
	
	local i:dword
	local x:dword
	
	invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 125, 125, FIG_CASTLE
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 175, 125, FIG_KNIGHT
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 225, 125, FIG_BISHOP
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 275, 125, FIG_QUEEN
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 325, 125, FIG_KING
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 375, 125, FIG_BISHOP
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 425, 125, FIG_KNIGHT
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, 475, 125, FIG_CASTLE
	
	mov [i], 0
	.while [i] < 8
		mov eax, [i]
		imul eax, 50
		add eax, 125
		mov [x], eax
		
		invoke CreateChessWindow, [hIns], [hwnd], COLOR_BLACK, [x], 175, FIG_PAWN
		inc [i]
	.endw
	
	mov [i], 0
	.while [i] < 8
		mov eax, [i]
		imul eax, 50
		add eax, 125
		mov [x], eax
		
		invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, [x], 425, FIG_PAWN
		inc [i]
	.endw
	
	invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 125, 475, FIG_CASTLE
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 175, 475, FIG_KNIGHT
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 225, 475, FIG_BISHOP
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 275, 475, FIG_QUEEN
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 325, 475, FIG_KING
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 375, 475, FIG_BISHOP
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 425, 475, FIG_KNIGHT
    invoke CreateChessWindow, [hIns], [hwnd], COLOR_WHITE, 475, 475, FIG_CASTLE
	
	ret
    
ShowFigures endp

;--------------------

InstallFigures proc hwnd:HWND

    invoke ShowFigures, [hwnd]

    ret
    
InstallFigures endp

;--------------------

InitBoardCenters proc

    local row:dword
    local col:dword
    local index:dword

    mov [row], 0
    mov [index], 0

    .while [row] < 8

        mov [col], 0

        .while [col] < 8

            mov eax, [col]
            imul eax, CELL_SIZE
            add eax, BOARD_X + CELL_SIZE/2

            mov ecx, [index]
            mov boardCenters[ecx * sizeof(POINT)].x, eax

            mov eax, [row]
            imul eax, CELL_SIZE
            add eax, BOARD_Y + CELL_SIZE/2

            mov ecx, [index]
            mov boardCenters[ecx * sizeof(POINT)].y, eax

            inc [index]
            inc [col]

        .endw

        inc [row]

    .endw

    ret

InitBoardCenters endp

;--------------------

FindNearestBoardCenter proc uses esi x:dword, y:dword, nearestX:ptr dword, nearestY:ptr dword

	local i:dword
	local distX:dword
	local distY:dword
	local distance:dword
	local minDistance:dword
	local bestX:dword
	local bestY:dword
	
	mov [minDistance], 7FFFFFFFh

	mov [i], 0
	.while [i] < 64
		mov esi, [i]
		
		mov eax, [x]
		sub eax, boardCenters[esi * sizeof(POINT)].x
		imul eax, eax
		mov [distX], eax
		
		mov eax, [y]
		sub eax, boardCenters[esi * sizeof(POINT)].y
		imul eax, eax
		mov [distY], eax
		
		mov eax, [distX]
		add eax, [distY]
		mov [distance], eax
		
		.if eax < [minDistance]
			mov eax, [distance]
			mov [minDistance], eax
			
			mov eax, boardCenters[esi * sizeof(POINT)].x
			mov [bestX], eax
			mov eax, boardCenters[esi * sizeof(POINT)].y
			mov [bestY], eax
		.endif
		inc [i]
	.endw
	
	mov ecx, [nearestX]
	mov eax, [bestX]
	mov [ecx], eax
	
	mov ecx, [nearestY]
	mov eax, [bestY]
	mov [ecx], eax
	
	ret

FindNearestBoardCenter endp

;--------------------
;--------------------

end
