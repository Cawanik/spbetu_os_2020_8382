; осталось распихать код в "код сегмент", а данные в "дата сегмент"
ASTACK SEGMENT STACK
	dw 100h dup(?)
ASTACK ENDS

DATA SEGMENT
	TypePc db 'IBM PC type - ', '$'
	FF db 'PC',10,13,'$'
	FE_FB db 'PC/XT',10,13,'$'
	FA db 'PS2 ver. 30',10,13,'$'
	FC db 'PS2 ver. 50/60 or AT',10,13,'$'
	F8 db 'PS2 ver. 80',10,13,'$'
	FD db 'PCjr',10,13,'$'
	F9 db 'PC Convertible',10,13,'$'
	TypeMSDOS db 'Your MSDOS type is ','$'
	OLD db '<2.0',10,13,'$'
	NEW db '0x.0y',10,13,'$'
	SERIAL db 'SERIAL OEM number is ','$'
	SERIAL2 db 10,13,'SERIAL user number is ','$'
DATA ENDS

CODE SEGMENT
	assume SS:AStack, DS:DATA, CS:CODE

PRINT PROC near
	push CX
	push DX

	call BYTE_TO_HEX
	mov CH, AH

	mov DL, AL
	mov AH, 02h
	int 21h

	mov DL, CH
	mov AH, 02h
	int 21h

	pop DX
	pop CX
	ret
PRINT ENDP

TETR_TO_HEX PROC near 
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

BEGIN PROC far
	mov ax, DATA
	mov ds, ax
;--------------
	mov ax,0F000h
	mov es,ax 
	mov al,es:[0FFFEh] 
	
	mov DX,offset TypePc
	mov AH,09h
	int 21h
	
	mov DX,offset FF
	cmp al, 0FFh
	je gogo
	mov DX,offset FE_FB
	cmp al, 0FEh
	je gogo
	cmp al, 0FBh
	je gogo
	mov DX,offset FC
	cmp al, 0FCh
	je gogo
	mov DX,offset FA
	cmp al, 0FAh
	je gogo
	mov DX,offset F8
	cmp al, 0F8h
	je gogo
	mov DX,offset FD
	cmp al, 0FDh
	je gogo
	mov DX,offset F9
	cmp al, 0F9h
	jne exception
exception:
	call print
gogo:
	mov AH,09h
	int 21h
	
	mov DX,offset TypeMSDOS
	mov AH,09h
	int 21h
	
	mov AH,30h
	int 21h
	
	cmp AL,0
	jne modern
	mov DX,offset OLD
	mov AH,09h
	int 21h
modern:
	mov SI,offset NEW
	add SI,1
	call BYTE_TO_DEC
	add SI,4
	mov AL,AH
	call BYTE_TO_DEC
	mov DX,offset NEW
	mov AH,09h
	int 21h
	
	mov AH,30h
	int 21h
	
	mov DX,offset SERIAL
	mov AH,09h
	int 21h
	mov AL,BH
	call BYTE_TO_DEC
	mov DL, [SI]
	mov AH, 02h
	int 21h
	mov DL, [SI+1]
	int 21h
	mov DL, [SI+2]
	int 21h
	
	mov AH,30h
	int 21h
	
	mov DX,offset SERIAL2
	mov AH,09h
	int 21h
	mov AL, BL
	call PRINT
	mov AL, CH
	call PRINT
	mov AL, CL
	call PRINT
		
	xor AL,AL
	mov AH,4Ch
	int 21H
BEGIN ENDP
CODE ENDS
END BEGIN