TESTPC SEGMENT
	   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	   ORG 100H
START: JMP BEGIN

PC db 0ffh
AT db 0fch
PCXT_1 db 0feh
PCXT_2 db 0fbh
PS230 db 0fch
PS25060 db 0f8h
PCjr db 0fdh
PCConv db 0f9h

PC_STRING db 'PC', 13, 10, '$'
PC_XT_STRING db 'PC/XT', 13, 10, '$'
AT_STRING db 'AT', 13, 10, '$'
PS230_STRING db 'PS2 model 30', 13, 10, '$'
PS25060_STRING db 'PS2 model 50/60', 13, 10, '$'
PS280_STRING db 'PS2 model 80', 13, 10, '$'
PCjr_STRING db 'PCjr', 13, 10, '$'
PCConv_STRING db 'PC Convertible', 13, 10, '$'
VERSION_STRING db '00.00', 13, 10, '$'
OEM_STRING db '0', 13, 10, '$'
NUMBER_STRING db '000', 13, 10, '$'

EXIT PROC near
	xor AL, AL
	mov AH, 4ch
	int 21h
	ret
EXIT ENDP

PRINT PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

TETR_TO_HEX PROC near
	and al, 0fh
	cmp al, 09
	jbe NEXT
	add al, 07
	NEXT:
		add al, 30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX
	pop cx
	ret
BYTE_TO_HEX ENDP

BYTE_TO_DEC PROC near
	push cx
	push dx
	xor ah, ah
	xor dx, dx
	mov cx, 10
	loop_bd:
		div cx
		or dl, 30h
		mov [si], dl
		dec si
		xor dx, dx
		cmp ax, 10
		jae loop_bd
		cmp al, 00h
		je end_l
		or al, 30h
		mov [si], al
	end_l:
		pop dx
		pop cx
	ret
BYTE_TO_DEC ENDP

BEGIN:
	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, PC
	je print_PC
	cmp al, PCXT_1
	je print_PC_XT
	cmp al, PCXT_2
	je print_PC_XT
	cmp al, AT
	je print_AT
	cmp al, PS230
	je print_PS2_30
	cmp al, PS25060
	je print_PS2_50_or_60
	cmp al, PS280_STRING
	je print_PS2_80
	cmp al, PCjr
	je print_PCjr
	cmp al, PCConv
	je print_PCConv

	jmp print_unknown

	print_PC:
		mov dx, offset PC_STRING
		jmp finish
	print_PC_XT:
		mov dx, offset PC_XT_STRING
		jmp finish
	print_AT:
		mov dx, offset AT_STRING
		jmp finish
	print_PS2_30:
		mov dx, offset PS230_STRING
		jmp finish
	print_PS2_50_or_60:
		mov dx, offset PS25060_STRING
		jmp finish
	print_PS2_80:
		mov dx, offset PS280_STRING
		jmp finish
	print_PCjr:
		mov dx, offset PCjr_STRING
		jmp finish
	print_PCConv:
		mov dx, offset PCConv_STRING
		jmp finish
	print_unknown:
		call BYTE_TO_HEX
		mov dx, ax
		mov ah, 02h
		int 21h
		xchg dl, dh
		int 21h
		jmp skip
	finish:
		call PRINT
	skip:

	mov ah, 30h
	int 21h
	mov dx, ax
	mov si, offset VERSION_STRING
	inc si
	call BYTE_TO_DEC
	mov si, offset VERSION_STRING
	add si, 4
	mov al, dh
	call BYTE_TO_DEC
	mov dx, offset VERSION_STRING
	call PRINT
	mov si, offset OEM_STRING
	mov al, bh
	mov dx, offset OEM_STRING
	call PRINT
	mov si, offset NUMBER_STRING
	mov al, bl
	call BYTE_TO_DEC
	mov si, offset NUMBER_STRING
	inc si
	mov al, cl
	call BYTE_TO_DEC
	mov si, offset NUMBER_STRING
	add si, 2
	mov al, ch
	call BYTE_TO_DEC
	mov dx, offset NUMBER_STRING
	call PRINT

	call EXIT
TESTPC ENDS
END START