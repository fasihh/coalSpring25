#### Using MUL and converting the result using shift registers
```asm
INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
    result BYTE 33 DUP(0)
.code

ToBin PROC
    enter 0, 0
    pushad
    
    mov ecx, 16
    mov esi, OFFSET result
convdx:
    shl dx, 1
    jc onedx
    mov BYTE PTR [esi], '0'
    jmp nextdx
onedx:
    mov BYTE PTR [esi], '1'
nextdx:
    inc esi
    loop convdx

    mov ecx, 16
convax:
    shl ax, 1
    jc oneax
    mov BYTE PTR [esi], '0'
    jmp nextax
oneax:
    mov BYTE PTR [esi], '1'
nextax:
    inc esi
    loop convax

    popad
    leave
    ret
ToBin ENDP

main PROC
    mov eax, 0
    mov edx, 0
    mov ebx, 0
    mov ax, 2
    mov bx, 1
    mul bx

    call ToBin
    mov edx, OFFSET result
    call WriteString

    exit
main ENDP
END main
```
#### using movsd and rep to shift array left by one. deleting the first entry
```asm
INCLUDE Irvine32.inc
INCLUDE macros.inc

.data
    arr DWORD 1, 2, 3, 4, 5
.code

PrintArr PROC, _s_data:DWORD, _s_size:DWORD, _s_type:DWORD
    pushad
    
    mov esi, _s_data
    mov ecx, _s_size
    mov ebx, _s_type
l1:
    mov eax, [esi]
    call WriteHex
    mov eax, 32
    call WriteChar
    add esi, TYPE arr
    loop l1

    popad
    ret
PrintArr ENDP

main PROC
    mov ecx, LENGTHOF arr - 1
    mov esi, OFFSET arr + TYPE arr
    mov edi, OFFSET arr

    rep movsd

    INVOKE PrintArr, ADDR arr, LENGTHOF arr, TYPE arr

    exit
main ENDP
END main
```

