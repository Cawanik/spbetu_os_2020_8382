AStack    SEGMENT  STACK
    DW 100 dup(?)   
AStack    ENDS

DATA  SEGMENT
	STR_OVL1_NAME db 'OVERLAY1.OVL $'
	STR_OVL2_NAME db 'OVERLAY2.OVL $'
	MEM_ERROR7_STR db 'Memory control block destroyed ',13,10,'$'
	MEM_ERROR8_STR db 'Not enough memory to execute function ',13,10,'$'
	MEM_ERROR9_STR db 'Invalid memory block address ',13,10,'$'
	PATH db 128 dup (0)
	PARAMETERS dw 0,0
	ADDRESS dd 0
	DTA db 43 dup(0)
	STR_ERROR_FREE_MEMORY db 'Error free memory ',13,10,'$'
	STR_ERROR_1 db 'Function does not exist ', 13,10,'$'
	STR_ERROR_2 db 'File not found ',13,10,'$'
	STR_ERROR_3 db 'Route not found ',13,10,'$'
	STR_ERROR_4 db 'Too many files were opened ',13,10,'$'
	STR_ERROR_5 db 'No access ',13,10,'$'
	STR_MEMORY_8 db 'Low memory size for function ',13,10,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack

GET_SIZE PROC NEAR
	push AX
	push BX
	push CX
	push DX
	push BP	
	mov AH, 1Ah
	lea DX, DTA
	int 21h
	mov AH, 4Eh
	lea DX, PATH
	mov CX, 0
	int 21h
	jnc MEM
	lea DX, STR_ERROR_2
	cmp AX, 2
		je WRITE_ERR
	lea DX, STR_ERROR_3
	cmp AX, 3
	je WRITE_ERR	
WRITE_ERR:
	push AX
	mov AH,09h
	int 21h
	pop AX
	jmp ENDING

MEM:
	mov SI, offset DTA
	add SI, 1Ah
	mov BX, [SI]	
	shr BX, 4 
	mov AX, [SI + 2]	
	shl AX, 12
	add BX, AX
	add BX, 2
	mov AH,48h
	int 21h
	jnc SAVE
	lea DX, STR_ERROR_FREE_MEMORY
	push AX
	mov AH,09h
	int 21h
	pop AX
    	jmp ENDING
SAVE:
	mov PARAMETERS, AX
	mov PARAMETERS + 2, AX
ENDING:	
	pop BP
	pop DX
	pop CX
	pop BX
	pop AX
	ret
GET_SIZE ENDP

LOAD_OVL PROC NEAR
	push AX
	push DX
	push ES	
	lea DX, PATH
	push DS
	pop ES
	lea BX, PARAMETERS
	mov AX, 4B03h            
    	int 21h
	jnc LOAD
	lea DX, STR_ERROR_1
	cmp AX, 1
		je L_ERR
	lea DX, STR_ERROR_2
	cmp AX, 2
		je L_ERR
	lea DX, STR_ERROR_3
	cmp AX, 3
		je L_ERR
	lea DX, STR_ERROR_4
	cmp AX, 4
		je L_ERR
	lea DX, STR_ERROR_5
	cmp AX, 5 
		je L_ERR
	lea DX, STR_MEMORY_8
	cmp AX, 8
		je L_ERR
L_ERR:
	push AX
	mov AH,09h
	int 21h
	pop AX
	jmp GO_END
LOAD:
	mov AX, PARAMETERS
	mov word ptr ADDRESS + 2, AX
	call ADDRESS
	mov ES, AX
	mov AH, 49h
	int 21h
GO_END:
	pop ES
	pop DX
	pop AX
	ret
LOAD_OVL ENDP

FILE_NAME PROC NEAR
	push DX
	push DI
	push SI
	push ES   
	xor DI, DI
	mov ES, ES:[2ch]
SKIP:
	mov DL, ES:[DI]
	cmp DL, 0h
		je LAST
	inc DI
	jmp SKIP
LAST:
	inc DI
	mov DL, ES:[DI]
	cmp DL, 0h
	jne SKIP
	add DI, 3h
	mov SI, 0   
WRITE:
	mov DL, ES:[DI]
	cmp DL, 0h
		je DELETE
	mov PATH[SI], DL 
	inc DI
	inc SI
	jmp WRITE
DELETe:
	dec SI
	cmp PATH[si], '\'
		je READY
	jmp DELETE
READY:
	mov DI,-1
ADD_NAME:
	inc SI
	inc DI
	mov DL, BX[DI]
	cmp DL, '$'
		je PATH_END
	mov PATH[SI], DL
	jmp ADD_NAME
PATH_END:
	mov PATH[SI],'$'
	pop ES
	pop SI
	pop DI
	pop DX
	ret
FILE_NAME ENDP

FREE_MEMORY PROC
	push AX
	push BX
	mov BX, 4096
	mov AH, 4Ah
	int 21h
	jnc MEM_END
	mov DX, offset MEM_ERROR7_STR
	cmp AX,7
		je MEM_WRITE
	mov DX, offset MEM_ERROR8_STR
	cmp AX,8
		je MEM_WRITE
	mov DX, offset MEM_ERROR9_STR
	cmp AX,9
		je MEM_WRITE
MEM_END:   
	pop BX
	pop AX
	ret
MEM_WRITE:
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
FREE_MEMORY ENDP

Main PROC FAR
	mov AX, DATA
	mov DS, AX   
	call FREE_MEMORY
	push DX
   	push BX
	lea BX, STR_OVL1_NAME
   	call FILE_NAME
   	pop BX
	lea DX, PATH
	push AX
	mov AH, 09h
	int 21h
	pop AX
	call GET_SIZE
	call LOAD_OVL
	pop DX
	push DX
   	push BX
	lea BX, STR_OVL2_NAME
   	call FILE_NAME
   	pop BX
	lea DX, PATH
	push AX
	mov AH, 09h
	int 21h
	pop AX
	call GET_SIZE
	call LOAD_OVL
	pop DX
   
    ;Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21h
Main ENDP
CODE ENDS
      END Main
