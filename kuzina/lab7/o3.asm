CODE SEGMENT
	ASSUME  cs:CODE, ds:NOTHING, ES:NOTHING, SS:NOTHING

MAIN PROC FAR
	jmp MainS
		
OAddr db '	Segment address of third overlay: $'
Endl db 10,13,'$'

MainS:
	push ax
	push dx
	push ds
	mov ax, cs
	mov ds, ax

	mov dx, offset OAddr
	mov ah, 09h
	int 21h
	mov ax, cs
	call PrintWord
	mov dx, offset Endl
	mov ah, 09h
	int 21h
		
	pop ds
	pop dx
	pop ax
	ret
MAIN ENDP

PrintWord PROC
	xchg ah, al
	call PrintByte
	xchg ah, al
	call PrintByte
	ret
PrintWord ENDP

PrintByte PROC
	push ax
	push bx
	push dx
	call ByteToHex
	mov bh, ah

	mov dl, al
	mov ah, 02h
	int 21h
	mov dl, bh
	mov ah, 02h
	int 21h
	pop dx
	pop bx
	pop ax
	ret
PrintByte    ENDP

TetrToHex 	PROC 
	and al,0Fh 
	cmp al,09 
		jbe next 
	add al,07 
next:
	add al,30h 
	ret 
TetrToHex   ENDP 

ByteToHex   PROC
	push cx 
	mov  ah,al 
	call TetrToHex 
	xchg al,ah 
	mov cl,4 
	shr al,cl 
	call TetrToHex
	pop cx        
	ret 
ByteToHex  ENDP 

CODE ENds

END MAIN