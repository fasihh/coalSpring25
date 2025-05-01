INCLUDE Irvine32.inc

.data
    array DWORD 1, 2, 3, 4
.code

addTwoAdv PROC, first:DWORD, second:DWORD
    mov eax, first
    add eax, second
    ret
addTwoAdv ENDP

addTwo PROC
    ; first, second
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    add eax, [ebp + 12]

    pop ebp
    ret 8
addTwo ENDP

addAll PROC
    ; array, type, length
    push ebp
    mov ebp, esp
    sub esp, 4
    
    push ebp
    push ecx
    push esi
    mov DWORD PTR [ebp - 4], 0
    mov esi, [ebp + 8]
    mov ecx, 0
begin_loop:
    cmp ecx, [ebp + 16]
    jge end_loop
    mov eax, [esi]
    add DWORD PTR [ebp - 4], eax
    add esi, [ebp + 12]
    inc ecx
    jmp begin_loop
end_loop:

    mov eax, [ebp - 4]

    pop esi
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret 16
addAll ENDP

addAllAdv PROC
    ; array, type, length
    enter 4, 0

    push ebp
    push ecx
    push esi
    mov DWORD PTR [ebp - 4], 0
    mov esi, [ebp + 8]
    mov ecx, 0
begin_loop:
    cmp ecx, [ebp + 16]
    jge end_loop
    mov eax, [esi]
    add DWORD PTR [ebp - 4], eax
    add esi, [ebp + 12]
    inc ecx
    jmp begin_loop
end_loop:

    mov eax, [ebp - 4]

    pop esi
    pop ecx
    pop ebx

    leave
    ret 16
addAllAdv ENDP

binarySearch PROC
    ; array, left, right, target
    push ebp
    mov ebp, esp
    sub esp, 4
    push eax
    push ebx

    ; base case
    mov edi, -1
    mov eax, [ebp + 12] ; eax = left
    cmp eax, [ebp + 16] ; left > right
    jg end_search

    ; Calculate mid = (left + right) / 2
    mov ebx, [ebp + 12]  ; ebx = left
    mov ecx, [ebp + 16]  ; ecx = right
    add ebx, ecx         ; ebx = left + right
    shr ebx, 1           ; mid = (left + right) / 2
    mov [ebp - 4], ebx   ; Store mid

    ; Access array[mid]
    mov esi, [ebp + 8]   ; esi = array base address
    mov eax, [ebp - 4]   ; eax = mid index
    shl eax, 2           ; Convert index to byte offset (4 bytes per int)
    add esi, eax         ; esi = array + (mid * 4)
    mov eax, [esi]       ; eax = array[mid]

    cmp eax, [ebp + 20] ; eax == target
    je found_result

    cmp [ebp + 20], eax  ; target < array[mid]
    jl search_left

    mov eax, [ebp - 4]   ; eax = mid
    add eax, 1           ; left = mid + 1
    push [ebp + 20]      ; Push target
    push [ebp + 16]      ; Push right
    push eax             ; Push updated left
    push [ebp + 8]       ; Push array
    call binarySearch
    jmp end_search

search_left:
    mov eax, [ebp - 4]   ; eax = mid
    sub eax, 1           ; right = mid - 1
    push [ebp + 20]      ; Push target
    push eax             ; Push updated right
    push [ebp + 12]      ; Push left
    push [ebp + 8]       ; Push array
    call binarySearch
    jmp end_search

found_result:
    mov edi, [ebp - 4]   ; Return mid index
    jmp end_search
not_found:
    mov eax, -1
end_search:
    pop ebx
    pop eax
    mov esp, ebp
    pop ebp
    ret 20
binarySearch ENDP

main PROC
    
    push LENGTHOF array
    push TYPE array
    push OFFSET array
    call addAllAdv
    call WriteDec

    call CRLF
    
    push 2
    push 1
    call AddTwoAdv
    call WriteDec

    call CRLF

    push 4
    push LENGTHOF array
    push 0
    push OFFSET array
    call binarySearch
    mov eax, edi
    call WriteDec

    exit
main ENDP
END main
