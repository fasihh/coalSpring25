INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
    WORDCNT=20
    WORDBUF=20

    file_name BYTE "input.txt", 0
    file_buffer BYTE WORDCNT * WORDBUF DUP(0)
    buffer BYTE WORDCNT DUP(WORDBUF DUP(0))
    bufsiz DWORD WORDCNT * WORDBUF
.code

; PRINTS BUFFER ELEMENTS
PrintBuffer PROC USES esi eax
    mov eax, 0
    mov esi, 0

print_loop:
    mov edi, esi
print_word:
    mov al, buffer[edi]
    cmp al, 0
    je go_next
    call WriteChar
    inc edi
    jmp print_word

go_next:
    add esi, 20
    mov eax, 32
    call WriteChar
    cmp esi, bufsiz
    jne print_loop

    ret
PrintBuffer ENDP

; PARSES THE STRING READ FROM THE FILE AND TRANSFERS IT TO THE BUFFER: RETURNS word_count (always assumes at least 1 word exists)
ParseFileInput PROC USES esi edi ecx
    LOCAL word_count:DWORD

    mov word_count, 1
    mov esi, OFFSET file_buffer
    mov edi, OFFSET buffer
    mov ecx, 0

read_loop:
    cmp word_count, WORDCNT
    jge end_parse

    mov al, BYTE PTR [esi]
    cmp al, 0
    je end_parse

    cmp al, 0dh
    jne go_next

    inc word_count
    inc esi
    neg ecx
    add ecx, 20
pad_word:
    mov al, 0
    mov BYTE PTR [edi], al
    inc edi
    loop pad_word

    inc esi
    jmp read_loop
go_next:
    mov BYTE PTR [edi], al
    inc esi
    inc edi
    inc ecx
    jmp read_loop

end_parse:
    mov eax, word_count
    ret
ParseFileInput ENDP


; READS FROM FILE AND PARSES IT
ReadInputFile PROC USES eax edx ecx
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
    mov ecx, bufsiz
    call ReadFromFile
    jnc check_read
    mWrite "Cannot read from file"
    jmp close_file

check_read:
    cmp eax, 0
    jne check_buffer
    mWrite "Nothing in file"
    jmp close_file

check_buffer:
	cmp	eax, bufsiz
	jb	buf_size_ok
	mWrite "File size greater than buffer"
	jmp	close_file
buf_size_ok:

    mov eax, file_handle
    call CloseFile
    jmp terminate

close_file:
    mov eax, file_handle
    call CloseFile
    jmp quit
terminate:
    ret
ReadInputFile ENDP


; SELECTS RANDOM WORD INDEX FROM RANGE OF WORDS AVAILABLE: TAKES IN ARGUMENTS eax AND RETURNS INDEX IN eax TOO
SelectRandomWord PROC USES eax ebx
    call Randomize
    call RandomRange

    mov ebx, WORDBUF
    imul ebx

    ret
SelectRandomWord ENDP


; TAKES INDEX OF WORD AS PARAMETER IN EAX AND PRINTS THE WORD
WriteWord PROC USES eax esi
    mov esi, eax
write_loop:
    mov al, buffer[esi]
    cmp al, 0
    je finish
    call WriteChar
    inc esi
    jmp write_loop

finish:
    ret
WriteWord ENDP


; GENERATES SEQUENCE OF WORD COUNT STORED IN ecx. ALSO TAKES IN WORD COUNT IN eax
GenerateRandomWords PROC USES eax ecx
write_loop:
    call SelectRandomWord
    call WriteWord
    push eax
    mov eax, 32
    call WriteChar
    pop eax
    loop write_loop

    ret
GenerateRandomWords ENDP

main PROC
    LOCAL word_count:DWORD

    call ReadInputFile
    call ParseFileInput
    mov word_count, eax

    mov ecx, 10
    mov eax, word_count
    call GenerateRandomWords

quit::
    exit
main ENDP
END main

