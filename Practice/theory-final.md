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
