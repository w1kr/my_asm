.686
.model flat, stdcall
option casemap:none

includelib C:\masm32\lib\msvcrt.lib
include C:\masm32\include\msvcrt.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\user32.inc


.data
strData 	db "abababa", 0
subStrData 	db "aba", 0

.data?

.const
format 		db "%s", 13, 10, 0
nullText 	db "NULL", 0

ErrorMessageSplitStr 	db "Error: func splitStr", 0


.code

; char ** split (const char *str, const char *substr);
splitStr proc c uses ebx, strPtr:dword, substrPtr:dword

	local currPos:dword
	local foundPos:dword
	local array:dword
	local subStrCount:dword
	local subStrLen:dword
	local partLen:dword
	local countParts:dword
	local index:dword
	local part:dword
	local freeIndex:dword

	; check args
	.if dword ptr[strPtr] == 0
		xor eax, eax
		ret
	.elseif dword ptr[substrPtr] == 0
		xor eax, eax
		ret
	.endif

	; strlen(substrPtr) -> subStrLen
	invoke crt_strlen, dword ptr[substrPtr]
	.if eax == 0
		xor eax, eax
		ret
	.endif

	mov dword ptr[subStrLen], eax

	; count subStrCount
	mov eax, dword ptr[strPtr]
	mov dword ptr[currPos], eax
	mov dword ptr[countParts], 1
	
	.while 1
		invoke crt_strstr, dword ptr[currPos], dword ptr[substrPtr]
		mov dword ptr[foundPos], eax
		
		.if eax == 0
			.break
		.endif
		
		inc dword ptr[countParts]
		mov eax, dword ptr[foundPos]
		add eax, dword ptr[subStrLen]
		mov dword ptr[currPos], eax
	.endw
	
	; malloc for pointer's array
	; (countParts + 1) * 4
	mov eax, dword ptr[countParts]
	inc eax
	shl eax, 2 ; *= 4
	
	invoke crt_malloc, eax
	
	.if eax == 0
		xor eax, eax
		ret
	.endif
	
	mov dword ptr[array], eax
	
	; create substrings
	mov eax, dword ptr[strPtr]
	mov dword ptr[currPos], eax
	mov dword ptr[index], 0
	
	.while 1
		invoke crt_strstr, dword ptr[currPos], dword ptr[substrPtr]
		mov dword ptr[foundPos], eax
		
		.if dword ptr[foundPos] == 0
			invoke crt_strlen, dword ptr[currPos]
			mov dword ptr[partLen], eax
		.else
			mov eax, dword ptr[foundPos]	; partLen = address foundPos - address currPos
			sub eax, dword ptr[currPos]
			mov dword ptr[partLen], eax
		.endif
		
		; malloc for substr 
		mov eax, dword ptr[partLen]
		inc eax		; (partLen + 1) * 1
		
		invoke crt_malloc, eax
		
		mov dword ptr[part], eax
		
		.if dword ptr[part] == 0
			jmp splitStr_cleanup
		.endif
		
		.if dword ptr[partLen] > 0
			invoke crt_memcpy, dword ptr[part], dword ptr[currPos], dword ptr[partLen]
		.endif
		
		mov eax, dword ptr[part]
		mov ecx, dword ptr[partLen]
		mov byte ptr[eax + ecx], 0
		
		mov eax, dword ptr[index]
		shl eax, 2
		
		mov ebx, dword ptr[array]
		mov ecx, dword ptr[part]
		
		mov dword ptr[ebx + eax], ecx
		inc dword ptr[index]
		
		; if substr not found => last part
		.if dword ptr[foundPos] == 0
			mov eax, dword ptr[index]
			shl eax, 2
			
			mov ebx, dword ptr[array]
			mov dword ptr[ebx + eax], 0
			
			mov eax, dword ptr[array]
			ret
		.endif
		
		mov eax, dword ptr[foundPos]
		add eax, dword ptr[subStrLen]
		mov dword ptr[currPos], eax
	
	.endw
	
	; cleanup data	
splitStr_cleanup:
	mov dword ptr[freeIndex], 0
	
splitStr_cleanup_loop:
	mov eax, [freeIndex]
	cmp eax, dword ptr[index]
	jae splitStr_cleanup_done
	
	shl eax, 2
	
	mov ebx, dword ptr[array]
	mov eax, dword ptr[ebx + eax]
	
	invoke crt_free, eax
	
	inc dword ptr[freeIndex]
	jmp splitStr_cleanup_loop
	
splitStr_cleanup_done:
	invoke crt_free, dword ptr[array]
	
	xor eax, eax
	ret
	
splitStr endp

	

main proc c uses ebx, argc:DWORD, argv:DWORD, envp:DWORD

	local array:dword
	local index:dword
	
	invoke splitStr, offset strData, offset subStrData
	
	mov dword ptr[array], eax
	
	.if eax == 0
		invoke crt_printf, offset format, offset ErrorMessageSplitStr
		xor eax, eax
		ret
	.endif
	
	.while 1
		mov eax, dword ptr[index]
		shl eax, 2
		
		mov ebx, dword ptr[array]
		mov ebx, dword ptr[ebx + eax]
		
		.if ebx == 0
			invoke crt_printf, offset format, offset nullText
			.break
		.endif
		
		invoke crt_printf, offset format, ebx		
		invoke crt_free, ebx
		
		inc dword ptr[index]
	.endw

	xor eax, eax
	ret

main endp


end
