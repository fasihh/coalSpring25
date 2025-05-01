INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
    WORDCNT=200
    WORDBUF=30
    MAX_SELECTED=100
    max_bufsiz DWORD WORDCNT * WORDBUF

    file_name BYTE "input.txt",0
    file_buffer BYTE WORDCNT * WORDBUF DUP(0)

    buffer BYTE WORDCNT DUP(WORDBUF DUP(0))
    buffer_size DWORD ?

    selected_buffer BYTE MAX_SELECTED DUP(WORDBUF DUP(0))
    input_buffer BYTE WORDBUF DUP(0)
    
    start_time FILETIME <>
    end_time   FILETIME <>
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


; WRITES WORD FROM buffer BASED ON INDEX GIVEN IN eax INTO selected_buffer BASED ON INDEX GIVEN IN ebx
WriteWordFromIndex PROC USES eax ebx ecx esi
    mov ecx, WORDBUF
    mov esi, OFFSET buffer
    mul ecx
    add esi, eax

    mov edi, OFFSET selected_buffer
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


; SETS COLOR TO WHITE AND RED TO INDICATE ERROR
SetErrorColor PROC USES eax
    mov eax, white + (16 * red)
    call SetTextColor
    ret
SetErrorColor ENDP

; SETS COLOR TO WHITE AND GREEN TO INDICATE CURRENT WORD
SetCurrentColor PROC USES eax
    mov eax, white + (16 * green)
    call SetTextColor
    ret
SetCurrentColor ENDP

; RESETS COLOR TO WHITE AND BLACK
ResetColor PROC USES eax
    mov eax, white + (16 * black)
    call SetTextColor
    ret
ResetColor ENDP


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
; HIGHLIGHTS CURRENT WORD SENT IN ebx
PrintSelectedWords PROC USES eax ebx edx esi edi
    lea esi, OFFSET selected_buffer
    mov edi, 0
print_loop:
    cmp edi, ebx
    jne not_current
    call SetCurrentColor
not_current:
    mov edx, esi
    call WriteString
    call ResetColor
    mov eax, 32
    call WriteChar
    add esi, WORDBUF
    inc edi
    loop print_loop

    ret
PrintSelectedWords ENDP


; READS USER INPUT INTO BUFFER. TERMINATES WHEN EITHER BUFFER LENGTH IS FULL OR USER TYPES SPACE OR ENTER
; COMPARES EACH LETTER WITH THAT IN edi AND HIGHLIGHTS THE INCORRECT ONES IN RED
; ALSO RETURNS 1 IN ebx IF MISTAKE HAD BEEN MADE IN BETWEEN OTHERWISE 0
ReadWordInput PROC USES eax esi edi
    mov ebx, 0
    mov eax, 0
    mov esi, 0
input_loop:
    cmp esi, WORDBUF-1
    jge finish

    call ReadChar
    cmp al, 20h
    je finish
    cmp al, 0Dh
    je finish
    cmp al, 08h
    jne not_backspace
    cmp esi, 0
    je input_loop
    call ResetColor
    ; move back pointers by one
    dec esi
    dec edi
    ; delete character from screen too
    mov eax, 8
    call WriteChar
    mov eax, 32
    call WriteChar
    mov eax, 8
    call WriteChar

    jmp input_loop
not_backspace:

    mov input_buffer[esi], al ; store in input buffer
    cmp al, BYTE PTR [edi]    ; compare with current letter
    je same_letter            ; if same then dont color

    call SetErrorColor
    mov ebx, 1
same_letter:

    ; write character, reset color and update pointers
    call WriteChar
    call ResetColor
    inc esi
    inc edi
    jmp input_loop
finish:
    mov input_buffer[esi], 0
    ret
ReadWordInput ENDP


; CHECKS STRING STORED IN esi WITH input_buffer. RETURNS 1 IN ebx IF SAME OR 0 OTHERWISE
CheckInputBuffer PROC USES esi ecx edi
    mov ebx, 0
    lea edi, input_buffer
    invoke str_compare, esi, edi
    jne is_not_same
    mov ebx, 1
is_not_same:
    ret
CheckInputBuffer ENDP


main PROC
    LOCAL correct_words:DWORD
    LOCAL error_words:DWORD
    LOCAL elapsed_time:DWORD
    LOCAL words_count:DWORD

    ; set new seed
    call Randomize
    ; read form file
    call ReadInputData
    ; parse file data
    call ParseInputData
    
    mWrite "Enter number of words to type: "
    call ReadInt
    mov words_count, eax
    mov ecx, eax
    call GenerateRandomWords
    
    mov ecx, words_count
    mov ebx, 0
    lea edi, selected_buffer
    mov correct_words, 0
    INVOKE GetDateTime, ADDR start_time
run_loop:
    push ecx
    mov ecx, words_count
    call PrintSelectedWords
    pop ecx
    mov eax, 0
    mov edx, 0
    call CRLF
    push ebx
    mWrite ">> "
    call ReadWordInput
    add error_words, ebx
    pop ebx

    mov esi, edi
    push ebx
    call CheckInputBuffer
    add correct_words, ebx
    pop ebx
    add edi, WORDBUF
    inc ebx
    call ClrScr
    loop run_loop

    INVOKE GetDateTime, ADDR end_time
    mov eax, end_time.loDateTime
    sub eax, start_time.loDateTime
    mov ebx, 10000000
    div ebx
    mov elapsed_time, eax

    mWrite "Completed in: "
    call WriteDec
    mWrite <"s",0dh,0ah>
    
    mWrite "Got "
    mov eax, correct_words
    call WriteDec
    mWrite " word(s) correct out of "
    mov eax, words_count
    call WriteDec
    mWrite <" word(s)",0dh,0ah>
    mWrite "Made "
    mov eax, error_words
    call WriteDec
    mWrite <" mistake(s)",0ah,0dh,0ah,0dh>

    mov eax, correct_words
    mov ebx, elapsed_time

    mov ecx, 60
    mul ecx
    div ebx
    
    mWrite "Raw Speed: "
    call WriteDec
    mWrite <"wpm",0dh,0ah>

    mov eax, words_count
    sub eax, error_words
    mov ebx, elapsed_time
    mov ecx, 60
    mul ecx
    div ebx

    mWrite "Original Speed: "
    call WriteDec
    mWrite <"wpm",0dh,0ah>
    
quit::
    exit
main ENDP
END main
