.686
.model flat, c

includelib msvcrt.lib
includelib ucrt.lib
includelib legacy_stdio_definitions.lib

arg1 equ 8
arg2 equ 12
arg3 equ 16
arg4 equ 20

var1 equ -4
var2 equ -8
var3 equ -12
var4 equ -16

.data
format_str db "%d", 0Dh, 0Ah, 0
format_sym db "%c", 0

.code

printf proto c :dword, :vararg

; print_str (char *str)
print_str:
    push ebp
    mov ebp, esp
    sub esp, 4

    mov eax, [ebp + 8]
    mov [ebp - 4], eax

start_loop:
    mov eax, [ebp - 4]
    cmp byte ptr [eax], 0
    je end_loop
    
    movzx eax, byte ptr[eax]
    invoke printf, offset format_sym, eax

    inc dword ptr [ebp - 4]
    jmp start_loop
        
end_loop:
    
    mov esp, ebp
    pop ebp
    ret


; ---------------------------------------
; char* strstr(const char *str, const char* searchStr);
;
; 	str 				[ebp + 8] = [ebp + arg1]
;	searchStr			[ebp + 12] = [ebp + arg2]
; 	str_ptr				[ebp - 4] = [ebp + var1]
; 	searchStr_ptr 		[ebp - 8] = [ebp + var2]
;	start_ptr			[ebp - 12] = [ebp + var3]
; ---------------------------------------
my_strstr:
	push ebp
	mov ebp, esp

	sub esp, 3*4

	mov eax, dword ptr[ebp + arg1]
	mov dword ptr[ebp + var1], eax
	mov eax, dword ptr[ebp + arg2]
	mov dword ptr[ebp + var2], eax
	
	mov eax, dword ptr [ebp + var2]
    cmp byte ptr [eax], 0
    je  strstr_found_empty

strstr_loop:
	mov eax, dword ptr[ebp + var1]

	cmp byte ptr[eax], 0
	je strstr_notfound
	
	mov eax, dword ptr[ebp + var1]
	mov dword ptr[ebp + var3], eax
	mov eax, dword ptr [ebp + arg2]
    mov dword ptr [ebp + var2], eax
	
strstr_loop2:
	mov eax, dword ptr [ebp + var3]
    movzx eax, byte ptr [eax]
	mov edx, dword ptr [ebp + var2]
    movzx edx, byte ptr [edx]
	
	cmp edx, 0
	je strstr_found
	
	cmp eax, edx
	jne strstr_end_loop2
	
	inc dword ptr[ebp + var2]
	inc dword ptr[ebp + var3]
	jmp strstr_loop2

strstr_end_loop2:
	inc dword ptr[ebp + var1]
	jmp strstr_loop
	
strstr_found_empty:
    mov eax, dword ptr [ebp + arg1]
	mov dword ptr[ebp + var3], eax
    jmp strstr_end
	
strstr_found:
	mov eax, dword ptr [ebp + var1]
	mov dword ptr[ebp + var3], eax
	jmp strstr_end

strstr_notfound:
	mov dword ptr[ebp + var3], 0

strstr_end:
	mov eax, dword ptr[ebp + var3]
	
	mov esp, ebp
	pop ebp
	ret



; ---------------------------------------------------------------------------
; char * ReplaceStr (const char *text, const char *pattern, const char *rep);
; ---------------------------------------------------------------------------
ReplaceStr:
	sub esp, 4*4
	
	mov eax, dword ptr[esp + 4*4 + arg1]	; text
	mov ebx, dword ptr[esp + 4*4 + arg2]	; pattern
	mov edx, dword ptr[esp + 4*4 + arg3]	; rep
	
	mov dword ptr[esp + 4*4 + var1], eax	; text
	mov dword ptr[esp + 4*4 + var2], ebx	; pattern
	mov dword ptr[esp + 4*4 + var3], edx	; rep
	mov dword ptr[esp + 4*4 + var4], 0		; start_ptr
	
ReplaceStr_loop:
	mov dword ptr[esp + 4*4 + arg2]
	mov dword ptr[esp + 4*4 + var2]

	push dword ptr[esp + 4*4 + var2]
	push dword ptr[esp + 4*4 + var1]
	call my_strstr
	add esp, 2*4
	; eax -> start_ptr (if equ 0 => not found)
	cmp eax, 0
	je ReplaceStr_not_found
	
	mov dword ptr[esp + 4*4 + var1], eax	; start_ptr -> text
	
ReplaceStr_loop2:
	mov edx, dword ptr[esp + 4*4 + var2]
	movzx dl, byte ptr[edx]
	
	cmp dl, 0
	je ReplaceStr_loop
	
	mov eax, dword ptr[esp + 4*4 + var1]
	mov edx
	mov byte ptr[eax], dl
	
	inc dword ptr[esp + 4*4 + var4]
	inc dword ptr[esp + 4*4 + var1]
	
	jmp ReplaceStr_loop2	
	
ReplaceStr_not_found:
	mov eax, dword ptr[esp + 4*4 + arg1]

ReplaceStr_end:
	add esp, 4*4
	ret


main proc
    
    push offset TestStr
    call print_str
    add esp, 4
	
	mov eax, 0
	nop
    ret
main endp

end
