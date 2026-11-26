.686
.model flat, stdcall
option casemap:none

include C:\masm32\include\windows.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\gdi32.inc

MAX_GRAPH_POINTS EQU 401       ; 400 line segments
ELLIPSE_POINTS   EQU 361       ; 360 line segments, including closing point
CHILD_W          EQU 60
CHILD_H          EQU 30
WM_START_DRAG    EQU WM_APP+17

SinCallback PROTO
CosCallback PROTO
SquareCallback PROTO

DrawGraph PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
DrawEllipse PROTO :DWORD, :SDWORD, :SDWORD, :SDWORD, :SDWORD
MouseOnEllipse PROTO :SDWORD, :SDWORD, :SDWORD, :SDWORD, :SDWORD, :SDWORD, :DWORD, :DWORD
UpdateLayout PROTO :HWND
MainWndProc PROTO :HWND, :UINT, :WPARAM, :LPARAM
ChildWndProc PROTO :HWND, :UINT, :WPARAM, :LPARAM
WinMain PROTO

.data
MainClassName  db "MainWindow",0
ChildClassName db "ChildWindow",0
AppTitle       db "function graph and ellipse",0
GraphLabel     db "1. Function graph (automatically scaled)",0
EllipseLabel   db "2. Ellipse. Drag the child window around its orbit",0
ChildCaption   db "DRAG ME",0
CreateError    db "Could not create the window.",0

GraphXMin REAL8 -1000.0
GraphXMax REAL8  1000.0
HalfValue REAL8 0.5

.data?
GraphPoints   POINT MAX_GRAPH_POINTS DUP (<>)
GraphValues   REAL8 MAX_GRAPH_POINTS DUP (?)
EllipsePoints POINT ELLIPSE_POINTS DUP (<>)

hInstanceApp DWORD ?
gChild       HWND  ?
gDragging    DWORD ?
gCenterX     SDWORD ?
gCenterY     SDWORD ?
gRadiusX     SDWORD ?
gRadiusY     SDWORD ?

.code

; ============================================================================

SinCallback PROC
    fld QWORD PTR [esp+4]
    fsin
    ret 8
SinCallback ENDP

CosCallback PROC
    fld QWORD PTR [esp+4]
    fcos
    ret 8
CosCallback ENDP

SinCosCallback PROC
    fld QWORD PTR [esp+4]
    fsin

    fld QWORD PTR [esp+4]
    fcos

    faddp st(1), st(0)
    ret 8
SinCosCallback ENDP

SquareCallback PROC
    fld QWORD PTR [esp+4]
    fmul st(0), st(0)
    ret 8
SquareCallback ENDP

CubeCallback PROC
    fld QWORD PTR [esp+4]
    fmul QWORD PTR [esp+4]
    fmul QWORD PTR [esp+4]
    ret 8
CubeCallback ENDP

AbsCallback PROC
    fld QWORD PTR [esp+4]
    fabs
    ret 8
AbsCallback ENDP

; ============================================================================
; DrawGraph(hdc, pRect, pFunction, pXMin, pXMax)
; ============================================================================
DrawGraph PROC USES ebx esi edi, hdc:DWORD, pRect:DWORD, pFunction:DWORD, pXMin:DWORD, pXMax:DWORD
    
	LOCAL xMinVal:QWORD
    LOCAL xMaxVal:QWORD
    LOCAL xStep:QWORD
    LOCAL xVal:QWORD
    LOCAL yVal:QWORD
    LOCAL yMin:QWORD
    LOCAL yMax:QWORD
    LOCAL yRange:QWORD
	
    LOCAL i:DWORD
    LOCAL divNum:DWORD
    LOCAL leftX:DWORD
    LOCAL topY:DWORD
    LOCAL bottomY:DWORD
    LOCAL graphW:DWORD
    LOCAL graphH:DWORD
    LOCAL tempY:DWORD

    mov eax, pRect
    mov ecx, [eax].RECT.left
    mov leftX, ecx
    mov ecx, [eax].RECT.top
    mov topY, ecx
    mov ecx, [eax].RECT.bottom
    mov bottomY, ecx

    mov ecx, [eax].RECT.right
    sub ecx, leftX
    dec ecx
    cmp ecx, 1
    jle dg_done
    mov graphW, ecx

    mov ecx, bottomY
    sub ecx, topY
    dec ecx
    cmp ecx, 1
    jle dg_done
    mov graphH, ecx

    ; Copy caller's X range
    finit
    mov eax, pXMin
    fld QWORD PTR [eax]
    fstp QWORD PTR [xMinVal]
    mov eax, pXMax
    fld QWORD PTR [eax]
    fstp QWORD PTR [xMaxVal]

    fld QWORD PTR [xMaxVal]
    fld QWORD PTR [xMinVal]
    fcomip st(0), st(1)
    fstp st(0)
    je dg_done

    ; xStep = (xMax - xMin) / (MAX_GRAPH_POINTS - 1)
    mov divNum, MAX_GRAPH_POINTS-1
    fld QWORD PTR [xMaxVal]
    fsub QWORD PTR [xMinVal]
    fild DWORD PTR [divNum]
    fdivp st(1), st(0)
    fstp QWORD PTR [xStep]

    ; Pass 1: sample y=f(x), save each value, find minimum and maximum
    mov i, 0

dg_sample_loop:
    fild DWORD PTR [i]
    fmul QWORD PTR [xStep]
    fadd QWORD PTR [xMinVal]
    fstp QWORD PTR [xVal]

    lea esi, xVal
    push DWORD PTR [esi+4]
    push DWORD PTR [esi]
    mov ebx, pFunction
    call ebx
    fstp QWORD PTR [yVal]

    mov eax, i
    shl eax, 3
    fld QWORD PTR [yVal]
    fstp QWORD PTR GraphValues[eax]

    cmp i, 0
    jne dg_compare_min
    fld QWORD PTR [yVal]
    fst QWORD PTR [yMin]
    fstp QWORD PTR [yMax]
    jmp dg_next_sample

dg_compare_min:
    fld QWORD PTR [yVal]
    fld QWORD PTR [yMin]
    fxch st(1)
    fcomip st(0), st(1)             ; compare yVal with yMin
    fstp st(0)
    jae dg_compare_max
    fld QWORD PTR [yVal]
    fstp QWORD PTR [yMin]

dg_compare_max:
    fld QWORD PTR [yVal]
    fld QWORD PTR [yMax]
    fxch st(1)
    fcomip st(0), st(1)             ; compare yVal with yMax
    fstp st(0)
    jbe dg_next_sample
    fld QWORD PTR [yVal]
    fstp QWORD PTR [yMax]

dg_next_sample:
    inc i
    cmp i, MAX_GRAPH_POINTS
    jb dg_sample_loop

    ; yRange = Ymax - Ymin. Avoid division by zero for a constant function
    fld QWORD PTR [yMax]
    fsub QWORD PTR [yMin]
    fstp QWORD PTR [yRange]

    fld QWORD PTR [yRange]
    ftst							; compare with 0
    fstsw ax						; save the FPU state to AX
    sahf							; move the comparison flags to the processor flags register
    fstp st(0)
    jnz dg_have_range				; jump if yRange is not zero

    fld QWORD PTR [yMin]
    fsub QWORD PTR [HalfValue]
    fstp QWORD PTR [yMin]
    fld QWORD PTR [yMax]
    fadd QWORD PTR [HalfValue]
    fstp QWORD PTR [yMax]
	
    fld QWORD PTR [yMax]
    fsub QWORD PTR [yMin]
    fstp QWORD PTR [yRange]

dg_have_range:
    ; Pass 2: X fills the width, Y fills the height (top=max, bottom=min)
    mov i, 0

dg_pixel_loop:
    ; px = left + i*(graphW) / (number of segments)
    mov eax, i
    imul eax, graphW
    cdq
    idiv divNum
    add eax, leftX
    mov edx, eax                 ; preserve X pixel while FPU works

    ; py = bottom - 1 - ((y-yMin) / yRange)*(graphH)
    mov eax, i
    shl eax, 3
    fld QWORD PTR GraphValues[eax]
    fsub QWORD PTR [yMin]
    fdiv QWORD PTR [yRange]
    fimul DWORD PTR [graphH]
    fistp DWORD PTR [tempY]

    mov eax, i
    shl eax, 3
    mov DWORD PTR GraphPoints[eax], edx
    mov ecx, bottomY
    dec ecx
    sub ecx, tempY
    mov DWORD PTR GraphPoints[eax+4], ecx

    inc i
    cmp i, MAX_GRAPH_POINTS
    jb dg_pixel_loop

    invoke Polyline, hdc, ADDR GraphPoints, MAX_GRAPH_POINTS

dg_done:
    ret
DrawGraph ENDP

; ============================================================================
; DrawEllipse(hdc, centerX, centerY, radiusX, radiusY)
; 	x = cx + a*cos(t), y = cy + b*sin(t), t from 0 to 2*pi
; ============================================================================
DrawEllipse PROC USES ebx esi edi, hdc:DWORD, centerX:SDWORD, centerY:SDWORD, radiusX:SDWORD, radiusY:SDWORD
    
	LOCAL i:DWORD
    LOCAL divNum:DWORD
    LOCAL tVal:QWORD
    LOCAL xPixel:DWORD
    LOCAL yPixel:DWORD

    cmp radiusX, 0
    jle de_done
    cmp radiusY, 0
    jle de_done

    mov divNum, ELLIPSE_POINTS-1
    mov i, 0

de_loop:
    finit

    ; t = (i / 360) * 2*pi
    fild DWORD PTR [i]
    fidiv DWORD PTR [divNum]
    fldpi
    fadd st(0), st(0)
    fmulp st(1), st(0)
    fstp QWORD PTR [tVal]

    ; x = centerX + radiusX*cos(t)
    fld QWORD PTR [tVal]
    fcos
    fimul radiusX
    fiadd centerX
    fistp DWORD PTR [xPixel]

    ; y = centerY + radiusY*sin(t)
    fld QWORD PTR [tVal]
    fsin
    fimul radiusY
    fiadd centerY
    fistp DWORD PTR [yPixel]

    mov eax, i
    shl eax, 3
    mov ecx, xPixel
    mov DWORD PTR EllipsePoints[eax], ecx
    mov ecx, yPixel
    mov DWORD PTR EllipsePoints[eax+4], ecx

    inc i
    cmp i, ELLIPSE_POINTS
    jb de_loop

    invoke Polyline, hdc, ADDR EllipsePoints, ELLIPSE_POINTS

de_done:
    ret
DrawEllipse ENDP

; ================================================================================
; MouseOnEllipse(mouseX, mouseY, centerX, centerY, radiusX, radiusY, pOutX, pOutY)
; Returns EAX=1 on success.
; EAX=0 if the cursor equals the centre or a semi-axis is invalid.
; ================================================================================
MouseOnEllipse PROC USES ebx, mouseX:SDWORD, mouseY:SDWORD, centerX:SDWORD, centerY:SDWORD, radiusX:SDWORD, radiusY:SDWORD, pOutX:DWORD, pOutY:DWORD
    
	LOCAL deltaX:SDWORD
    LOCAL deltaY:SDWORD
    LOCAL lambda:QWORD

    cmp radiusX, 0
    jle moe_fail
    cmp radiusY, 0
    jle moe_fail

    mov eax, mouseX
    sub eax, centerX
    mov deltaX, eax
    mov eax, mouseY
    sub eax, centerY
    mov deltaY, eax

    mov eax, deltaX
    or eax, deltaY
    jz moe_fail               		; direction undefined at ellipse centre

    ; q = dx^2/a^2 + dy^2/b^2
	finit
    fild    DWORD PTR [deltaX]
    fmul    st(0), st(0)
    fild    radiusX
    fmul    st(0), st(0)
    fdivp   st(1), st(0)            ; dx^2/a^2

    fild    DWORD PTR [deltaY]
    fmul    st(0), st(0)
    fild    radiusY
    fmul    st(0), st(0)
    fdivp   st(1), st(0)            ; dy^2/b^2
    faddp   st(1), st(0)            ; q

    ; lambda = 1/sqrt(q)
    fsqrt
    fld1
    fdiv    st(0), st(1)
    fstp    QWORD PTR [lambda]
    fstp    st(0)

    ; outX = centerX + lambda*dx
    fild    DWORD PTR [deltaX]
    fmul    QWORD PTR [lambda]
    fiadd   centerX
    mov     eax, pOutX
    fistp   DWORD PTR [eax]

    ; outY = centerY + lambda*dy
    fild    DWORD PTR [deltaY]
    fmul    QWORD PTR [lambda]
    fiadd   centerY
    mov     eax, pOutY
    fistp   DWORD PTR [eax]

    mov     eax, 1
    ret

moe_fail:
    xor     eax, eax
    ret
MouseOnEllipse ENDP

; ==============================================================================
; UpdateLayout(hwnd): calculate the orbit geometry from the current client size.
; ==============================================================================
UpdateLayout PROC USES ebx esi, hWnd:HWND

    LOCAL rc:RECT
    LOCAL childX:SDWORD
    LOCAL childY:SDWORD

    invoke GetClientRect, hWnd, ADDR rc

    mov eax, rc.right
    shr eax, 1
    mov gCenterX, eax

    ; centreY = 3/4 of client height
    mov eax, rc.bottom
    mov ecx, eax
    shr eax, 1
    shr ecx, 2
    add eax, ecx
    mov gCenterY, eax

    ; Semi-axes, leaving margins around the ellipse
    mov eax, rc.right
    shr eax, 1
    sub eax, 64
    cmp eax, 10
    jge ul_rx_ok
    mov eax, 10
ul_rx_ok:
    mov gRadiusX, eax

    mov eax, rc.bottom
    shr eax, 2
    sub eax, 50
    cmp eax, 10
    jge ul_ry_ok
    mov eax, 10
ul_ry_ok:
    mov gRadiusY, eax

    ; Keep the child's centre at the rightmost point after a resize
    cmp gChild, 0
    je ul_done
	
    mov eax, gCenterX
    add eax, gRadiusX
    sub eax, CHILD_W/2
    mov childX, eax
	
    mov eax, gCenterY
    sub eax, CHILD_H/2
    mov childY, eax
	
    invoke  SetWindowPos, gChild, NULL, childX, childY, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
ul_done:
    ret
UpdateLayout ENDP

; ============================================================================
; Main window procedure. Draws the graph + ellipse and handles mouse dragging.
; ============================================================================
MainWndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    LOCAL ps:PAINTSTRUCT
    LOCAL rc:RECT
    LOCAL graphRect:RECT
    LOCAL hdc:DWORD
    LOCAL hPen:DWORD
    LOCAL oldObj:DWORD
    LOCAL mouseX:SDWORD
    LOCAL mouseY:SDWORD
    LOCAL targetX:SDWORD
    LOCAL targetY:SDWORD
    LOCAL childX:SDWORD
    LOCAL childY:SDWORD

    .IF uMsg == WM_CREATE
        mov gDragging, 0
        mov gChild, 0
        invoke UpdateLayout, hWnd

        ; Start the child at the ellipse's rightmost point
        mov eax, gCenterX
        add eax, gRadiusX
        sub eax, CHILD_W/2
        mov childX, eax
        mov eax, gCenterY
        sub eax, CHILD_H/2
        mov childY, eax

        invoke CreateWindowEx, 0, ADDR ChildClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER, childX, childY, CHILD_W, CHILD_H, hWnd, NULL, hInstanceApp, NULL
        .IF eax == 0
            mov eax, -1
            ret
        .ENDIF
        mov gChild, eax
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_SIZE
        invoke UpdateLayout, hWnd
        invoke InvalidateRect, hWnd, NULL, TRUE
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, ADDR ps
        mov hdc, eax
        invoke GetClientRect, hWnd, ADDR rc
        invoke GetStockObject, WHITE_BRUSH
        invoke FillRect, hdc, ADDR rc, eax
        invoke SetBkMode, hdc, TRANSPARENT
        invoke SetTextColor, hdc, 001E1E1Eh

        invoke TextOut, hdc, 12, 10, ADDR GraphLabel, SIZEOF GraphLabel-1

        ; Graph drawing rectangle: nearly full width, upper half of window
        mov graphRect.left, 20
        mov graphRect.top, 34
        mov eax, rc.right
        sub eax, 20
        mov graphRect.right, eax
        mov eax, rc.bottom
        shr eax, 1
        sub eax, 14
        mov graphRect.bottom, eax

        invoke CreatePen, PS_SOLID, 2, 00D26A18h
        mov hPen, eax
        invoke SelectObject, hdc, hPen
        mov oldObj, eax
        invoke DrawGraph, hdc, ADDR graphRect, OFFSET SinCosCallback, ADDR GraphXMin, ADDR GraphXMax	; ======== draw function =========
        invoke SelectObject, hdc, oldObj
        invoke DeleteObject, hPen

        ; Ellipse in lower half of window
        mov eax, rc.bottom
        shr eax, 1
        add eax, 8
        invoke TextOut, hdc, 12, eax, ADDR EllipseLabel, SIZEOF EllipseLabel-1

        invoke CreatePen, PS_SOLID, 2, 003CC878h
        mov hPen, eax
        invoke SelectObject, hdc, hPen
        mov oldObj, eax
        invoke DrawEllipse, hdc, gCenterX, gCenterY, gRadiusX, gRadiusY
        invoke SelectObject, hdc, oldObj
        invoke DeleteObject, hPen

        invoke EndPaint, hWnd, ADDR ps
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_START_DRAG
        mov eax, wParam
        mov gChild, eax
        mov gDragging, 1
        invoke SetCapture, hWnd
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_MOUSEMOVE
        .IF gDragging != 0
            mov eax, lParam
            movsx ecx, ax
            mov mouseX, ecx
            shr eax, 16
            movsx ecx, ax
            mov mouseY, ecx

            invoke MouseOnEllipse, mouseX, mouseY, gCenterX, gCenterY, gRadiusX, gRadiusY, ADDR targetX, ADDR targetY
            .IF eax == 1
                mov eax, targetX
                sub eax, CHILD_W/2
                mov childX, eax
                mov eax, targetY
                sub eax, CHILD_H/2
                mov childY, eax
                invoke SetWindowPos, gChild, NULL, childX, childY, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
            .ENDIF
        .ENDIF
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_LBUTTONUP
        .IF gDragging == 1
            mov gDragging, 0
            invoke ReleaseCapture
        .ENDIF
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_CAPTURECHANGED
        mov gDragging, 0
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_DESTROY
        mov gChild, 0
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .ENDIF

    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
MainWndProc ENDP

; =============================================================================
; Child window procedure. Clicking the child asks the parent to start dragging.
; =============================================================================
ChildWndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL ps:PAINTSTRUCT
    LOCAL rc:RECT

    .IF uMsg == WM_LBUTTONDOWN
        invoke GetParent, hWnd
        invoke SendMessage, eax, WM_START_DRAG, hWnd, 0
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_SETCURSOR
        invoke  LoadCursor, NULL, IDC_SIZEALL
        invoke  SetCursor, eax
        mov eax, TRUE
        ret

    .ELSEIF uMsg == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, ADDR ps
        invoke GetClientRect, hWnd, ADDR rc
        invoke GetSysColorBrush, COLOR_HIGHLIGHT
        invoke FillRect, ps.hdc, ADDR rc, eax
        invoke SetBkMode, ps.hdc, TRANSPARENT
        invoke SetTextColor, ps.hdc, 00FFFFFFh
        invoke DrawText, ps.hdc, ADDR ChildCaption, -1, ADDR rc, DT_CENTER or DT_VCENTER or DT_SINGLELINE
        invoke EndPaint, hWnd, ADDR ps
        xor eax, eax
        ret
    .ENDIF

    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
ChildWndProc ENDP

; ===========================================================================
; WinMain: register two window classes, create the main window, message loop.
; ===========================================================================
WinMain PROC
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hWnd:HWND
	LOCAL hInst:HINSTANCE

    invoke GetModuleHandle, NULL
	mov hInst, eax
	mov hInstanceApp, eax

    ; Register the main window class
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET MainWndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInst
    mov wc.hInstance, eax
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    mov wc.hbrBackground, COLOR_WINDOW+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET MainClassName
    invoke RegisterClassEx, ADDR wc
    .IF eax == 0
        jmp wm_register_error
    .ENDIF

    ; Register the child class
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET ChildWndProc
    mov wc.hbrBackground, COLOR_HIGHLIGHT+1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET ChildClassName
    invoke RegisterClassEx, ADDR wc
    .IF eax == 0
        jmp wm_register_error
    .ENDIF

    invoke CreateWindowEx, 0, ADDR MainClassName, ADDR AppTitle, WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN, CW_USEDEFAULT, CW_USEDEFAULT, 1040, 780, NULL, NULL, hInst, NULL
    mov hWnd, eax
    .IF eax == 0
        jmp wm_register_error
    .ENDIF

    invoke ShowWindow, hWnd, SW_SHOWDEFAULT
    invoke UpdateWindow, hWnd

wm_message_loop:
    invoke GetMessage, ADDR msg, NULL, 0, 0
    cmp eax, -1
    je wm_getmessage_error
    cmp eax, 0
    je wm_message_done
    invoke TranslateMessage, ADDR msg
    invoke DispatchMessage, ADDR msg
    jmp wm_message_loop

wm_message_done:
    mov eax, msg.wParam
    invoke ExitProcess, eax

wm_register_error:
    invoke MessageBox, NULL, ADDR CreateError, ADDR AppTitle, MB_OK or MB_ICONERROR
    mov eax, 1
    invoke ExitProcess, eax

wm_getmessage_error:
    mov eax, 1
    invoke ExitProcess, eax

WinMain ENDP

END WinMain
