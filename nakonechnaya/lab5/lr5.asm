AStack SEGMENT STACK
    dw 100h dup(?)
AStack ENDS

DATA SEGMENT
	LOADED_STR db 'Interruption loaded $'
	NOT_LOADED_STR db 'Interruption unloaded $'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack
	LOADED db ?
	ID dw 0FFFh
	KEEP_AX dw ?
	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_IP dw ?
	KEEP_CS dw ?
	PSP dw ?
ROUT PROC FAR
	jmp START
	INTER_STR db 'All is working $'
	INDEX db 0
	STACK_INTER dw 100h dup(?)
	END_STACK_INTER db ?
START:
	mov KEEP_SS, SS
 	mov KEEP_SP, SP
  	mov KEEP_AX, AX
	mov AX, CS
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
	call dword ptr cs:KEEP_IP;
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

LOAD_INTER PROC near
	push AX
	push CX
	push DX
	mov AH, 35h
	mov AL, 1Ch
	int 21h
	mov KEEP_IP, BX
	mov KEEP_CS, ES
	push DS
	mov DX, offset ROUT
	mov AX, seg ROUT
	mov DS, AX
	mov AH, 25h
	mov AL, 1ch
	int 21h
	pop DS
	mov DX, offset LAST_BYTE
	mov CL, 4h
	shr DX, CL
	add DX, CODE
	inc DX 
	xor AX, AX
	mov AH, 31h
	int 21h
	pop DX
	pop CX
	pop AX
	ret
LOAD_INTER ENDP

UNLOAD_INTER PROC near
	push AX
	push BX
	push DX
	push DI
	cli
	mov AH, 35h
	mov AL, 1Ch
	int 21h
	mov DI, offset KEEP_IP
	sub DI, offset ROUT
	mov DX, ES:[BX+DI]
	mov AX, ES:[BX+DI+2]
	push DS
	mov DS, AX
	mov AH, 25h
	mov AL, 1Ch
	int 21h
	pop DS
	mov AX, ES:[BX+DI+4]
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
	pop DI
	pop DX
	pop BX
	pop AX
	ret
UNLOAD_INTER ENDP

CHECK_UNLOAD PROC near
	mov AX, PSP
	mov ES, AX
	cmp byte ptr ES:[81h+1], '/'
		jne NOT_UN
	cmp byte ptr ES:[81h+2], 'u'
		jne NOT_UN
	cmp byte ptr ES:[81h+3], 'n'
		jne NOT_UN
	mov DX, offset NOT_LOADED_STR
	mov AH, 09h
    	int 21h
	call UNLOAD_INTER
	jmp STOP
NOT_UN:
	mov AL, LOADED 
	cmp AL, 1
		je STOP
	mov DX, offset LOADED_STR
	mov AH, 09h
    	int 21h
	call LOAD_INTER
STOP:
	ret
CHECK_UNLOAD ENDP

CHECK_LOAD PROC near
	push ES
	mov AH, 35h
	mov AL, 1Ch
	int 21h
	mov DX, ES:[BX-2]
	pop ES
	cmp DX, ID
		je GO
	jmp EXIT
	GO:
		mov LOADED, 1
	EXIT:
		ret
CHECK_LOAD ENDP

MAIN PROC far
	mov AX, DATA
	mov DS, AX
	mov AX, ES
	mov PSP, AX	
	call CHECK_LOAD
	call CHECK_UNLOAD
	
	; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
MAIN ENDP
CODE ENDS
END MAIN
