CODE SEGMENT
ASSUME CS:CODE, DS:CODE

START: jmp START_PROC

link  DB 'overlay two at        ',0DH,0AH,'$'

START_PROC PROC FAR 
	push ax
	push bx
	push dx
	push ds
	mov ax, cs
	mov ds, ax
	mov bx, offset link
	add bx, 18
	mov di, bx		
	mov ax, cs			
	mov	bh, ah 
	call BYTE_TO_HEX 
	mov	[di], ah 
	dec	di 
	mov	[di], al 
	dec	di
	mov	al, bh 
	xor	ah, ah 
	call BYTE_TO_HEX 
	mov	[di], ah 
	dec	di
	mov	[di], al 
	mov dx, offset link	
	mov ah, 9
	int 21h
	pop ds
	pop dx
	pop bx
	pop ax
	retf
START_PROC ENDP

TETR_TO_HEX PROC near 
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

CODE ENDS
END START 