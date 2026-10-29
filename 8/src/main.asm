.686
.model flat, stdcall
option casemap:none

include C:\masm32\include\msvcrt.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc

string struct
	str_length 	dword ?
	str_ptr 	dword ?
string ends

.data
text1	 		db "Hello"
struct1 string 	<5, offset text1>

buff			db 256 dup(0)
struct2 string	<0, offset buff>

text2			db "World!"
struct3 string	<6, offset text2>

symbol			db 'l'

text3			db "Worl"
struct4 string	<4, offset text3>

.data?

.const
format 			db "%s", 13, 10, 0
format_symbol 	db "%c", 0
format_last		db 13, 10, 0

.code


; strlen
my_strlen proc c data:ptr string

	mov eax, data
	mov eax, (string ptr[eax]).str_length
	ret

my_strlen endp


; strcpy
my_strcpy proc c uses ebx dst:ptr string, src:ptr string

	local dst_ptr:dword
	local src_ptr:dword
	local src_len:dword

	mov eax, src
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[src_ptr], eax

	mov eax, src
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[src_len], eax

	mov eax, dst
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[dst_ptr], eax

	mov ecx, dword ptr[src_len]
	mov eax, dst
	mov (string ptr[eax]).str_length, ecx

	.WHILE dword ptr[src_len] > 0
		mov ebx, dword ptr[dst_ptr]
		mov eax, dword ptr[src_ptr]
		mov al, byte ptr[eax]
		mov byte ptr[ebx], al

		inc dword ptr[src_ptr]
		inc dword ptr[dst_ptr]
		dec dword ptr[src_len]
	.ENDW

	xor eax, eax
	ret

my_strcpy endp


; strcat
my_strcat proc c dst:ptr string, src:ptr string

	local dst_ptr:dword
	local dst_len:dword
	local src_ptr:dword
	local src_len:dword

	mov eax, dst
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[dst_ptr], eax

	mov eax, dst
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[dst_len], eax

	mov eax, src
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[src_ptr], eax

	mov eax, src
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[src_len], eax

	mov eax, dword ptr[dst_len]
	add dword ptr[dst_ptr], eax

	mov ecx, dword ptr[src_len]

	.WHILE ecx > 0
		mov ebx, dword ptr[dst_ptr]
		mov eax, dword ptr[src_ptr]
		mov al, byte ptr[eax]
		mov byte ptr[ebx], al

		inc dword ptr[src_ptr]
		inc dword ptr[dst_ptr]
		dec ecx
	.ENDW

	mov eax, dword ptr[src_len]
	add dword ptr[dst_len], eax

	mov ecx, dword ptr[dst_len]
	mov eax, dst
	mov (string ptr[eax]).str_length, ecx
	
	xor eax, eax
	ret

my_strcat endp


; strcmp
my_strcmp proc c uses ebx, string1:ptr string, string2:ptr string

	local str1_ptr:dword
	local str1_len:dword
	local str2_ptr:dword
	local str2_len:dword

	mov eax, string1
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[str1_ptr], eax

	mov eax, string1
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[str1_len], eax

	mov eax, string2
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[str2_ptr], eax

	mov eax, string2
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[str2_len], eax

	.WHILE 1
		mov ecx, dword ptr[str1_len]

		.IF (ecx != 0) && (dword ptr[str2_len] == 0)
			mov eax, dword ptr[str1_ptr]
			mov al, byte ptr[eax]
			movzx eax, al
			ret

		.elseif (ecx == 0) && (dword ptr[str2_len] != 0)
			mov eax, dword ptr[str2_ptr]			
			mov al, byte ptr[eax]
			movzx eax, al
			neg eax
			ret

		.elseif (ecx == 0) && (dword ptr[str2_len] == 0)
			xor eax, eax
			ret

		.ENDIF

		mov eax, dword ptr[str1_ptr]
		mov ebx, dword ptr[str2_ptr]
		mov al, byte ptr[eax]
		mov bl, byte ptr[ebx]

		.IF al != bl
			sub al, bl
			movsx eax, al
			ret
		.ENDIF

		inc dword ptr[str1_ptr]
		inc dword ptr[str2_ptr]
		dec dword ptr[str1_len]
		dec dword ptr[str2_len]
	.ENDW

	xor eax, eax
	ret

my_strcmp endp


; strchr
my_strchr proc c data:ptr string, char:dword

	local string_ptr:dword
	local str_len:dword
	
	mov eax, data
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[string_ptr], eax

	mov eax, data
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[str_len], eax


	.WHILE dword ptr[str_len] > 0
		mov eax, dword ptr[string_ptr]
		mov al, byte ptr[eax]
		movzx eax, al

		.IF eax == dword ptr[char]
			mov eax, dword ptr[string_ptr]
			ret
		.ENDIF

		inc dword ptr[string_ptr]
		dec dword ptr[str_len]
	.ENDW

	xor eax, eax
	ret

my_strchr endp


; strncpy
my_strncpy proc dst:ptr string, src:ptr string, n:dword

	local dst_ptr:dword
	local src_ptr:dword

	mov eax, src
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[src_ptr], eax

	mov eax, dst
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[dst_ptr], eax

	mov ecx, dword ptr[n]
	mov eax, dst
	mov (string ptr[eax]).str_length, ecx

	.WHILE dword ptr[n] > 0
		mov ebx, dword ptr[dst_ptr]
		mov eax, dword ptr[src_ptr]
		mov al, byte ptr[eax]
		mov byte ptr[ebx], al

		inc dword ptr[src_ptr]
		inc dword ptr[dst_ptr]
		dec dword ptr[n]
	.ENDW

	xor eax, eax
	ret

my_strncpy endp


; strnlen
my_strnlen proc c data:ptr string, n:dword

	mov eax, data
	mov eax, (string ptr[eax]).str_length
	mov ecx, dword ptr[n]
	
	.IF eax >= ecx
		mov eax, ecx
	.ENDIF

	ret

my_strnlen endp


my_strncat proc c dst:ptr string, src:ptr string, n:dword

	local dst_ptr:dword
	local dst_len:dword
	local src_ptr:dword
	local src_len:dword

	mov eax, dst
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[dst_ptr], eax

	mov eax, dst
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[dst_len], eax

	mov eax, src
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[src_ptr], eax

	mov eax, src
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[src_len], eax

	mov eax, dword ptr[dst_len]
	add dword ptr[dst_ptr], eax

	mov ecx, dword ptr[src_len]

	.WHILE ecx > 0
		mov ebx, dword ptr[dst_ptr]
		mov eax, dword ptr[src_ptr]
		mov al, byte ptr[eax]
		mov byte ptr[ebx], al

		inc dword ptr[src_ptr]
		inc dword ptr[dst_ptr]
		dec ecx
	.ENDW

	mov eax, dword ptr[n]
	add dword ptr[dst_len], eax

	mov ecx, dword ptr[dst_len]
	mov eax, dst
	mov (string ptr[eax]).str_length, ecx
	
	xor eax, eax
	ret

my_strncat endp


; strncmp
my_strncmp proc c uses ebx, string1:ptr string, string2:ptr string, n:dword

	local str1_ptr:dword
	local str1_len:dword
	local str2_ptr:dword
	local str2_len:dword
	local local_n:dword

	mov eax, dword ptr[n]
	mov dword ptr[local_n], eax

	mov eax, string1
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[str1_ptr], eax

	mov eax, string1
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[str1_len], eax

	mov eax, string2
	mov eax, (string ptr[eax]).str_ptr
	mov dword ptr[str2_ptr], eax

	mov eax, string2
	mov eax, (string ptr[eax]).str_length
	mov dword ptr[str2_len], eax

	.WHILE 1
		.IF dword ptr[local_n] == 0
			xor eax, eax
			ret

		.ENDIF

		mov ecx, dword ptr[str1_len]

		.IF (ecx != 0) && (dword ptr[str2_len] == 0)
			mov eax, dword ptr[str1_ptr]
			mov al, byte ptr[eax]
			movzx eax, al
			ret

		.elseif (ecx == 0) && (dword ptr[str2_len] != 0)
			mov eax, dword ptr[str2_ptr]			
			mov al, byte ptr[eax]
			movzx eax, al
			neg eax
			ret

		.elseif (ecx == 0) && (dword ptr[str2_len] == 0)
			xor eax, eax
			ret

		.ENDIF

		mov eax, dword ptr[str1_ptr]
		mov ebx, dword ptr[str2_ptr]
		mov al, byte ptr[eax]
		mov bl, byte ptr[ebx]

		.IF al != bl
			sub al, bl
			movsx eax, al
			ret
		.ENDIF

		inc dword ptr[str1_ptr]
		inc dword ptr[str2_ptr]
		dec dword ptr[str1_len]
		dec dword ptr[str2_len]
		dec dword ptr[local_n]
	.ENDW

	xor eax, eax
	ret

my_strncmp endp


; strstr
my_strstr proc c uses edx data:ptr string, search:ptr string

    local str_ptr:dword
    local str_len:dword
    local search_ptr:dword
    local search_len:dword
    local start_ptr:dword
    local i:dword
    local j:dword

    mov eax, data
    mov eax, (string ptr[eax]).str_ptr
    mov str_ptr, eax

    mov eax, data
    mov eax, (string ptr[eax]).str_length
    mov str_len, eax

    mov eax, search
    mov eax, (string ptr[eax]).str_ptr
    mov search_ptr, eax

    mov eax, search
    mov eax, (string ptr[eax]).str_length
    mov search_len, eax

    mov eax, dword ptr[search_len]
    .IF eax == 0
        mov eax, dword ptr[str_ptr]
        ret
    .ENDIF

    mov eax, dword ptr[search_len]
    .IF eax > dword ptr[str_len]
        xor eax, eax
        ret
    .ENDIF

    mov dword ptr[i], 0

    .WHILE 1
        mov eax, dword ptr[i]
        add eax, dword ptr[search_len]

        mov edx, dword ptr[str_len]
        .IF eax > edx
            .BREAK
        .ENDIF

        mov eax, dword ptr[str_ptr]
        add eax, dword ptr[i]
        mov dword ptr[start_ptr], eax

        mov dword ptr[j], 0

        .WHILE 1

            mov eax, dword ptr[j]
            mov edx, dword ptr[search_len]

            .IF eax >= edx
                .BREAK
            .ENDIF

            mov eax, dword ptr[start_ptr]
            add eax, dword ptr[j]
            mov al, byte ptr[eax]

            mov edx, dword ptr[search_ptr]
            add edx, dword ptr[j]
            mov dl, byte ptr[edx]

            .IF al != dl
                .BREAK
            .ENDIF

            inc dword ptr[j]
        .ENDW

        mov eax, dword ptr[j]
		
        .IF eax == dword ptr[search_len]
            mov eax, dword ptr[start_ptr]
            ret
        .ENDIF

        inc dword ptr[i]
    .ENDW

    xor eax, eax
    ret

my_strstr endp


; print_str
print_str proc c uses ebx, data:ptr string
	
	local str_ptr:dword
	local str_len:dword

	mov eax, data
	mov eax, (string ptr[eax]).str_ptr
	mov str_ptr, eax

	mov eax, data
	mov eax, (string ptr[eax]).str_length
	mov str_len, eax

	.WHILE str_len != 0
		mov eax, dword ptr[str_ptr]
		mov al, byte ptr[eax]
		invoke crt_printf, offset format_symbol, al
		inc str_ptr
		dec str_len
	.ENDW

	invoke crt_printf, offset format_last
	
	xor eax, eax
	ret	

print_str endp


; main 
main proc c argc:DWORD, argv:DWORD, envp:DWORD

	; strcpy
	invoke my_strcpy, offset struct2, offset struct1
;	invoke print_str, offset struct1
;	invoke print_str, offset struct2

	; strcat
	invoke my_strcat, offset struct2, offset struct3
;	invoke print_str, offset struct2

	; strcmp
;	invoke my_strcmp, offset struct1, offset struct3

	; strchr	
;	invoke my_strchr, offset struct1, 61
;	invoke crt_printf, offset format, eax

	; strncpy
;	invoke my_strncpy, offset struct2, offset struct1, 3
;	invoke print_str, offset struct2

	; strnlen
;	invoke my_strnlen, offset struct1, 2

	; strncat
;	invoke my_strncat, offset struct2, offset struct3, 4
;	invoke print_str, offset struct2

	; strncmp
;	invoke my_strncmp, offset struct1, offset struct2, 6

	; strstr
	invoke my_strstr, offset struct2, offset struct4
	invoke crt_printf, offset format, eax


	xor eax, eax
	ret

main endp

end
