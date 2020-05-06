OVERLAY SEGMENT
	ASSUME CS:OVERLAY, DS:NOTHING, SS:NOTHING, ES:NOTHING
	
	MAIN PROC FAR
		push	ax
		push	dx
		push	di
		push	ds
	
		mov		ax, cs
		mov		ds, ax
		
		mov		dx, offset SEGMENT_MESSAGE
		call	PRINT_STRING
		
		mov		di, offset SEGMENT_ADRESS_MESSAGE
		add		di, 3
		call	WRD_TO_HEX
		
		mov		dx, offset SEGMENT_ADRESS_MESSAGE
		call	PRINT_STRING
		call	PRINT_ENDL
		
		pop		ds
		pop		di
		pop		dx
		pop		ax
		retf
	MAIN ENDP
	
	SEGMENT_MESSAGE			DB	'OVERLAY #2 SEGMENT: ', '$'
	SEGMENT_ADRESS_MESSAGE	DB	'    $'

	; Младшая 16-ичная цифра AL в 16-ичную цифру ASCII в AL
	TETR_TO_HEX PROC near
			and 	AL, 0Fh
			cmp		AL, 09
			jbe		NEXT
			add		AL, 07
	NEXT: 	add		AL, 30h
			ret
	TETR_TO_HEX ENDP 

	; Байт в AL переводится в два 16-ичных числа ASCII в AX
	BYTE_TO_HEX PROC near
			push	CX
			mov		AH, AL
			call	TETR_TO_HEX
			xchg	AL, AH
			mov		CL, 4
			shr		AL, CL
			call	TETR_TO_HEX 	; в AL старшая цифра
			pop		CX 				; в AH младшая
			ret
	BYTE_TO_HEX ENDP 

	; Перевод в 16 с/с 16-разрядного числа
	; в AX – число, DI – адрес последнего символа
	WRD_TO_HEX PROC near
			push	BX
			mov		BH,AH
			call	BYTE_TO_HEX
			mov		[DI],AH
			dec		DI
			mov		[DI],AL
			dec		DI
			mov		AL,BH
			call	BYTE_TO_HEX
			mov		[DI],AH
			dec		DI
			mov		[DI],AL
			pop		BX
			ret
	WRD_TO_HEX ENDP
	
	PRINT_STRING PROC near
		push ax
		
		mov ah, 09h
		int 21h
		
		pop ax
		ret
	PRINT_STRING ENDP
	
	PRINT_ENDL PROC near
		push ax
		push dx
		
		mov dl, 13
		mov ah, 02h
		int 21h
		mov dl, 10
		int 21h
		
		pop dx
		pop ax
		ret
	PRINT_ENDL ENDP
OVERLAY ENDS
END MAIN
