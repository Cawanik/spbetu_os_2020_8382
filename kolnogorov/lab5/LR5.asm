CODE SEGMENT

	ASSUME  CS:CODE, DS:DATA, ES:NOTHING, SS:AStack
	
	MY_INT PROC FAR
		jmp MY_INT_START
	MY_INT_DATA:
		KEEP_IP   dw 0
		KEEP_CS   dw 0
		KEEP_PSP  dw 0
		SIGNATURE dw 1234h
		
	MY_INT_START:	
		push AX
		push BX
		push CX
		push DX
		push SI
		push DS
		push ES

		; set DS to int's data segment
		mov AX, SEG KEEP_IP
		mov DS, AX
				
		; check if key matches
		in AL, 60h
		cmp AL, 02h
		jl KEY_DID_NOT_MATCH
		cmp AL, 0Ah
		jg KEY_DID_NOT_MATCH
		jmp KEY_MATCHED

		KEY_DID_NOT_MATCH:
			; call original vec and exit int
			pushf
			call DWORD PTR CS:KEEP_IP
			jmp MY_INT_END
		
	KEY_MATCHED:
		; increase digit
		sub AL, 01h
		mov CL, '1'
		add CL, AL
		cmp CL, '9'
		jle NO_OVERFLOW
		mov CL, '1'
		NO_OVERFLOW:
			
		; some required stuff
		in AL, 61h
		mov AH, AL
		or AL, 80h
		out 61h, AL
		xchg AH, AL
		out 61h, AL
		mov AL, 20h
		out 20h, AL
		
		; write char into keyboard buffer
		mov AH, 05h
		mov CH, 00h
		int 16h
		
	MY_INT_END:	
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
	MY_INT_LAST_BYTE:

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
		mov AL, 09h
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
		mov AL, 09h
		int 21h
		mov KEEP_IP, BX
		mov KEEP_CS, ES

		; set new int
		push DS
		mov DX, offset MY_INT
		mov AX, seg MY_INT
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
		int 21h
		pop DS

		; make resident
		mov DX, offset MY_INT_LAST_BYTE
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
		mov AL, 09h
		int 21h

		; get int's data offset
		mov SI, offset KEEP_IP
		sub SI, offset MY_INT

		mov DX, ES:[BX+SI] 	 	; ip
		mov AX, ES:[BX+SI+2] 	; cs
		push DS
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
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
