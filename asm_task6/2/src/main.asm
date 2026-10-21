;
; Модуль main.asm.
;
; Пример обращения к аргументам функции main.
;
; Маткин Илья Александрович 18.09.2013
;

.686
.model flat, stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\msvcrt.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc

include Strings.mac

.data
glVar db 0, 0, 0, 0

.data?

.const
format db "%s",13,10,0

.code

print_array proc c arg:DWORD

    local i:DWORD			; ebp-4
    local buf[10]:DWORD		; ebp-0x2c
							; ebp - 8 -> &buf[9]
    local var:dword			; ebp-0x30

	mov [glVar], 0
	mov [var], 0
	;mov dword ptr[eax], 0
	mov [i], 0
	mov [buf], 0
	;mov dword ptr[eax][4][ebx], 0
	;mov dword ptr[buf][4][eax][ebx][ecx], 0
	;mov dword ptr[buf][4][eax], 0	; mov dword ptr [buf+4+eax], 0 -> mov dword ptr [ebp-0x2c+4+eax], 0
	mov buf[8], 1	; mov [buf+8], 1	-> mov [ebp-0x2c+8], 1	-> mov [ebp-0x24], 1
	mov byte ptr buf[8], 1
	mov buf[5], 1
	mov byte ptr buf[5], 1
	;buf[1] = 2;
	mov [buf+4], 2
	mov eax, 1
	mov [buf+eax*4], 1


    ;jmp while_cmp
    ;
;while_body:
    ;mov ecx, [i]
    ;mov ebx, [arg]
    ;invoke crt_printf, addr format, dword ptr[ecx + ebx]
;
    ;add [i], 4
    ;
;while_cmp:
    ;mov ecx, [i]
    ;mov ebx, [arg]
    ;cmp dword ptr [ebx + ecx], 0
    ;jne while_body
	
@@:
    mov ecx, [i]
    mov ebx, [arg]
    cmp dword ptr [ebx + ecx], 0
    je @f
    
    mov ecx, [i]
    mov ebx, [arg]
    invoke crt_printf, addr format, dword ptr[ecx + ebx]

    add [i], 4
    jmp @b
@@:


;M1::
M1:
@@:


    ret
    
print_array endp

@@:
M:
jmp @b


main proc c uses esi edi argc:DWORD, argv:DWORD, envp:DWORD

	local var:dword
	
	;mov [eax], 0x01
	mov byte ptr [eax], 1
	mov byte ptr [var], 1
	mov [var], 1
	mov var, 1
	mov [eax], ebx
	
	;mov [var], 41h
;M::
;M1::
M1:
	mov byte ptr [var], 41h
	mov byte ptr [var+1], 42h
	mov byte ptr [var+2], 43h
	mov byte ptr [var+3], 0

	invoke crt_printf, addr format, addr var
	
	invoke print_array, [argv]
	;invoke print_array, [envp]
	
	mov eax, 0
	ret

main endp


end
