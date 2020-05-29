CODE SEGMENT
    ASSUME  CS:CODE, SS:NOTHING, DS:NOTHING, ES:NOTHING
	
MAIN	PROC	FAR
	jmp Start
		OvlSegAdd	db	'2nd overlay segment address:    ',0Dh,0Ah,'$'
Start:
	push AX
	push DX
	push DS
	push DI
	
	mov AX,CS
	mov DS,AX
	mov DI,offset OvlSegAdd
	add DI,31
	call WRD_TO_HEX
	mov DX,offset OvlSegAdd
	mov AH,09h
	int 21h
	
	pop DI
	pop DS
	pop DX
	pop AX
	retf
MAIN	ENDP

;----------------------
TETR_TO_HEX	PROC near
		  and	AL,0Fh
		  cmp	AL,09
		  jbe	NEXT
		  add	AL,07
NEXT:	  add	AL,30h
		  ret
TETR_TO_HEX ENDP
;----------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два числа в 16 с/с
		  push	CX
		  mov	AH,AL
		  call	TETR_TO_HEX
		  xchg	AL,AH
		  mov	CL,4
		  shr	AL,CL
		  call	TETR_TO_HEX ;в AL старшая цифра, в AH - младшая
		  pop	CX
		  ret
BYTE_TO_HEX ENDP
;----------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-разрядного числа
;в АХ - число, в DI - адрес последнего символа
		  push	BX
		  mov	BH,AH
		  call	BYTE_TO_HEX
		  mov	[DI],AH
		  dec	DI
		  mov	[DI],AL
		  dec	DI
		  mov	AL,BH
		  call	BYTE_TO_HEX
		  mov	[DI],AH
		  dec	DI
		  mov	[DI],AL
		  pop	BX
		  ret
WRD_TO_HEX	ENDP
	
CODE ENDS
END MAIN