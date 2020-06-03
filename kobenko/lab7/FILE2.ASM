CODE SEGMENT
	ASSUME CS:CODE, DS:NOTHING, SS:NOTHING
	MAIN PROC FAR
		push AX
		push DX
		push DS
		push DI
		
		mov AX, CS
		mov DS, AX
		mov DI, offset OVL
		add DI, 23
		call WRD_TO_HEX
		MOV DX, offset OVL
		call PRINT
		
		pop DI
		pop DS
		pop DX
		pop AX
		retf
	MAIN ENDP

	OVL db 13, 10, "FILE2_OVL address:          ", 13, 10, '$'

	PRINT PROC 
		push DX
		push AX
		
		mov AH, 09h
		int 21h

		pop AX
		pop DX
		ret
	PRINT ENDP


	TETR_TO_HEX PROC 
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
	next:
		add AL,30h
		ret
	TETR_TO_HEX ENDP


	BYTE_TO_HEX PROC 		
		push 	cx
		mov 	ah, al
		call 	TETR_TO_HEX
		xchg 	al,ah
		mov 	cl,4
		shr 	al,cl
		call 	TETR_TO_HEX 	
		pop 	cx 				
		ret
	BYTE_TO_HEX ENDP


	WRD_TO_HEX PROC  
		push	bx
		mov	bh,ah
		call	BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		xor	ah,ah
		call	BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
	WRD_TO_HEX ENDP
CODE ENDS
END MAIN 
