```asm
INCLUDE Irvine32.inc

.data
	BUFSIZ=256
	N=3
	messages BYTE N * BUFSIZ DUP(0)
.code
main proc
	mov ecx, N
	mov esi, 0
	input:
		push ecx
		mov edx, offset messages
		add edx, esi
		mov ecx, BUFSIZ
		call ReadString
		pop ecx

		add esi, BUFSIZ
		loop input
	
	call crlf
	mov ecx, N
	mov esi, 0
	mov eax, 32
	output:
		mov edx, offset messages
		add edx, esi
		call WriteString
		call WriteChar
		
		add esi, BUFSIZ
		loop output
	
	exit
main endp
end main
```