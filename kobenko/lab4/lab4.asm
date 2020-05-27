CODE    SEGMENT
ASSUME  CS:CODE,    DS:DATA,    SS:ASTACK

ROUT   PROC    FAR
        jmp     _start
		ROUTDATA:
		COUNTER            DB  "000 interruptions"
		SIGNATURE          DW  2228h
		KEEP_IP 	       DW  0
		KEEP_CS 	       DW  0
		KEEP_PSP 	       DW  0
		KEEP_AX 	       DW  0
		KEEP_SS        	       DW  0
		KEEP_SP 	       DW  0
		_STACK                 DW 128 dup(0)
    _start:
		mov 	KEEP_AX, AX
		mov 	KEEP_SP, SP
		mov 	KEEP_SS, SS
		mov 	AX, SEG _STACK
		mov 	SS, AX
		mov 	AX, offset _STACK
		add 	AX, 256
		mov 	SP, AX	

		push	AX
		push    BX
		push    CX
		push    DX
		push    SI
        push    ES
        push    DS
		mov 	AX, seg COUNTER
		mov 	DS, AX
        
        mov     AH, 03h
		mov     BH, 0h
		int     10h
        push    DX

        mov     AH, 02h
		mov     BH, 0h
		mov     DX, 1820h 
		int     10h

		mov 	AX, SEG COUNTER
		push 	DS
		mov 	DS, AX
		mov 	SI, offset COUNTER
		add		SI, 2
		mov 	CX, 3
	_icycle:
		mov 	AH, [SI]
		inc 	AH
		mov 	[SI], AH
		cmp 	AH, ':'
		jne 	_end_icycle
		mov 	AH, '0'
		mov 	[SI], AH
		dec 	SI
		loop 	_icycle		
	_end_icycle:
		pop 	DS

		push 	ES
		push	BP
        mov     AX, SEG COUNTER
		mov     ES, AX
		mov     BP, offset COUNTER
		mov     AH, 13h
		mov     AL, 1h
		mov 	BL, 6h
		mov     BH, 0
		mov     CX, 17
		int     10h

		pop		BP
		pop		ES

        pop     DX
        mov     AH, 02h
		mov     BH, 0h
		int     10h

		pop     DS
		pop     ES
		pop		SI
		pop     DX
		pop     CX
		pop     BX
		pop		AX

		mov 	SP, KEEP_SP
		mov 	AX, KEEP_SS
		mov 	SS, AX
	        mov 	AX, KEEP_AX

		mov     AL, 20h
		out     20h, AL
	iret
ROUT    ENDP
    _end:

IS_INT_L       PROC
		push    AX
		push    BX
		push    SI
		
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     SI, offset SIGNATURE
		sub     SI, offset ROUT
		mov     AX, ES:[BX + SI]
		cmp	    AX, SIGNATURE
		jne     _exit_is_l
		mov     IS_L, 1
		
	_exit_is_l:
		pop     SI
		pop     BX
		pop     AX
	ret
IS_INT_L       ENDP

INT_LOAD        PROC
        push    AX
		push    BX
		push    CX
		push    DX
		push    ES
		push    DS

        mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov     KEEP_CS, ES
        mov     KEEP_IP, BX
        mov     AX, seg ROUT
		mov     DX, offset ROUT
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop		DS

        mov     DX, offset _end
		mov     CL, 4h
		shr     DX, CL
		add		DX, 10Fh
		inc     DX
		xor     AX, AX
		mov     AH, 31h
		int     21h

        pop     ES
		pop     DX
		pop     CX
		pop     BX
		pop     AX
	ret
INT_LOAD        ENDP

INT_UNLOAD      PROC
        CLI
		push    AX
		push    BX
		push    DX
		push    DS
		push    ES
		push    SI
		
		mov     AH, 35h
		mov     AL, 1Ch
		int     21h
		mov 	SI, offset KEEP_IP
		sub 	SI, offset ROUT
		mov 	DX, ES:[BX + SI]
		mov 	AX, ES:[BX + SI + 2]
		
		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 1Ch
		int     21h
		pop 	DS
		
		mov 	AX, ES:[BX + SI + 4]
		mov 	ES, AX
		push 	ES
		mov 	AX, ES:[2Ch]
		mov 	ES, AX
		mov 	AH, 49h
		int 	21h
		pop 	ES
		mov 	AH, 49h
		int 	21h
		
		STI
		
		pop     SI
		pop     ES
		pop     DS
		pop     DX
		pop     BX
		pop     AX
		
	ret
INT_UNLOAD      ENDP

IS_FLAG_UN        PROC
        push    AX
		push    ES

		mov     AX, KEEP_PSP
		mov     ES, AX
		cmp     byte ptr ES:[82h], '/'
		jne     _exit_un
		cmp     byte ptr ES:[83h], 'u'
		jne     _exit_un
		cmp     byte ptr ES:[84h], 'n'
		jne     _exit_un
		mov     IS_UN, 1
		
	_exit_un:
		pop     ES
		pop     AX
		ret
IS_FLAG_UN        ENDP

PRINT    PROC    NEAR
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
    ret
PRINT   ENDP

MAIN PROC
		push    DS
		xor     AX, AX
		push    AX
		mov     AX, DATA
		mov     DS, AX
		mov     KEEP_PSP, ES
		
		call    IS_INT_L
		call    IS_FLAG_UN
		cmp     IS_UN, 1
		je      _unload
		mov     AL, IS_L
		cmp     AL, 1
		jne     _load
		mov     DX, offset LOADED
		call    PRINT
		jmp     _exit_
	_load:
		mov 	DX, offset LOAD
		call 	PRINT
		call    INT_LOAD
		jmp     _exit_
	_unload:
		cmp     IS_L, 1
		jne     _not_loaded
		mov 	DX, offset UNLOAD
		call 	PRINT
		call    INT_UNLOAD
		jmp     _exit_
	_not_loaded:
		mov     DX, offset NOT_LOADED
		call    PRINT
	_exit_:
		xor 	AL, AL
		mov 	AH, 4Ch
		int 	21h
	MAIN ENDP

CODE    ENDS

ASTACK  SEGMENT STACK
    DW  128 dup(0)
ASTACK  ENDS

DATA    SEGMENT
	LOAD           DB  "Interruption has loaded",10,13,"$"
	LOADED DB  "Interruption loaded already ",10,13,"$"
	UNLOAD         DB  "Interruption has unloaded",10,13,"$"
	NOT_LOADED     DB  "Interruption isn't loaded",10,13,"$"
        IS_L          DB  0
        IS_UN               DB  0
DATA    ENDS
END 	MAIN
