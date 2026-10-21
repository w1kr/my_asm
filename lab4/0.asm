.686
.model flat, c

.data
format_str db "%d", 0Dh, 0Ah, 0

; сегмент кода
.code

printf proto c :dword, :vararg
;AddFun proto c :dword, dword

;
;	arg2
;	arg1
;	ret_addr
;	old_ebp		<- ebp
; 	var			<- ebp - 4	<- esp

AddFun:
    push ebp
    mov ebp, esp
    sub esp, 4

    mov eax, [ebp + 8]
	mov [ebp - 4], eax
	mov eax, [ebp + 12]
    add [ebp - 4], eax
	
	mov eax, [ebp - 4]
    
    mov esp, ebp
    pop ebp
    ret
    ;retn 8

;
;	arg2
;	arg1
;	ret_addr
; 	copy_arg1
;	copy_arg2
;	sum				<- esp
AddFun2:
	sub esp, 12
	
	; arg1 -> copy_arg1
	mov eax, [esp + 16]
	mov [esp + 8], eax
	; arg2 -> copy_arg2
	mov eax, [esp + 20]
	mov [esp + 4], eax
	
	; eax = copy_arg1 + copy_arg2
	mov eax, [esp + 16]
    add eax, [esp + 20]
	mov [esp], eax
	
	mov eax, [esp]

	add esp, 12
    ret
    

main proc

    push 1
    push 2
    call AddFun2
    add esp, 8
	;invoke AddFun, 1, 2
    
    invoke printf, offset format_str, eax

    nop
    ret
main endp

end
