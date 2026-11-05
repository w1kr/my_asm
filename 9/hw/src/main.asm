; ---------------------------------------------------------

.686
.model flat, stdcall
option casemap:none

include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\gdi32.inc
include C:\masm32\include\windows.inc
include C:\masm32\include\msvcrt.inc

RegisterClassExW PROTO :DWORD
CreateWindowExW PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DefWindowProcW PROTO :DWORD,:DWORD,:DWORD,:DWORD
GetMessageW PROTO :DWORD,:DWORD,:DWORD,:DWORD
DispatchMessageW PROTO :DWORD
LoadCursorW PROTO :DWORD,:DWORD

TranslateMessage PROTO :DWORD
ShowWindow PROTO :DWORD,:DWORD
UpdateWindow PROTO :DWORD
SetFocus PROTO :DWORD
PostQuitMessage PROTO :DWORD
InvalidateRect PROTO :DWORD,:DWORD,:DWORD
BeginPaint PROTO :DWORD,:DWORD
EndPaint PROTO :DWORD,:DWORD
GetClientRect PROTO :DWORD,:DWORD

GetStockObject PROTO :DWORD
SelectObject PROTO :DWORD,:DWORD
CreateFontW PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DeleteObject PROTO :DWORD
GetTextMetricsW PROTO :DWORD,:DWORD
SetTextColor PROTO :DWORD,:DWORD
SetBkMode PROTO :DWORD,:DWORD
TextOutW PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

; Maximum retained input and temporary screen dimensions
APP_INPUT_CAPACITY EQU 16384          ; UTF-16 code units
APP_MAX_ROWS  EQU 128
APP_MAX_COLS  EQU 256
APP_WINDOW_WIDTH  EQU 300
APP_WINDOW_HEIGHT EQU 300

; ------------------------------------------------------------

.data
szClassNameW dw 'U','n','i','c','o','d','e','T','e','x','t','W','i','n',0
szTitleW     dw 'U','n','i','c','o','d','e',' ','t','e','x','t',0
szFontNameW  dw 'C','o','n','s','o','l','a','s',0

.data?
hIns             HINSTANCE ?
HwndMainWindow   HWND      ?
hAppFont         HFONT     ?

; Persistent text history. Each element is one UTF-16 code unit.
InputBuffer      dw APP_INPUT_CAPACITY dup(?)
InputLen         dd ?

; Temporary visible screen, rebuilt from InputBuffer on WM_PAINT.
RenderBuffer     dw (APP_MAX_ROWS * APP_MAX_COLS) dup(?)
RowLen           dd APP_MAX_ROWS dup(?)

gRows            dd ?	; number of lines that fit in the window
gCols            dd ?	; number of UTF-16 code units allocated for the width of a string
gCellW           dd ?	; average character width in pixels
gLineH           dd ?	; line height in pixels
gFirstRow        dd ?	; index of the row displayed first
gCurRow          dd ?	; current line
gCurCol          dd ?	; current column (position in line)

tmBuf            db 64 dup(?)     ; for TEXTMETRICW

; ------------------------------------------------------------

RegisterClassMainWindow proto
CreateMainWindow proto
AppendUtf16 proto codeUnit:DWORD
DropOldestInput proto
AdvanceLine proto
RebuildScreen proto
WndProcMain proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

; ------------------------------------------------------------

.code

; ------------------------------------------------------------

WinMain proc stdcall hInstance:HINSTANCE, hPrevInstance:HINSTANCE, szCmdLine:PSTR, iCmdShow:DWORD

    local msg:MSG

    mov eax, [hInstance]
    mov [hIns], eax

    invoke CreateMainWindow
    mov [HwndMainWindow], eax
    .if [HwndMainWindow] == 0
        xor eax, eax
        ret
    .endif

    .while TRUE
        invoke GetMessageW, addr msg, NULL, 0, 0
        .break .if eax <= 0

        invoke TranslateMessage, addr msg
        invoke DispatchMessageW, addr msg
    .endw

    mov eax, [msg].wParam
    ret
WinMain endp

; ------------------------------------------------------------

RegisterClassMainWindow proc

    local wc:WNDCLASSEX

    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WndProcMain
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, [hIns]
    mov wc.hInstance, eax
    mov wc.hIcon, 0
    invoke LoadCursorW, NULL, 32512       ; IDC_ARROW
    mov wc.hCursor, eax
    invoke GetStockObject, BLACK_BRUSH
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, offset szClassNameW
    mov wc.hIconSm, 0

    invoke RegisterClassExW, addr wc
    ret
RegisterClassMainWindow endp

; ------------------------------------------------------------

CreateMainWindow proc
    
	local hwnd:HWND

    invoke RegisterClassMainWindow
    .if eax == 0
        xor eax, eax
        ret
    .endif

    invoke CreateWindowExW, 
        WS_EX_APPWINDOW,
        offset szClassNameW,
        offset szTitleW,
        WS_OVERLAPPEDWINDOW,
        100, 100,
        APP_WINDOW_WIDTH, APP_WINDOW_HEIGHT,
        NULL,
        NULL,
        [hIns],
        NULL

    mov [hwnd], eax
    .if [hwnd] == 0
        xor eax, eax
        ret
    .endif

    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    invoke SetFocus, hwnd

    mov eax, [hwnd]
    ret
CreateMainWindow endp

; ------------------------------------------------------------

AppendUtf16 proc uses ecx edx, codeUnit:DWORD
    
	local tempChar:DWORD
	
    mov eax, [codeUnit]

    ; Backspace
    .if eax == 8
        mov ecx, [InputLen]
        .if ecx == 0
            ret
        .endif

        dec ecx
        movzx edx, word ptr [InputBuffer + ecx*2]

        .if edx >= 0DC00h && edx <= 0DFFFh
            .if ecx > 0
                dec ecx
                movzx edx, word ptr [InputBuffer + ecx*2]
                .if edx >= 0D800h && edx <= 0DBFFh
                    mov [InputLen], ecx
                    ret
                .else
                    inc ecx
                .endif
            .endif
        .endif

        mov [InputLen], ecx
        ret
    .endif

    ; Enter
    .if eax == 0Dh
        mov eax, 0Ah
    .endif

    ; ignore control characters
    .if eax < 20h
        .if eax != 0Ah
            ret
        .endif
    .endif

    ; mov [tempChar], eax
	
    ; mov eax, [tempChar]
    mov ecx, [InputLen]
	
	.if ecx >= APP_INPUT_CAPACITY
		ret
	.endif
	
    mov dx, ax
    mov [InputBuffer + ecx*2], dx
	
    inc ecx
    mov [InputLen], ecx
	ret
AppendUtf16 endp

; ------------------------------------------------------------

AdvanceLine proc uses eax ecx edx edi
    
	mov [gCurCol], 0
    mov eax, [gCurRow]
    inc eax
    cmp eax, [gRows]
    jb AL_AdvanceRow

    mov eax, [gFirstRow]
    inc eax
    cmp eax, [gRows]
    jb AL_SaveFirst
    xor eax, eax
	
AL_SaveFirst:
    mov [gFirstRow], eax
    mov eax, [gRows]
    dec eax
    mov [gCurRow], eax

    ; Clear the new bottom row
    mov edx, [gFirstRow]
    add edx, [gCurRow]
    cmp edx, [gRows]
    jb AL_ClearReady
    sub edx, [gRows]
	
AL_ClearReady:
    mov dword ptr [RowLen + edx*4], 0
    imul edx, APP_MAX_COLS
    shl edx, 1
    lea edi, RenderBuffer
    add edi, edx
    mov ecx, APP_MAX_COLS
    xor eax, eax
    cld
    rep stosw
    ret

AL_AdvanceRow:
    mov [gCurRow], eax
    ret
AdvanceLine endp

; ------------------------------------------------------------

RebuildScreen proc uses ebx esi edi

    local units:DWORD
    local phys:DWORD
    local skipUnit:DWORD

    cld
    lea edi, RenderBuffer
    mov ecx, APP_MAX_ROWS * APP_MAX_COLS
    xor eax, eax
    rep stosw

    lea edi, RowLen
    mov ecx, APP_MAX_ROWS
    xor eax, eax
    rep stosd

    mov [gFirstRow], 0
    mov [gCurRow], 0
    mov [gCurCol], 0

    xor ebx, ebx

    .while ebx < [InputLen]
        movzx esi, word ptr [InputBuffer + ebx*2]

        .if esi == 000Ah
            inc ebx
            invoke AdvanceLine
        .else
            mov [units], 1
            mov [skipUnit], 0

            .if esi >= 0D800h && esi <= 0DBFFh
                mov eax, ebx
                inc eax

                .if eax < [InputLen]
                    movzx eax, word ptr [InputBuffer + eax*2]
					
                    .if eax >= 0DC00h && eax <= 0DFFFh
                        mov [units], 2
                    .else
                        mov [skipUnit], 1
                    .endif
					
                .else
                    mov [skipUnit], 1
                .endif
				
            .elseif esi >= 0DC00h && esi <= 0DFFFh
                mov [skipUnit], 1
            .endif

            .if [skipUnit] == 0
                mov eax, [gCurCol]
                add eax, [units]

                .if eax > [gCols]
                    invoke AdvanceLine
				.endif
				
                mov eax, [gFirstRow]
                add eax, [gCurRow]

                .if eax >= [gRows]
                    sub eax, [gRows]
                .endif

                mov [phys], eax
                imul eax, APP_MAX_COLS
                add eax, [gCurCol]
                lea edi, RenderBuffer
                mov [edi + eax*2], si		; SI contains the current UTF-16 code unit

                .if [units] == 2
                    movzx edx, word ptr [InputBuffer + ebx*2 + 2]
                    mov [edi + eax*2 + 2], dx
                .endif

                mov edx, [phys]
                mov eax, [gCurCol]
                add eax, [units]
                mov [RowLen + edx*4], eax

                mov eax, [units]
                add [gCurCol], eax
                add ebx, eax

			.else
				inc ebx
			.endif
		.endif
    .endw

    ret
RebuildScreen endp

; ------------------------------------------------------------

WndProcMain proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM
    local ps:PAINTSTRUCT
    local rc:RECT
    local hdc:HDC
    local hFont:DWORD
    local hOldFont:DWORD
    local row:DWORD
    local phys:DWORD
    local yPos:DWORD
    local textLen:DWORD
    local pLine:DWORD
    local unicodeTemp:DWORD

    .if [iMsg] == WM_CREATE
        mov [InputLen], 0
        invoke CreateFontW, -18, 0, 0, 0, 
				FW_NORMAL, 
				0, 0, 0, 
				DEFAULT_CHARSET, 
				OUT_DEFAULT_PRECIS, 
				CLIP_DEFAULT_PRECIS, 
				CLEARTYPE_QUALITY, 
				(FIXED_PITCH or FF_MODERN), 
				offset szFontNameW
				
        mov [hAppFont], eax
        xor eax, eax
        ret

    .elseif [iMsg] == WM_DESTROY
        .if [hAppFont] != 0
            invoke DeleteObject, [hAppFont]
            mov [hAppFont], 0
        .endif
		
        invoke PostQuitMessage, 0
        xor eax, eax
        ret

    .elseif [iMsg] == WM_CHAR
        mov eax, [wParam]
        and eax, 0FFFFh
        invoke AppendUtf16, eax
        invoke InvalidateRect, hwnd, NULL, TRUE
        xor eax, eax
        ret

    .elseif [iMsg] == 0109h				; WM_UNICHAR (UTF-32)
        mov eax, [wParam]

        .if eax == 0FFFFh
            mov eax, TRUE				; UNICODE_NOCHAR = FFFFh
            ret
        .endif

        .if eax <= 0FFFFh
            .if eax >= 0D800h && eax <= 0DFFFh
                xor eax, eax
                ret
            .endif
            invoke AppendUtf16, eax

        .elseif eax <= 10FFFFh
            sub eax, 10000h
            mov [unicodeTemp], eax

            mov edx, eax
            shr edx, 10
            add edx, 0D800h
            invoke AppendUtf16, edx

            mov eax, [unicodeTemp]
            and eax, 03FFh
            add eax, 0DC00h
            invoke AppendUtf16, eax
        .else
            xor eax, eax
            ret
        .endif

        invoke InvalidateRect, hwnd, NULL, TRUE
        xor eax, eax
        ret

    .elseif [iMsg] == WM_SIZE
        invoke InvalidateRect, hwnd, NULL, TRUE
        xor eax, eax
        ret

    .elseif [iMsg] == WM_LBUTTONDOWN
        invoke SetFocus, hwnd
        xor eax, eax
        ret

    .elseif [iMsg] == WM_PAINT
        invoke BeginPaint, hwnd, addr ps
        mov [hdc], eax

        invoke GetClientRect, hwnd, addr rc

        mov eax, [hAppFont]
        .if eax == 0
            invoke GetStockObject, 16       ; SYSTEM_FIXED_FONT fallback
        .endif
        mov [hFont], eax
        invoke SelectObject, [hdc], [hFont]
        mov [hOldFont], eax

        mov dword ptr [tmBuf+0], 16			; tmHeight
        mov dword ptr [tmBuf+16], 0			; tmExternalLeading 
        mov dword ptr [tmBuf+20], 8			; tmAveCharWidth
        invoke GetTextMetricsW, [hdc], addr tmBuf

        mov eax, dword ptr [tmBuf+20]
        .if eax <= 0
            mov eax, 8
        .endif
        mov [gCellW], eax

        mov eax, dword ptr [tmBuf+0]
        add eax, dword ptr [tmBuf+16]
        .if eax <= 0
            mov eax, 16
        .endif
        mov [gLineH], eax

        mov eax, rc.right
        sub eax, rc.left
        xor edx, edx
        mov ecx, [gCellW]
        div ecx
        .if eax < 1
            mov eax, 1
        .endif
        .if eax > APP_MAX_COLS
            mov eax, APP_MAX_COLS
        .endif
        mov [gCols], eax

        mov eax, rc.bottom
        sub eax, rc.top
        xor edx, edx
        mov ecx, [gLineH]
        div ecx
        .if eax < 1
            mov eax, 1
        .endif
        .if eax > APP_MAX_ROWS
            mov eax, APP_MAX_ROWS
        .endif
        mov [gRows], eax

        invoke RebuildScreen

        invoke SetTextColor, [hdc], 00FFFFFFh	; WHITE
        invoke SetBkMode, [hdc], 1            	; TRANSPARENT

        mov [row], 0
        mov [yPos], 0

PaintRowLoop:
        mov eax, [row]
        cmp eax, [gRows]
        jae PaintRowsDone

        mov eax, [gFirstRow]
        add eax, [row]
        cmp eax, [gRows]
        jb PaintPhysReady
        sub eax, [gRows]
PaintPhysReady:
        mov [phys], eax

        mov edx, eax
        mov eax, [RowLen + edx*4]
        mov [textLen], eax

        .if [textLen] > 0
            mov eax, [phys]
            imul eax, APP_MAX_COLS
            lea edx, RenderBuffer
            lea edx, [edx + eax*2]
            mov [pLine], edx
            invoke TextOutW, [hdc], 0, [yPos], [pLine], [textLen]
        .endif

        inc [row]
        mov eax, [gLineH]
        add [yPos], eax
        jmp PaintRowLoop

PaintRowsDone:
        ; restore the font selected before painting
        invoke SelectObject, [hdc], [hOldFont]
        invoke EndPaint, hwnd, addr ps
        xor eax, eax
        ret
    .endif

    invoke DefWindowProcW, hwnd, iMsg, wParam, lParam
    ret
WndProcMain endp

end
