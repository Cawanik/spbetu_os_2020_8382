CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack
	
AStack SEGMENT STACK
    dw 100h dup(?)
AStack ENDS

DATA SEGMENT
	LOADED_STR db 'Interruption loaded $'
	NOT_LOADED_STR db 'Interruption unloaded $'
DATA ENDS

ROUT PROC far
	jmp START
	INTER_STR db 'All is working $'
	INDEX db 0
	ID dw 0FFFh
	KEEP_IP dw 0 
	KEEP_CS dw 0 
	PSP dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw	0	
	STACK_INTER dw 100 dup(?)
	END_STACK_INTER db 0
START:
	mov KEEP_SS, SS 
	mov KEEP_SP, SP 
	mov KEEP_AX, AX 
	mov AX, seg STACK_INTER 
	mov SS, AX 
	mov SP, offset END_STACK_INTER
	push BX
	push CX
	push DX
	push SI
	push DS
	push BP
	push ES
    	in AL, 60h
    	cmp AL, 2Ah 
		je DO_REQ
	pushf
	call dword ptr CS:KEEP_IP;
    	jmp ENDING;
DO_REQ:
	in AL, 61h 
	mov AH, AL 
	or AL, 80h 
	out 61h, AL 
	xchg AH, AL 
	out 61h, AL 
	mov AL, 20h 
	out 20h, AL 
	xor BX, BX
	mov BL, INDEX 
WRITE:
	mov AH, 05h
	mov CL, INTER_STR[BX]
	cmp CL, '$'
		je END_STR
	mov CH, 00h
	int 16h
	or AL, AL 
	jnz SKIP
	inc BL
	mov INDEX, BL
	jmp ENDING
SKIP:
	mov AX, 0C00h
	int 21h
	jmp WRITE
END_STR:
	mov INDEX, 0
ENDING:
	pop ES
	pop BP
	pop DS
	pop SI
	pop DX
	pop CX
	pop BX
	mov SP, KEEP_SP
	mov AX, KEEP_SS
	mov SS, AX
	mov AX, KEEP_AX
	mov AL, 20h
	out 20h, AL		
	iret 	
ROUT ENDP
LAST_BYTE:

LOAD_INTER PROC	near
	push AX
	push BX
	push ES
	push DX
	mov AH, 35h
	mov AL, 09h 
	int 21h
	mov KEEP_IP, BX
	mov KEEP_CS, ES
	push DS
	mov DX, offset ROUT 
	mov AX, seg ROUT 	    
	mov DS, AX
	mov AH, 25h		 
	mov AL, 09h         	
	int 21h
	pop DS
	mov DX, offset LAST_BYTE
	mov CL, 4h
	shr DX, CL
	inc DX
	add DX, 10h
	mov AH, 31h
	int 21h
	pop DX
	pop ES
	pop BX
	pop AX
	ret
LOAD_INTER ENDP

UNLOAD_INTER PROC near
	push AX
	push BX
	push DX
	push ES
	push SI
	cli 
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov SI, offset KEEP_IP
	sub SI, offset ROUT		
	push DS
	mov DX, ES:[BX + SI]
	mov AX, ES:[BX + SI + 2]
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	pop DS	
	mov AX, ES:[BX + SI + 4]
	mov ES, AX
	push ES
	mov AX, ES:[2Ch]
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	mov AH, 49h
	int 21h
	sti
	pop SI
	pop ES
	pop DX
	pop BX
	pop AX
	ret
UNLOAD_INTER ENDP

CHECK_UNLOAD PROC near
	cmp byte ptr ES:[81h+1], '/'
		jne NOT_UN
	cmp byte ptr ES:[81h+2], 'u'
		jne NOT_UN
	cmp byte ptr ES:[81h+3], 'n'
		jne NOT_UN
	mov BX, 1
NOT_UN:
	ret
CHECK_UNLOAD ENDP

CHECK_LOAD PROC near
	push BX
	push DX
	push SI
	push ES
	mov AH, 35h
	mov AL, 09h
	int 21h
	lea SI, ID
	sub SI, offset ROUT 
	mov AX, 1
	mov BX, ES:[BX + SI]
	cmp BX, ID
		je EXIT
	mov AX, 0
EXIT:
	pop ES
	pop SI
	pop DX
	pop BX
	ret
CHECK_LOAD ENDP

MAIN PROC far
	mov AX, DATA
	mov DS, AX
	mov AX, ES
	mov PSP, AX	
	call CHECK_LOAD
	call CHECK_UNLOAD
	cmp BX, 1
		je UNLOAD
LOAD:
	lea DX, LOADED_STR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	call LOAD_INTER
	jmp GO_DOS
UNLOAD:	
	lea DX, NOT_LOADED_STR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	call UNLOAD_INTER
	jmp GO_DOS
GO_DOS:
	; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
MAIN ENDP
CODE ENDS
END MAIN
