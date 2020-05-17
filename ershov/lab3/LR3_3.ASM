TESTMEMORY SEGMENT
	   ASSUME CS:TESTMEMORY, DS:TESTMEMORY, ES:NOTHING, SS:NOTHING
	   ORG 100H
START: JMP MAIN

AVAILABLE_MEMORY_title db 'AVAILABLE_MEMORY(bytes): ', 10, 13, '$'
EXTENDED_MEMORY_title db 'EXTENDED_MEMORY(kilobytes):', 10, 13, '$'
MCB_title db 'MCB:', 10, 13, '$'
AVAILABLE_MEMORY db '000000', 10, 13, '$'
EXPANDED_MEMORY db '00000', 10, 13, '$'
MCB_TYPE db 'MCBtype = 00h', '$'
MCB_SIZE db ' Size = 000000', '$'
MCB_OWNER db '  Owner = 0000', '$'
MCB_TAIL db ' Tail = ', '$'
ENTER_ db  10, 13, '$'

TETR_TO_HEX proc near
  	and al, 0fh
  	cmp al, 09
  	jbe NEXT
  	add al, 07
  	NEXT:
		add al, 30h
		ret
TETR_TO_HEX endp

BYTE_TO_HEX proc near
  	push cx
  	mov ah, al
  	call TETR_TO_HEX
  	xchg al, ah
  	mov cl, 4
  	shr al, cl
  	call TETR_TO_HEX
  	pop cx
  	ret
BYTE_TO_HEX endp

EXIT PROC near
	xor AL, AL
	mov AH, 4ch
	int 21h
	ret
EXIT ENDP

PRINT_STR PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_STR ENDP

WRD_TO_DEC PROC near
	push bx
  	mov bx, 10	
  	convertion:
    	div bx
    	add dl, 30h
    	mov [si], dl
    	xor dx, dx
    	dec si
    	cmp ax, 0
    	jne convertion
	pop bx
  	ret
WRD_TO_DEC ENDP


MAIN:
	
	mov dx, offset AVAILABLE_MEMORY_title
	call PRINT_STR
	mov ah, 4ah
	mov bx, 0ffffh; заведомо большая память
	int 21h; bx - наибольший доступный блок памяти
	mov ax, 16;преобразование в байты
	mul bx
	mov si, offset AVAILABLE_MEMORY
	add si, 5	
	call WRD_TO_DEC
	mov dx, offset AVAILABLE_MEMORY
	call PRINT_STR
	
	mov dx, offset EXTENDED_MEMORY_title
	call PRINT_STR
	mov al, 30h
  	out 70h, al
  	in al, 71h;чтение младшего байта расширенной памяти
  	mov bl, al
    mov al, 31h
  	out 70h, al
  	in al, 71h;чтение старшего байта расширенной памяти	
	mov ah, al
  	mov al, bl
	xor dx, dx	
	mov si, offset EXPANDED_MEMORY
	add si, 4
	call WRD_TO_DEC
	mov dx, offset EXPANDED_MEMORY
	call PRINT_STR
	
	;освобождение незанятой памяти
	mov ah, 4ah
	mov bx, offset programmEND
	int 21h
	
	;запрос 64кб
	mov ah, 48h
	mov bx, 4096
	int 21h
	
	mov dx, offset MCB_title
	call PRINT_STR
	mov ah, 52h;возвращаем адрес векторной таблицы
	int 21h
	mov es, es:[bx-2];адрес первого MCB		
	printMCB:
		mov al, es:[0h]
		push ax
		call BYTE_TO_HEX
		mov si, offset MCB_TYPE
		add si, 10
		mov [si], ax
		mov dx, offset MCB_TYPE
		call PRINT_STR
		
		mov ax, es:[1h]
		mov si, offset MCB_OWNER
		add si, 12
		push ax
		xor ah, ah
		call BYTE_TO_HEX
		mov [si], ax
		pop ax
		xor al, al
		mov al, ah
		sub si, 2
		call BYTE_TO_HEX
		mov [si], ax
		mov dx, offset MCB_OWNER
		call PRINT_STR
		
		mov ax, es:[3h]
		mov si, offset MCB_SIZE
		add si, 13
		mov bx, 16
		mul bx
		call WRD_TO_DEC
		mov dx, offset MCB_SIZE
		call PRINT_STR
		
		mov dx, offset MCB_TAIL
		call PRINT_STR		
		mov cx, 8
		mov ah, 2h
		mov bx, 8h
		xor dx, dx
		print_tail:;посимвольная печать хвоста MCB
			mov dl, es:[bx]
			int 21h
			add bx, 1
			loop print_tail
		
		
		pop ax
		cmp al, 5ah;тип последней части
		je FINISH
		mov dx, offset ENTER_
		call PRINT_STR
		mov ax, es
		add ax, es:[3h]
		add ax, 1
		mov es, ax
		jmp printMCB

	FINISH:
	call EXIT
	programmEND:
TESTMEMORY ENDS
END START 