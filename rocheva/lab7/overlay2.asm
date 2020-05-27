OVERLAY2 SEGMENT
ASSUME CS:OVERLAY2, DS:OVERLAY2

START: jmp START_PROC

PRINT_ADDRESS  DB 'has address:        ',0DH,0AH,'$'

START_PROC PROC FAR 
	push ax
	push bx
	push dx
	push ds
	mov ax, cs
	mov ds, ax
	mov bx, offset PRINT_ADDRESS
	add bx, 16
	mov di, bx		
	mov ax, cs			
	call WRD_TO_HEX
	mov dx, offset PRINT_ADDRESS	
	call WRITE
	pop ds
	pop dx
	pop bx
	pop ax
	retf
START_PROC ENDP

WRITE PROC NEAR  
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WRITE ENDP

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

OVERLAY2 ENDS
END START