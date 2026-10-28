.686
.model flat, stdcall
option casemap:none

includelib C:\masm32\lib\msvcrt.lib
include C:\masm32\include\msvcrt.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc


.data
my_str1 			db "Hello"
my_struct1 string 	<5, offset text>
my_struct2 string

.data?

.const
format 		db "%s", 13, 10, 0


.code

string struct
	str_length 	dword ?
	str_ptr 	dword ?
string ends


; strlen
my_strlen proc c struct_arg:ptr string

	mov eax, (string ptr[struct_arg]).str_length
	ret

my_strlen endp


; strcpy
my_strcpy proc c dst_struct:ptr string, src_struct:ptr string

	local dst_ptr:dword
	local src_ptr:dword
	local src_len:dword

	mov eax, (string ptr[src_struct]).str_ptr
	mov src_ptr, eax
	mov eax, (string ptr[src_struct]).str_length
	mov src_len, eax

	mov eax, src_len
	invoke crt_malloc, eax

	.IF eax == 0
		mov eax, 1
		ret
	.ENDIF

	mov dst_ptr, eax

	mov eax, dst_struct
	mov (string ptr[eax]).str_length, src_len
	mov (string ptr[eax]).str_ptr, dst_ptr

	.WHILE src_len != 0
		mov al, byte ptr[src_ptr]
		mov byte ptr[dst_ptr], al
		inc src_ptr
		inc dst_ptr
		dec src_len
	.ENDW

	xor eax, eax
	ret

my_strcpy endp


; main 
main proc c argc:DWORD, argv:DWORD, envp:DWORD

	

	xor eax, eax
	ret

main endp


end
