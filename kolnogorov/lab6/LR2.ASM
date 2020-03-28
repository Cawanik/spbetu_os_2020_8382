TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
           ORG     100H

START:     JMP     BEGIN 
; data
NEW_LINE          db 10,13,'$'
STR_SEG_MEM       db 'unavailable memory: $'
STR_ENV_ADDR      db 'environment memory: $'
STR_TAIL          db 'tail: $'
STR_NO_TAIL       db 'no tail',10,13,'$'
STR_ENV_VARIABLES db 'environment variables:',10,13,'$'
STR_PATH          db 'path: $'

PRINT_NEW_LINE  PROC near
	push DX
	push AX

	mov DX, offset NEW_LINE
	mov AH, 09h
	int 21h

	pop AX
	pop DX
	ret
PRINT_NEW_LINE  ENDP

PRINT_BYTE      PROC near
; prints AL as two hex digits
	push BX
	push DX

	call BYTE_TO_HEX
	mov BH, AH

	mov DL, AL
	mov AH, 02h
	int 21h

	mov DL, BH
	mov AH, 02h
	int 21h

	pop DX
	pop BX
	ret
PRINT_BYTE    ENDP
TETR_TO_HEX 	PROC near
	and      AL,0Fh 
	cmp      AL,09 
	jbe      NEXT 
	add      AL,07 
NEXT:
	add      AL,30h 
	ret 
TETR_TO_HEX   ENDP 
;------------------------------- 
BYTE_TO_HEX   PROC  near 
; AL --> two hex symbols in AX 
	push     CX 
	mov      AH,AL 
	call     TETR_TO_HEX 
	xchg     AL,AH 
	mov      CL,4 
	shr      AL,CL 
	call     TETR_TO_HEX ; AL - high digit
	pop      CX          ; AH - low digit
	ret 
BYTE_TO_HEX  ENDP 
;------------------------------- 
; CODE
BEGIN: 

PRINT_SEG_MEM:
	mov DX, offset STR_SEG_MEM
	mov AH, 09h
	int 21h

	mov BX, DS:[02h]
	mov AL, BH
	call PRINT_BYTE
	mov AL, BL
	call PRINT_BYTE

	call PRINT_NEW_LINE
PRINT_ENV_ADDR:
	mov DX, offset STR_ENV_ADDR
	mov AH, 09h
	int 21h

	mov BX, DS:[2Ch]
	mov AL, BH
	call PRINT_BYTE
	mov AL, BL
	call PRINT_BYTE
	
	call PRINT_NEW_LINE
PRINT_TAIL:
	mov DX, offset STR_TAIL
	mov AH, 09h
	int 21h

	mov CH, 0
	mov CL, DS:[80H]
	cmp CL, 0
	je no_tail

	mov BX, 0
	tail_loop:
		mov DL, DS:[81H+BX]
		mov AH, 02H
		int 21h

		inc BX
		loop tail_loop

	call PRINT_NEW_LINE
	jmp tail_end
	no_tail:
	mov DX, offset STR_NO_TAIL
	mov AH, 09h
	int 21h
	tail_end:

PRINT_ENV_CONTENTS:
	mov DX, offset STR_ENV_VARIABLES
	mov AH, 09h
	int 21h
	
	mov ES, DS:[2Ch]
	mov BX, 0
	print_env_variable:
		mov DL, ES:[BX]
		cmp DL, 0
		je new_variable

		mov AH, 02h
		int 21h

		jmp variable_end
	new_variable:
		call PRINT_NEW_LINE
	variable_end:
		inc BX
		mov DX, ES:[BX]
		cmp DX, 0
		je env_content_end
		jmp print_env_variable
	env_content_end:
	call PRINT_NEW_LINE
	
	add BX, 1

PRINT_MODULE_PATH:
	mov DX, offset STR_PATH
	mov AH, 09h
	int 21h
	add BX, 3
	path_loop:
		mov DL, ES:[BX]
		cmp DL, 0
		jne path_next
		je loop_end
	path_next:
		mov AH, 02H
		int 21h
		inc BX
		jmp path_loop
	loop_end:
	call PRINT_NEW_LINE

	mov AH, 01h
	int 21h

; return to DOS
           mov     AH,4Ch 
           int     21H 
TESTPC     ENDS 
           END     START     ; module end START - entry point
