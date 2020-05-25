CODE    SEGMENT
ASSUME  CS:CODE,    DS:DATA,    SS:ASTACK

ROUT   PROC    FAR
        jmp     _start
		ROUTDATA:
		KEY                DB  0
		SIGNATURE          DW  2228h
		KEEP_IP 	       DW  0
		KEEP_CS 	       DW  0
		KEEP_PSP 	       DW  0
		
    _start:
		push	AX
		push    BX
		push    CX
		push    DX
		push    SI
        push    ES
        push    DS
		mov 	AX, seg KEY
		mov 	DS, AX
        
		in AL, 60h
		cmp AL, 23h	;"H I J K"
		je K_C
		cmp AL, 17h
		je K_S
		cmp AL, 24h
		je K_G
		cmp AL, 25h
		je K_O
		
		pushf
		call 	DWORD PTR CS:KEEP_IP
		jmp 	_endR

	K_C:
		mov KEY, 'C'
		jmp _next
	K_S:
		mov KEY, 'S'
		jmp _next
	K_G:
		mov KEY, 'G'
		jmp _next
	K_O:
		mov KEY, 'O'

	_next:
		in 		AL, 61h
		mov 	AH, AL
		or 		AL, 80h
		out 	61h, AL
		xchg	AL, AL
		out 	61h, AL
		mov 	AL, 20h
		out 	20h, AL
			
	_printK:
		mov 	AH, 05h
		mov 	CL, KEY
		mov 	CH, 00h
		int 	16h
		or 		AL, AL
		jz 		_endR
		mov 	AX, 0040h
		mov 	ES, AX
		mov 	AX, ES:[1Ah]
		mov 	ES:[1Ch], AX
		jmp 	_printK

	_endR:
		pop     DS
		pop     ES
		pop		SI
		pop     DX
		pop     CX
		pop     BX
		pop		AX

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
		mov     AL, 09h
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
		mov     AL, 09h
		int     21h
		mov     KEEP_CS, ES
        mov     KEEP_IP, BX
        mov     AX, seg ROUT
		mov     DX, offset ROUT
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
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
		mov     AL, 09h
		int     21h
		mov 	SI, offset KEEP_IP
		sub 	SI, offset ROUT
		mov 	DX, ES:[BX + SI]
		mov 	AX, ES:[BX + SI + 2]
		
		push 	DS
		mov     DS, AX
		mov     AH, 25h
		mov     AL, 09h
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
