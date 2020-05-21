aSTACK SEGMENT STACK
	DW 100h DUP(0)
aSTACK ENDS

DATA SEGMENT
MYHANDLER_STATUS_ON db 'The handler is already loaded', 13, 10, '$'
MYHANDLER_STATUS_OFF db 'The handler is not loaded', 13, 10, '$'

UNLOAD_STR db '/un', 13, 10, '$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:aSTACK

MY_HANDLER PROC far;мой обработчик

	jmp HANDLER_CODE
	HANDLER_UNIQUE_CODE dw 1111h
	HANDLER_DATA:
	HANDLER_STACK dw 100h dup(0)
	KEEP_CS dw 0
	KEEP_IP dw 0 
	KEEP_PSP dw 0
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	COUNTER dw 0
	COUNTER_STR db '000000$'

	HANDLER_CODE:
	mov KEEP_AX, ax
  	mov KEEP_SS, ss
  	mov KEEP_SP, sp
  	mov ax, seg HANDLER_STACK
  	mov ss, ax
  	mov sp, offset KEEP_CS
		push es
		push ds
		push dx
		push si

		mov ax, seg HANDLER_DATA
		mov ds, ax

		inc COUNTER
		mov dx, 0
		mov ax, COUNTER
		mov si, offset COUNTER
		add si, 5
		call WRD_TO_DEC

		mov ax, seg COUNTER_STR
		mov es, ax
		mov bp, offset COUNTER_STR
		call OUTPUT		
		
		pop si
		pop dx
		pop ds
		pop es
		
		mov al, 20h
  		out 20h, al
		
		mov ss, KEEP_SS
  		mov sp, KEEP_SP
  		mov ax, KEEP_AX
  		iret
MY_HANDLER ENDP

WRD_TO_DEC PROC near
	push bx
	push ax

  	mov bx, 10
  	convertion:
    	div bx
    	add dl, 30h
    	mov [si], dl
    	xor dx, dx
    	dec si
    	cmp ax, 0
    	jne convertion

	pop ax
	pop bx
  	ret
WRD_TO_DEC ENDP

OUTPUT PROC near
	push ax
	push bx
	push dx
	push cx

	mov ah, 13h;функция
	mov al, 0
	mov bh, 0;номер видео страницы
	mov dh, 22
	mov dl, 60
	mov cx, 6;число симв
	mov bl, 1;color
	int 10h

	pop cx
	pop dx
	pop bx
	pop ax 
	ret
OUTPUT ENDP

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

FIND_OUT_STATUS PROC near
	push es
	push bx
	push cx
	push si

	mov ah, 35h
	mov al, 1ch
	int 21h

	mov al, 0
	;mov dx, offset MYHANDLER_STATUS_ON
	mov si, offset HANDLER_UNIQUE_CODE
	sub si, offset MY_HANDLER
	mov cx, es:[bx+si]
	cmp cx, HANDLER_UNIQUE_CODE
	jne printStatus

	mov al, 1
	;mov dx, offset MYHANDLER_STATUS_OFF

	printStatus:
	pop si
	pop cx
	pop bx
	pop es
	ret
FIND_OUT_STATUS ENDP


PRINT_IS_HANDLER_LOADED PROC near
; IN al
	push dx
	cmp al, 1
	je LOADED
	jmp NOT_LOADED
	LOADED:
		mov dx, offset MYHANDLER_STATUS_ON
		jmp DO_PRINT
	NOT_LOADED:
		mov dx, offset MYHANDLER_STATUS_OFF
	DO_PRINT:
		call PRINT

	pop dx
	ret
PRINT_IS_HANDLER_LOADED ENDP

MAIN:
	mov ax, DATA
	mov ds, ax		

	call FIND_OUT_STATUS		
	call PRINT_IS_HANDLER_LOADED
	;AL = 1 - обработчик установлен	
	cmp al, 1
	je ON
	OFF: ;обработчик не установлен
		mov KEEP_PSP, es
		mov ah, 35h
		mov al, 1ch
		int 21h
		mov KEEP_CS, es
		mov KEEP_IP, bx
		push ds
		mov dx, offset MY_HANDLER
		mov ax, seg MY_HANDLER
		mov ds, ax
		mov ah, 25h;функция установки вектора
		mov al, 1ch
		int 21h
		pop ds
		;оставляем резидентную часть в памяти
		mov dx, 100h
		mov ax, 3100h
		int 21h
		jmp FINISH_MAIN
	ON:;обработчик установлен
		;проверяем на ключевое слово '/un'
		push ax
		mov cl, es:[80h];длина символов командной строки
		cmp cl, 4
		jne FINISH_MAIN
		mov cx, 3
		mov si, offset UNLOAD_STR
		mov bx, 82h		
		compareStr:
			mov ah, [si];символ терминального слова		
			cmp byte ptr es:[bx], ah
			jne FINISH_MAIN
			inc si
			inc bx
			mov al, 1
			loop compareStr
		pop ax
		cli
		mov ah, 35h
		mov al, 1ch
		int 21h	
		mov si, offset KEEP_CS
		sub si, offset MY_HANDLER
		mov ax, es:[bx+si]
		mov si, offset KEEP_IP
		sub si, offset MY_HANDLER
		mov dx, es:[bx+si]
		push ds
		mov ds, ax
		mov ah, 25h
		mov al, 1ch
		int 21h
		pop ds	
		mov si, offset KEEP_PSP
		sub si, offset MY_HANDLER
		mov es, es:[bx+si]
		mov ah, 49h
		int 21h
		mov es, es:[2ch]
		mov ah, 49h
		int 21h		
		sti
	FINISH_MAIN:
		call EXIT
CODE ENDS
END MAIN