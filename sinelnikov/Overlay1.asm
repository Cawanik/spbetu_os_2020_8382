OVERLAY1 SEGMENT
ASSUME CS:OVERLAY1, DS:OVERLAY1

Main PROC FAR 
	push ax
	push bx
	push dx
	push ds
	push di
	mov ax, cs
	mov ds, ax
	mov bx, offset address
	add bx, 14
	mov di, bx		
	mov ax, cs			
	call WRD_TO_HEX
	mov dx, offset address
	call print_message
	pop di
	pop ds
	pop dx
	pop bx
	pop ax
	retf
Main ENDP


address  db 'address:                   ',0dh,0ah,'$'

print_message proc
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print_message endp

TETR_TO_HEX		PROC near 
		and		al, 0Fh 
		cmp		al, 09 
		jbe		NEXT 
		add		al, 07 
	NEXT:add	al, 30h 
		ret
TETR_TO_HEX		ENDP

BYTE_TO_HEX		PROC near 
		push	cx
		mov		ah, al 
		call	TETR_TO_HEX 
		xchg	al, ah 
		mov		cl, 4 
		shr		al, cl 
		call	TETR_TO_HEX 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP

WRD_TO_HEX		PROC	near 
		push	bx
		mov		bh, ah 
		call	BYTE_TO_HEX 
		mov		[di], ah 
		dec		di 
		mov		[di], al 
		dec		di
		mov		al, bh 
		xor		ah, ah 
		call	BYTE_TO_HEX 
		mov		[di], ah 
		dec		di
		mov		[di], al 
		pop		bx
		ret
WRD_TO_HEX		ENDP

OVERLAY1 ENDS
END Main
