CODE SEGMENT

	ASSUME  CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

	MY_INT PROC FAR
		jmp MY_INT_START
	MY_INT_DATA:
		KEEP_CS   dw 0
		KEEP_IP   dw 0
		KEEP_PSP  dw 0
		SIGNATURE dw 1234h
		COUNTER   db '000$'

	MY_INT_START:
		push AX
		push BX
		push CX
		push DX
		push SI
		push DS
		push ES

		; set DS to int's data segment
		mov AX, SEG KEEP_CS
		mov DS, AX

		INC_COUNTER:
			xor CX, CX
			mov SI, offset COUNTER
			add SI, 2
			INC_DIGIT:
				mov AL, [SI]
				cmp AL, '9'
				je CARRY
				inc AL
				mov [SI], AL
				jmp INC_DIGIT_END
				CARRY:
					mov AL, '0'
					mov [SI], AL

					cmp SI, offset COUNTER
					je CLEAR_COUNTER
					dec SI

					jmp INC_DIGIT
				CLEAR_COUNTER:
					mov CX, 2
					clear_digit:
						mov AL, '0'
						mov [SI], AL
						inc SI
						loop clear_digit
			INC_DIGIT_END:

		SAVE_CURSOR:
			mov AH, 03h
			mov BH, 0
			int 10h
			push DX

		SET_CURSOR:
			mov AH, 02h
			mov BH, 0
			mov DX, 1845h 	; DH=row, DL=col (18==last row)
			int 10h

		PRINT_COUNTER:
			push ES
			push BP
			mov AX, seg KEEP_CS
			mov ES, AX
			mov BP, offset COUNTER
			mov AH, 13h
			mov AL, 1
			mov BH, 0
			mov CX, 3 				; string length
			int 10h
			pop ES
			pop BP

		RESET_CURSOR:
			pop DX
			mov AH, 02h
			mov BH, 0
			int 10h

		pop ES
		pop DS
		pop SI
		pop DX
		pop CX
		pop BX
		pop AX

		mov AL, 20h
		out 20H, AL
		iret
	MY_INT ENDP
	MY_INT_END:

	CHECK_INT PROC
		; sets AX to 1 if interruption is already loaded
		; otherwise sets AX to 0
		push BX
		push CX
		push DX
		push SI
		push ES

		; get int's segment
		mov AH, 35h
		mov AL, 1Ch
		int 21h

		; get signature's offset
		mov SI, offset SIGNATURE
		sub SI, offset MY_INT

		; check signature
		mov AX, 1
		mov BX, ES:[BX+SI]
		mov CX, SIGNATURE
		cmp BX, CX
		je CHECK_INT_END
		mov AX, 0

		CHECK_INT_END:
		pop ES
		pop DX
		pop SI
		pop CX
		pop BX
		ret
	CHECK_INT ENDP

	CHECK_TAIL PROC
		; sets AX to 1 if tail starts with '/un'
		; otherwise sets AX to 0
		mov AX, 0

		cmp byte ptr ES:[82h], '/'
		jne CHECK_TAIL_END
		cmp byte ptr ES:[83h], 'u'
		jne CHECK_TAIL_END
		cmp byte ptr ES:[84h], 'n'
		jne CHECK_TAIL_END

		mov AX, 1

		CHECK_TAIL_END:
		ret
	CHECK_TAIL ENDP

	LOAD_INT PROC
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES

		; save old int
		mov AH, 35h
		mov AL, 1Ch
		int 21h
		mov KEEP_IP, BX
		mov KEEP_CS, ES

		; set new int
		push DS
		mov DX, offset MY_INT
		mov AX, seg MY_INT
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
		int 21h
		pop DS

		; make resident
		mov DX, offset MY_INT_END
		shr DX, 1
		shr DX, 1
		shr DX, 1
		shr DX, 1
		add DX, 11h
		inc DX
		mov AX, 0
		mov AH, 31h
		int 21h

		pop ES
		pop DS
		pop DX
		pop CX
		pop BX
		pop AX

		ret
	LOAD_INT ENDP

	UNLOAD_INT PROC
		push AX
		push BX
		push CX
		push DX
		push SI
		push ES
		push DS

		cli

		; get int's segment
		mov AH, 35h
		mov AL, 1Ch
		int 21h

		; get int's data offset
		mov SI, offset KEEP_CS
		sub SI, offset MY_INT

		mov AX, ES:[BX+SI] 		; cs
		mov DX, ES:[BX+SI+2] 	; ip
		push DS
		mov DS, AX
		mov AH, 25h
		mov AL, 1Ch
		int 21h
		pop DS

		; free memory
		mov AX, ES:[BX+SI+4] 	; saved PSP
		mov ES, AX
		push ES
		mov AX, ES:[2Ch] 		; env variables seg
		mov ES, AX
		mov AH, 49h
		int 21h 				; free env variables seg
		pop ES
		mov AH, 49H
		int 21h 				; free resident program

		sti

		pop DS
		pop ES
		pop SI
		pop DX
		pop CX
		pop BX
		pop AX

		ret
	UNLOAD_INT ENDP

	MAIN PROC
		PUSH DS
		SUB AX, AX
		PUSH AX
		MOV AX, DATA
		MOV DS, AX

		mov KEEP_PSP, ES 	; save PSP to free it later

		call CHECK_TAIL
		mov BX, AX 			; BX=tail.startswith("/un")
		call CHECK_INT 		; AX=1 if int is loaded

		cmp BX, 1
		jne LOAD
		UNLOAD:
			cmp AX, 1
			jne NOT_LOADED
			call UNLOAD_INT
			mov DX, offset STR_RESTORE
			mov AH, 09h
			int 21h
			jmp CHECK_END
		LOAD:
			cmp AX, 1
			je LOADED
			call LOAD_INT
			mov DX, offset STR_LOAD
			mov AH, 09h
			int 21h
			jmp CHECK_END
		LOADED:
			mov DX, offset STR_EXISTS
			mov AH, 09h
			int 21h
			jmp CHECK_END
		NOT_LOADED:
			mov DX, offset STR_NOT_EXISTS
			mov AH, 09h
			int 21h
		CHECK_END:
		

		MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
	MAIN ENDP

CODE ENDS

DATA SEGMENT
	STR_EXISTS     db "Interruption already loaded",10,13,"$"
	STR_NOT_EXISTS db "Interruption isn't loaded",10,13,"$"
	STR_LOAD       db "Interruption successfully loaded",10,13,"$"
	STR_RESTORE    db "Restored interruption",10,13,"$"
DATA ENDS

AStack SEGMENT STACK
	DW 200 DUP(?)
AStack ENDS

END MAIN
