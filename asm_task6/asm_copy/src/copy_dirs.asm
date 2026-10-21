.686
.model flat, stdcall

option casemap:none

include c:\masm32\include\msvcrt.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\windows.inc

fopen  proto c :dword, :dword
fread  proto c :dword, :dword, :dword, :dword
fwrite proto c :dword, :dword, :dword, :dword
fclose proto c :dword
ferror proto c :dword



.data
usageText 		db "Usage: copy_dirs.exe <source_dir> <destination_dir>", 13, 10, 0
sourceText 		db "Source: %s", 13, 10, 0
destText 		db "Destination: %s", 13, 10, 0
copyDoneText  	db "Copy completed.", 13, 10, 0
copyErrorText 	db "Copy failed.", 13, 10, 0
listErrorText	db "Directory enumeration failed.", 13, 10, 0
dirErrorText 	db "Failed to create destination directory.", 13, 10, 0
sourceInvalidText db "Source path is invalid or is not a directory.", 13, 10, 0
pathResolveErrorText db "Failed to resolve full paths.", 13, 10, 0
pathOverlapErrorText db "Destination must not be source or inside source.", 13, 10, 0

readMode  		db "rb", 0
writeMode 		db "wb", 0

findPatternFormat 	db "%s\*", 0
dirItemFormat 		db "[DIR] %s", 13, 10, 0
fileItemFormat		db "[FILE] %s", 13, 10, 0
fullPathFormat 		db "%s\%s", 0

.code


CopyFileAsm proc c dstFileName:dword, srcFileName:dword

	local src:dword
	local dst:dword
	local buf[512]:byte
	local bytesRead:dword
	
	invoke fopen, srcFileName, addr readMode
	mov src, eax
	test eax, eax
	jz CF_OpenSourceError
	
	invoke fopen, dstFileName, addr writeMode
	mov dst, eax
	test eax, eax
	jz CF_OpenDestError

CF_ReadLoop:
	invoke fread, addr buf, 1, sizeof buf, src
	mov bytesRead, eax
	test eax, eax
	jz CF_CheckReadError
	
	invoke fwrite, addr buf, 1, bytesRead, dst
	cmp eax, bytesRead
	jne CF_CloseBothError
	
	jmp CF_ReadLoop
	
CF_CheckReadError:
	invoke ferror, src
	test eax, eax
	jnz CF_CloseBothError
	
	invoke fclose, dst
	test eax, eax
	jnz CF_CloseSourceError
	
	invoke fclose, src
	test eax, eax
	jnz CF_ReturnError
	
	mov eax, 1
	ret
	
CF_CloseBothError:
	invoke fclose, dst
	invoke fclose, src

CF_ReturnError:
	xor eax, eax
	ret

CF_CloseSourceError:
	invoke fclose, src
	xor eax, eax
	ret
	

CF_OpenDestError:
	invoke fclose, src
	
CF_OpenSourceError:
	xor eax, eax
	ret
	
CopyFileAsm endp



JoinPath proc c outPath:dword, dirName:dword, fileName:dword
	invoke crt_sprintf, outPath, addr fullPathFormat, dirName, fileName
	ret
JoinPath endp



ListDirectory proc c srcDir:dword, dstDir:dword

	local pattern[600]:byte
	local fullPath[600]:byte
	local dstPath[600]:byte
	local findData:WIN32_FIND_DATA
	local hFind:dword
	
	invoke crt_sprintf, addr pattern, addr findPatternFormat, srcDir
	invoke FindFirstFile, addr pattern, addr findData
	mov hFind, eax
	
	cmp eax, -1
	je LD_Error
	
LD_Next:
	cmp byte ptr[findData.cFileName], '.'
	jne LD_CheckType
	
	cmp byte ptr[findData.cFileName + 1], 0
	je LD_Advance
	
	cmp byte ptr[findData.cFileName + 1], '.'
	jne LD_CheckType
	
	cmp byte ptr[findData.cFileName + 2], 0
	je LD_Advance

LD_CheckType:
	invoke JoinPath, addr fullPath, srcDir, addr findData.cFileName
	
	test findData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
	jnz LD_PrintDirectory
	
	invoke JoinPath, addr dstPath, dstDir, addr findData.cFileName
	
	invoke CopyFileAsm, addr dstPath, addr fullPath
	test eax, eax
	jz LD_CopyError
	
	invoke crt_printf, addr fileItemFormat, addr fullPath
	jmp LD_Advance
	
LD_PrintDirectory:
    invoke crt_printf, addr dirItemFormat, addr fullPath

    invoke JoinPath, addr dstPath, dstDir, addr findData.cFileName

    invoke CreateDirectory, addr dstPath, NULL
    test eax, eax
    jnz LD_Recurse

    invoke GetLastError
    cmp eax, ERROR_ALREADY_EXISTS
    jne LD_DirectoryError

LD_Recurse:
    invoke ListDirectory, addr fullPath, addr dstPath
    test eax, eax
    jz LD_CopyError

    jmp LD_Advance
	
LD_Advance:
	invoke FindNextFile, hFind, addr findData
	test eax, eax
	jnz LD_Next
	
	invoke FindClose, hFind
	mov eax, 1
	ret
	
LD_DirectoryError:
	invoke crt_printf, addr dirErrorText
	jmp LD_CopyError
	
LD_CopyError:
	invoke FindClose, hFind
	xor eax, eax
	ret
	
LD_Error:
	xor eax, eax
	ret

ListDirectory endp



GetFullDirPath proc c inputPath:dword, outputPath:dword, capacity:dword

	local pathLength:dword
	
	invoke GetFullPathName, inputPath, capacity, outputPath, NULL
	test eax, eax
	jz GFD_Failed
	
	cmp eax, capacity
	jae GFD_Failed
	
	mov pathLength, eax
	mov edx, outputPath
	mov ecx, pathLength
	
	mov al, byte ptr[edx + ecx - 1]
	cmp al, 5Ch
	je GFD_Success
	
	cmp al, 2Fh
	je GFD_Success
	
	mov eax, capacity
	dec eax
	cmp ecx, eax
	jae GFD_Failed
	
	mov byte ptr[edx + ecx], 5Ch
	inc ecx
	mov byte ptr[edx + ecx], 0
	
GFD_Success:
	mov eax, 1
	ret

GFD_Failed:
	xor eax, eax
	ret
	
GetFullDirPath endp



main proc c argc:dword, argv:dword, envp:dword

    local srcPath:dword
    local dstPath:dword
    local srcFull[1024]:byte
    local dstFull[1024]:byte
    local srcLen:dword
    local dstLen:dword

    cmp argc, 3
    jne MP_BadArgs

    mov eax, argv
    mov edx, [eax+4]
    mov srcPath, edx

    mov edx, [eax+8]
    mov dstPath, edx

    invoke GetFileAttributes, srcPath
    cmp eax, INVALID_FILE_ATTRIBUTES
    je MP_SourceInvalid

    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz MP_SourceInvalid

    invoke GetFullDirPath, srcPath, addr srcFull, sizeof srcFull
    test eax, eax
    jz MP_PathResolveError

    invoke GetFullDirPath, dstPath, addr dstFull, sizeof dstFull
    test eax, eax
    jz MP_PathResolveError

    invoke crt_strlen, addr srcFull
    mov srcLen, eax

    invoke crt_strlen, addr dstFull
    mov dstLen, eax

    cmp eax, srcLen
    jb MP_PathsSafe

    invoke CompareString, LOCALE_USER_DEFAULT, NORM_IGNORECASE, addr srcFull, srcLen, addr dstFull, srcLen
    test eax, eax
    jz MP_PathResolveError

    cmp eax, CSTR_EQUAL
    je MP_PathOverlap

MP_PathsSafe:
    invoke crt_printf, addr sourceText, srcPath
    invoke crt_printf, addr destText, dstPath

    invoke CreateDirectory, dstPath, NULL
    test eax, eax
    jnz MP_StartCopy

    invoke GetLastError
    cmp eax, ERROR_ALREADY_EXISTS
    jne MP_CreateFailed

    invoke GetFileAttributes, dstPath
    cmp eax, INVALID_FILE_ATTRIBUTES
    je MP_CreateFailed

    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz MP_CreateFailed

MP_StartCopy:
    invoke ListDirectory, srcPath, dstPath
    test eax, eax
    jz MP_ListFailed

    invoke crt_printf, addr copyDoneText
    xor eax, eax
    ret

MP_SourceInvalid:
    invoke crt_printf, addr sourceInvalidText
    mov eax, 4
    ret

MP_PathResolveError:
    invoke crt_printf, addr pathResolveErrorText
    mov eax, 5
    ret

MP_PathOverlap:
    invoke crt_printf, addr pathOverlapErrorText
    mov eax, 6
    ret

MP_CreateFailed:
    invoke crt_printf, addr dirErrorText
    mov eax, 3
    ret

MP_ListFailed:
    invoke crt_printf, addr listErrorText
    mov eax, 2
    ret

MP_BadArgs:
    invoke crt_printf, addr usageText
    mov eax, 1
    ret

main endp

end
