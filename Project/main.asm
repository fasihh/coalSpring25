INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
    WORDCNT=200
    WORDBUF=30
    MAX_SELECTED=100

    file_name BYTE "input.txt",0
    file_buffer BYTE WORDCNT * WORDBUF DUP(0)
    buffer BYTE WORDCNT DUP(WORDBUF DUP(0))
    max_bufsiz DWORD WORDCNT * WORDBUF
    buffer_size DWORD ?
    selected BYTE MAX_SELECTED DUP(WORDBUF DUP(0))
.code


; PRINTS BUFFER ELEMENTS
PrintBuffer PROC USES esi edi ecx
    mov ecx, buffer_size
    mov esi, OFFSET buffer
print_loop:
    push ecx

    mov ecx, WORDBUF
    mov edi, esi
print_word:
    mov al, BYTE PTR [edi]
    call WriteChar
    inc edi
    loop print_word

    pop ecx
    call CRLF
    add esi, WORDBUF
    loop print_loop

    ret
PrintBuffer ENDP


; DEBUG PURPOSES
PrintFileBuffer PROC
    mov ecx, max_bufsiz
    mov esi, 0

print:
    movzx eax, file_buffer[esi]
    call WriteHex
    push eax
    mov eax, 32
    call WriteChar
    pop eax
    call WriteChar
    call CRLF
    inc esi
    loop print

    ret
PrintFileBuffer ENDP


; PARSES THE STRING READ FROM THE FILE AND TRANSFERS IT TO THE BUFFER: RETURNS # OF ELEMENTS IN ecx
ParseInputData PROC USES esi edi eax ecx
    LOCAL count:DWORD

    mov count, 0
    mov esi, OFFSET file_buffer
    mov edi, OFFSET buffer
    mov ecx, 0

parse_loop:
    mov al, BYTE PTR [esi]
    inc ecx
    cmp al, 0
    je finish

    cmp al, 0Dh ; newline found
    je next_word

    cmp ecx, WORDBUF
    je max_buf_limit ; skip moving into source if max buffer size reached
    movzx eax, BYTE PTR [esi]
    mov BYTE PTR [edi], al
    inc edi
max_buf_limit:
    inc esi
    jmp parse_loop
next_word:
    add esi, 2 ; adjust esi to next word
    dec ecx    ; decrement count to remove newline

    ; find total offset needed to be added into edi to move to next index in buffer
    mov ebx, ecx
    sub ebx, WORDBUF
    neg ebx

    add edi, ebx
    mov ecx, 0
    inc count

    jmp parse_loop
    
finish:
    mov ecx, count
    inc ecx
    mov buffer_size, ecx
    ret
ParseInputData ENDP


; READS FROM FILE INTO file_buffer
ReadInputData PROC USES eax edx ecx
    LOCAL file_handle:HANDLE

    lea edx, file_name
    call OpenInputFile
    mov file_handle, eax

    cmp eax, INVALID_HANDLE_VALUE
    jne file_ok
    mWrite "Cannot open file"
    jmp terminate
file_ok:

    lea edx, file_buffer
    mov ecx, max_bufsiz
    call ReadFromFile
    jnc check_read
    mWrite "Cannot read from file"
    jmp file_fail

check_read:
    cmp eax, 0
    jne check_buffer
    mWrite "Nothing in file"
    jmp file_fail

check_buffer:
	cmp	eax, max_bufsiz
	jb	buf_size_ok
	mWrite "File size greater than buffer"
	jmp	file_fail
buf_size_ok:

    mov eax, file_handle
    call CloseFile
    jmp terminate

file_fail:
    mov eax, file_handle
    call CloseFile
    jmp quit
terminate:
    ret
ReadInputData ENDP


; WRITES WORD FROM buffer BASED ON INDEX GIVEN IN eax INTO selected BASED ON INDEX GIVEN IN ebx
WriteWordFromIndex PROC USES eax ebx ecx esi
    mov ecx, WORDBUF
    mov esi, OFFSET buffer
    mul ecx
    add esi, eax

    mov edi, OFFSET selected
    push eax
    mov eax, ebx
    mul ecx
    mov ebx, eax
    pop eax
    add edi, ebx

    rep movsb
    
    ret
WriteWordFromIndex ENDP


; GENERATES RANDOM INDEX: RETURNS RESULT IN eax
SelectRandomIndex PROC
    mov eax, buffer_size
    call RandomRange
    ret
SelectRandomIndex ENDP


; GENERATES A SEQUENCE OF N WORDS WHERE N IS GIVEN IN ecx
GenerateRandomWords PROC USES eax ebx ecx
    mov ebx, 0
gen_loop:
    call SelectRandomIndex
    call WriteWordFromIndex
    inc ebx
    loop gen_loop

    ret
GenerateRandomWords ENDP


; PRINT N SELECTED WORDS WHERE N IS IN ecx
PrintSelectedWords PROC USES eax
    mov esi, OFFSET selected
print_loop:
    mov edx, esi
    call WriteString
    mov eax, 32
    call WriteChar
    add esi, WORDBUF
    loop print_loop

    ret
PrintSelectedWords ENDP


main PROC
    call Randomize
    call ReadInputData
    call ParseInputData

    mov ecx, 50
    call GenerateRandomWords
    call PrintSelectedWords

    ; take user input 50 times
    ; for each input compare string with selected
    ; if correct then count else leave
    ; after every word, reset cursor to start again (also clear line)

quit::
    exit
main ENDP
END main
