aSTACK SEGMENT STACK
	DW 100h DUP(0)
aSTACK ENDS

DATA SEGMENT

UNLOAD_STR db '/un', 13, 10, '$'
MYHANDLER_STATUS_ON db 'The handler is already loaded', 13, 10, '$'
MYHANDLER_STATUS_OFF db 'The handler is not loaded', 13, 10, '$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:aSTACK

MY_HANDLER PROC far
	jmp HANDLER_CODE
	HANDLER_UNIQUE_CODE dw 1111h
	HANDLER_DATA:
		HANDLER_STACK dw 100h dup(0)
		KEEP_IP dw 0		
		KEEP_CS dw 0		
		KEEP_SS dw 0
		KEEP_SP dw 0
		PROCESSED_CODE db 2h

	HANDLER_CODE:
		push ax
  		mov KEEP_SS, ss
  		mov KEEP_SP, sp
  		mov ax, seg HANDLER_STACK
  		mov ss, ax
  		mov sp, offset KEEP_IP
		push es
		push ds

		mov ax, seg HANDLER_DATA
		mov ds, ax

		call CHECK_CLICK
		cmp al, 1
		je DO_REQ
		
		pushf;поместить в стек значение регистра флагов
		call dword ptr KEEP_IP;переход на первоначальный обработчик
		jmp FINISH_HANDLER

		DO_REQ:
			push ax
			in al, 61h
			mov ah, al
			or al, 80h
			out 61h, al
			xchg ah, al
			out 61h, al	
			pop ax
			call PUSH_TO_BUFFER

		FINISH_HANDLER:
  		mov al, 20h
  		out 20h, al
		
		pop ds
		pop es
		mov ss, KEEP_SS
  		mov sp, KEEP_SP
		pop ax
  		iret
MY_HANDLER ENDP


CHECK_CLICK PROC near
; out al. 1 - true
	push dx
	push es
	push bx

	in al, 60h;считываем скан-код из порта 60h
	cmp al, PROCESSED_CODE;сравниваем с нужным кодом
	jne USE_STANDART_HANDLER
	mov ax, 0040h
	mov es, ax
	mov ax, es:[0017h];байты состояния
	mov bx, 4h
	and bx, ax
	mov al, 1
	cmp bx, 4h
	jne USE_STANDART_HANDLER	
	jmp USE_MY_HANDLER
	
	USE_STANDART_HANDLER:
		mov al, 0

	USE_MY_HANDLER:
	pop bx
	pop es
	pop dx
	ret
CHECK_CLICK ENDP

PUSH_TO_BUFFER PROC near
	push ax
	push cx
	push es
	push dx

	again:
		mov ah, 5h
		mov cl, 'D'
		mov ch, 00h
		int 16h
		or al, al
		jz FINISH_PUSH_TO_BUFFER

	    mov ax, 0040h
	    mov es, ax
		mov ax, es:[001ah]
		mov es:[001ch], ax
		jmp again

	FINISH_PUSH_TO_BUFFER:
	pop dx
	pop es
	pop cx
	pop ax
	ret
PUSH_TO_BUFFER ENDP

resident_last_byte label word

PRINT_IS_HANDLER_LOADED PROC near
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
	mov al, 9h
	int 21h

	mov al, 0
	mov si, offset HANDLER_UNIQUE_CODE
	sub si, offset MY_HANDLER
	mov cx, es:[bx+si]
	cmp cx, HANDLER_UNIQUE_CODE
	jne printStatus

	mov al, 1

	printStatus:
	pop si
	pop cx
	pop bx
	pop es
	ret
FIND_OUT_STATUS ENDP

MAIN:
	mov ax, DATA
	mov ds, ax
	
	call FIND_OUT_STATUS
	call PRINT_IS_HANDLER_LOADED
	
	cmp al, 1
	je ON
	OFF:;обработчик не установлен
		mov ah, 35h
		mov al, 9h
		int 21h
		mov KEEP_CS, es
		mov KEEP_IP, bx
		push ds
		mov dx, offset MY_HANDLER
		mov ax, seg MY_HANDLER
		mov ds, ax
		mov ah, 25h;функция установки вектора
		mov al, 9h
		int 21h
		pop ds
		;оставляем резидентную часть в памяти		
		mov dx, offset resident_last_byte
		sub dx, offset MY_HANDLER
		mov ah, 031h
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
		mov al, 9h
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
		mov al, 9h
		int 21h
		pop ds	
		mov es, es:[bx]
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