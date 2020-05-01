AStack SEGMENT STACK
	DW 128 DUP(?)
AStack ENDS


DATA SEGMENT
	NEW_LINE        db 						   0DH,0AH,'$'
	STR_PC_TYPE     db 'IBM PC type: $'
	STR_DOS_VERSION db 'MSDOS version: $'
	STR_OEM_NUMBER  db 'OEM serial number: $'
	STR_USER_NUMBER db 'User serial number: $'
	DOS_VERSION     db '00.00',                0DH,0AH,'$'
	TYPE1           db 'PC',                   0DH,0AH,'$'
	TYPE2           db 'PC/XT',                0DH,0AH,'$'
	TYPE3           db 'AT',                   0DH,0AH,'$'
	TYPE4           db 'PS2 модель 30',        0DH,0AH,'$'
	TYPE5           db 'PS2 модель 50 или 60', 0DH,0AH,'$'
	TYPE6           db 'PS2 80',               0DH,0AH,'$'
	TYPE7           db 'PCjr',                 0DH,0AH,'$'
	TYPE8           db 'PC Convertible',       0DH,0AH,'$'
DATA ENDS


CODE SEGMENT
		ASSUME SS:AStack,DS:DATA,CS:CODE

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
NEXT:      add      AL,30h 
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
WRD_TO_HEX   PROC  near 
; AX --> hex, DI - adress of last symbol
           push     BX 
           mov      BH,AH 
           call     BYTE_TO_HEX 
           mov      [DI],AH 
           dec      DI 
           mov      [DI],AL 
           dec      DI 
           mov      AL,BH 
           call     BYTE_TO_HEX 
           mov      [DI],AH 
           dec      DI 
           mov      [DI],AL 
           pop      BX 
           ret 
WRD_TO_HEX ENDP 
;--------------------------------------------------
BYTE_TO_DEC   PROC  near 
; AL --> dec, SI - adress of lower digit
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
;-------------------------------
; CODE
BEGIN 		  PROC far 
		mov  AX, DATA
		mov  DS, AX

		mov DX, offset STR_PC_TYPE
        mov AH, 09h
        int 21h

        mov AX, 0F000h
        mov ES, AX
        mov AX, ES:[0FFFEh]
        mov DX, 0
TEST_TYPE1:
        mov DX, offset TYPE1
        cmp al, 0FFh
        je WRITE_TYPE
TEST_TYPE2:
        mov DX, offset TYPE2
        cmp al, 0FEh
        je WRITE_TYPE
        cmp al, 0FBh
        je WRITE_TYPE
TEST_TYPE3:
        mov DX, offset TYPE3
        cmp al, 0FCh
        je WRITE_TYPE
TEST_TYPE4:
        mov DX, offset TYPE4
        cmp al, 0FAh
        je WRITE_TYPE
TEST_TYPE5:
        mov DX, offset TYPE5
        cmp al, 0FCh
        je WRITE_TYPE
TEST_TYPE6:
        mov DX, offset TYPE6
        cmp al, 0F8h
        je WRITE_TYPE
TEST_TYPE7:
        mov DX, offset TYPE7
        cmp al, 0FDh
        je WRITE_TYPE
TEST_TYPE8:
        mov DX, offset TYPE8
        cmp al, 0F9h
		je WRITE_TYPE
DOESNT_MATCH:
		call PRINT_BYTE
		mov DX, offset NEW_LINE
WRITE_TYPE:
        mov AH, 09h
        int 21h
TYPE_END:

PRINT_VERSION:
		mov DX, offset STR_DOS_VERSION
        mov AH, 09h
        int 21h

		mov AH, 30h
		int 21h

		mov SI, offset DOS_VERSION
		add SI, 1
		call BYTE_TO_DEC

		add SI, 3
		mov AL, AH
		call BYTE_TO_DEC

		mov DX, offset DOS_VERSION
		mov AH, 09h
		int 21h

PRINT_OEM:
		mov DX, offset STR_OEM_NUMBER
        mov AH, 09h
        int 21h

		mov AH, 30h
		int 21h

		mov AL, BH
		call PRINT_BYTE

PRINT_SERIAL:
		mov DX, offset NEW_LINE
        mov AH, 09h
        int 21h

		mov DX, offset STR_USER_NUMBER
        mov AH, 09h
        int 21h

		mov AH, 30h
		int 21h

		mov AL, BL
		call PRINT_BYTE
		mov AL, CH
		call PRINT_BYTE
		mov AL, CL
		call PRINT_BYTE

; return to DOS
           xor     AL,AL 
           mov     AH,4Ch 
           int     21H 
BEGIN  	ENDP
CODE    ENDS 
END     BEGIN     ; module end START - entry point
