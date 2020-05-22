MEMORYRESEARCH SEGMENT
	   ASSUME CS:MEMORYRESEARCH, DS:MEMORYRESEARCH, ES:NOTHING, SS:NOTHING
	   ORG 100H
START: JMP MAIN

AVAILABLE_MEMORY db '000000', 10, 13, '$'
EXPANDED_MEMORY db '00000', 10, 13, '$'
MCB_INFO db 'Type = 00; Owner = 0000; Size = 000000; Last 8 bytes = ', '$'
MCB_INFO_END db ';', 10, 13, '$'

TETR_TO_HEX proc near
  	and al, 0fh
  	cmp al, 09
  	jbe next
  	add al, 07
  	next:
	add al, 30h
    ret
TETR_TO_HEX endp

BYTE_TO_HEX proc near
  	push cx
  	mov ah, al
  	call tetr_to_hex
  	xchg al, ah
  	mov cl, 4
  	shr al, cl
  	call tetr_to_hex
  	pop cx
  	ret
BYTE_TO_HEX endp

CALC_AVAILABLE_MEMORY PROC near
	push ax
	push bx
	push dx
	push si
	mov ah, 4ah
	mov bx, 0ffffh
	int 21h

	mov ax, 16
	mul bx
	mov si, offset AVAILABLE_MEMORY
	add si, 5
	CALL WRD_TO_DEC

	mov dx, offset AVAILABLE_MEMORY
	call PRINT
	pop si
	pop dx
	pop bx
	pop ax
	ret
CALC_AVAILABLE_MEMORY ENDP

CALC_EXTENDED_MEMORY PROC near
	push ax
	push si
	mov al, 30h
  	out 70h, al
  	in al, 71h
  	mov bl, al
  	mov al, 31h
  	out 70h, al
  	in al, 71h

	mov ah, al
  	mov al, bl
	mov dx, 0

	mov si, offset EXPANDED_MEMORY
	add si, 4
	
	CALL WRD_TO_DEC

	mov dx, offset EXPANDED_MEMORY
	call PRINT
	pop si
	pop ax
	ret
CALC_EXTENDED_MEMORY ENDP

PRINT_MCBs PROC near
	push ax
	push bx
	push dx

	mov ah, 52h
	int 21h
	mov es, es:[bx-2]

	PRINT_MCB:
		mov al, es:[0h]
		call BYTE_TO_HEX
		mov si, offset MCB_INFO
		add si, 7
		mov [si], ax

		add si, 14
		mov bx, es:[1h]
		mov al, bl
		call BYTE_TO_HEX
		mov [si], ax
		sub si, 2
		mov al, bh
		call BYTE_TO_HEX
		mov [si], ax

		add si, 18
		mov ax, es:[3h]
		mov bx, 16
		mul bx
		call WRD_TO_DEC

		mov dx, offset MCB_INFO
		call PRINT

		mov si, 8h
    	mov cx, 8
		mov ah, 2h
    	PRINT_SMB:
			mov dl, es:[si]
			int 21h
      		inc si
      		loop PRINT_SMB

		mov dx, offset MCB_INFO_END
		call PRINT

		mov al, es:[0h]
		cmp al, 5ah
		je FINISH

		mov ax, es
    	add ax, es:[3h]
    	inc ax
    	mov es, ax
    	jmp PRINT_MCB

	FINISH:
	pop dx
	pop bx
	pop ax
	ret
PRINT_MCBs ENDP

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

WRD_TO_DEC PROC near
	push bx
  	mov bx, 10
  	DIVISION:
    	div bx
    	add dl, 30h
    	mov [si], dl
    	xor dx, dx
    	dec si
    	cmp ax, 0
    	jne DIVISION
	pop bx
  	ret
WRD_TO_DEC ENDP

MAIN:
	call CALC_AVAILABLE_MEMORY
	mov ah, 4ah
	mov bx, offset END_LABEL
	int 21h

	mov ah, 4ah
	mov bx, 4096
	int 21h
	call CALC_EXTENDED_MEMORY
	call PRINT_MCBs

	call EXIT
	END_LABEL:
MEMORYRESEARCH ENDS
END START