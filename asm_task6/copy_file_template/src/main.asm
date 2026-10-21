;
; Модуль main.asm.
;
; Шаблон проекта.
;
; Маткин Илья Александрович 15.09.2015
;

.686
.model flat, stdcall
option casemap:none

include c:\masm32\include\msvcrt.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc

include Strings.mac


fopen proto c :dword, :dword
printf proto c :VARARG

_open proto c :dword, :dword, :dword
_read proto c :dword, :dword, :dword

.data


.data?

.const
format_read db "r", 0


.code


copy proc fileName:dword

	local buf[10]:byte
	local fd:dword
	
	invoke printf, [fileName]
	;push dword ptr [ebp + 8]
	;call printf
	;add esp, 4
	
	invoke fopen, dword ptr [fileName], addr format_read
	;push offset format_read
	;push dword ptr [ebp + 8]
	;call fopen
	;add esp, 8
	mov [fd], eax
	
	invoke _open, dword ptr [fileName], 0, 0
	mov [fd], eax
	invoke _read, [fd], addr buf, sizeof buf

	ret

copy endp


main proc c argc:DWORD, argv:DWORD, envp:DWORD

	mov eax, argv
	push dword ptr [eax + 4]
	call copy
	add esp, 4
	
	mov eax, 0
	ret

main endp


end
