OVERLAY SEGMENT
	ASSUME CS:OVERLAY, DS:OVERLAY, SS:NOTHING, ES:NOTHING
	MAIN PROC FAR
		push ax
		push dx
		push di
		push ds
	
		mov	ax, cs
		mov	ds, ax
		
		mov	di, offset SEGMENT_STRING
		add	di, 20
		call WRD_TO_HEX
		mov	dx, offset SEGMENT_STRING
		call PRINT
		
		pop	ds
		pop	di
		pop	dx
		pop	ax
		retf
	MAIN ENDP

	SEGMENT_STRING DB 'Overlay address: 0000', 13, 10, '$'
	
	TETR_TO_HEX PROC near
		and al, 0fh
		cmp	al, 9
		jbe	NEXT
		add	al, 7
		NEXT: 	
			add al, 30h
		ret
	TETR_TO_HEX ENDP 

	BYTE_TO_HEX PROC near
		push cx
		mov ah, al
		call TETR_TO_HEX
		xchg al, ah
		mov cl, 4
		shr	al, cl
		call TETR_TO_HEX
		pop	cx
		ret
	BYTE_TO_HEX ENDP 

	WRD_TO_HEX PROC near
	; IN ax - number
	; OUT di - last symbol address
		push bx
		mov bh, ah
		call BYTE_TO_HEX
		mov [di], ah
		dec di
		mov [di], al
		dec di
		mov al, bh
		call BYTE_TO_HEX
		mov	[di], ah
		dec	di
		mov	[di], al
		pop	bx
		ret
	WRD_TO_HEX ENDP
	
	PRINT PROC near
		push ax
		
		mov ah, 09h
		int 21h
		
		pop ax
		ret
	PRINT ENDP
OVERLAY ENDS
END MAIN