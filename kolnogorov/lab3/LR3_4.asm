TESTPC     SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
           ORG     100H

START:     JMP     BEGIN 
; data
NEW_LINE          db 10,13,'$'
STR_MEM_AVAILABLE db 'available memory:       bytes',10,13,'$'
STR_MEM_EXTENDED  db 'extended memory:       bytes',10,13,'$'
STR_FREE_SUCCESS  db 'successful free',10,13,'$'
STR_FREE_ERROR    db 'unsuccessful free',10,13,'$'
STR_ALLOCATE_SUCCESS  db 'successful allocation',10,13,'$'
STR_ALLOCATE_ERROR    db 'unsuccessful allocation',10,13,'$'
STR_MCB_SIZE      db 'size:         bytes',10,13,'$'
STR_OWNER         db 'owner: $'
STR_LAST_BYTES    db 'last bytes: $'
STR_FREE          db 'free$'
STR_OSXMSUBM      db 'OS XMS UMB$'
STR_TOP_MEM       db "driver's top memory$"
STR_MSDOS         db 'MS DOS$'
STR_TAKEN386      db "386MAX UMB's block$"
STR_BLOCKED386    db 'blocked by 386MAX$'
STR_OWNED386      db '386MAX UMB$'

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

BYTE_TO_DEC   PROC  near 
; convert AL to dec, SI - adress of low digit
           push     CX 
           push     DX 
           xor      AH,AH 
           xor      DX,DX 
           mov      CX,10 
loop_bd:   div      CX 
           or       DL,30h 
           mov      [SI],DL 
           dec      SI 
           xor      DX,DX 
           cmp      AX,10 
           jae      loop_bd 
           cmp      AL,00h 
           je       end_l 
           or       AL,30h 
           mov      [SI],AL 
end_l:     pop      DX 
           pop      CX 
           ret 
BYTE_TO_DEC    ENDP 

WORD_TO_DEC PROC near
; convert AX to dec, SI - adress of low digit
           push     CX 
           push     DX 
           mov      CX,10 
loop_bd2:  div      CX 
           or       DL,30h 
           mov      [SI],DL 
           dec      SI 
           xor      DX,DX 
           cmp      AX,0 
           jnz      loop_bd2
end_l2:    pop      DX 
           pop      CX 
           ret 
WORD_TO_DEC ENDP

; CODE
BEGIN: 

PRINT_AVAILABLE_MEMORY:
	mov AH, 4Ah
	mov BX, 0FFFFh
	int 21h
	mov AX, BX
	mov BX, 10h
	mul BX

	mov SI, offset STR_MEM_AVAILABLE
	add SI, 22
	call WORD_TO_DEC
	mov DX, offset STR_MEM_AVAILABLE
	mov AH, 09h
	int 21h

PRINT_EXTENDED_MEMORY:
	mov AL, 30h
	out 70h, AL
	in AL, 71h
	mov BL, AL
	mov AL, 31h
	out 70h, AL
	in AL, 71h
	mov AH, AL
	mov AL, BL

	mov SI, offset STR_MEM_EXTENDED
	add SI, 21
	xor DX, DX
	call WORD_TO_DEC
	mov DX, offset STR_MEM_EXTENDED
	mov AH, 09h
	int 21h

	call PRINT_NEW_LINE

ALLOCATE_MEMORY:
	mov BX, 1000h
	mov AH, 48h
	int 21h

	jnc ALLOCATE_SUCCESS
	jmp ALLOCATE_ERROR

	ALLOCATE_SUCCESS:
		mov DX, offset STR_ALLOCATE_SUCCESS
		jmp ALLOCATE_MEMORY_END
	ALLOCATE_ERROR:
		mov DX, offset STR_ALLOCATE_ERROR

	ALLOCATE_MEMORY_END:
	mov AH, 09h
	int 21h

FREE_MEMORY:
	mov BX, offset END_OF_PROGRAM
	add BX, 10h
	shr BX, 1
	shr BX, 1
	shr BX, 1
	shr BX, 1

	mov AH, 4Ah
	int 21h

	jnc FREE_SUCCESS
	jmp FREE_ERROR

	FREE_SUCCESS:
		mov DX, offset STR_FREE_SUCCESS
		jmp FREE_MEMORY_END
	FREE_ERROR:
		mov DX, offset STR_FREE_ERROR

	FREE_MEMORY_END:
	mov AH, 09h
	int 21h

PRINT_MCBS:
	; get first mcb's address
	mov AH, 52h
	int 21h
	mov AX, ES:[BX-2]
	mov ES, AX
	mov CX, 0

	NEXT_MCB:
		call PRINT_NEW_LINE
		inc CX
		mov AL, CL
		call PRINT_BYTE
		call PRINT_NEW_LINE

		mov DX, offset STR_OWNER
		mov AH, 09h
		int 21h

		; get owner
		mov BX, ES:[1h]

		; match owner
		mov DX, offset STR_FREE
		cmp BX, 0000h
		je MCB_MATCHED
		mov DX, offset STR_OSXMSUBM
		cmp BX, 0006h
		je MCB_MATCHED
		mov DX, offset STR_TOP_MEM
		cmp BX, 0007h
		je MCB_MATCHED
		mov DX, offset STR_MSDOS
		cmp BX, 0008h
		je MCB_MATCHED
		mov DX, offset STR_TAKEN386
		cmp BX, 0FFFAh
		je MCB_MATCHED
		mov DX, offset STR_BLOCKED386
		cmp BX, 0FFFDh
		je MCB_MATCHED
		mov DX, offset STR_OWNED386
		cmp BX, 0FFFEh
		je MCB_MATCHED

		jmp MCB_NOT_MATCHED

		; print owner
		MCB_MATCHED:
			mov AH, 09h
			int 21h
			jmp MCB_MATCH_END
		MCB_NOT_MATCHED:
			mov AL, BH
			call PRINT_BYTE
			mov AL, BL
			call PRINT_BYTE

		MCB_MATCH_END:
		call PRINT_NEW_LINE
	
		; get size
		mov AX, ES:[3h]
		mov BX, 10h
		mul BX
		
		; print size
		mov SI, offset STR_MCB_SIZE
		add SI, 11
		call WORD_TO_DEC
		mov DX, offset STR_MCB_SIZE
		mov AH, 09h
		int 21h

		; print last 8 bytes
		mov DX, offset STR_LAST_BYTES
		mov AH, 09h
		int 21h

		push CX
		mov CX, 8
		mov BX, 0
		mov AH, 02h
		PRINT_LAST_BYTES:
			mov DL, ES:[BX+8h]
			int 21h
			inc BX
			loop PRINT_LAST_BYTES
			call PRINT_NEW_LINE
		pop CX

		; check if last block
		mov AL, ES:[0h]
		cmp AL, 5Ah
		je PRINT_MCBS_END

		; get next block's address
		mov AX, ES:[3h]
		mov BX, ES
		add BX, AX
		inc BX
		mov ES, BX

		jmp NEXT_MCB

	PRINT_MCBS_END:



; return to DOS
           xor     AL,AL 
           mov     AH,4Ch 
           int     21H 

   END_OF_PROGRAM:
TESTPC     ENDS 
           END     START     ; module end START - entry point
