aSTACK SEGMENT STACK
	DW 100h DUP(0)
aSTACK ENDS

DATA SEGMENT
STATUS_ON db 'The handler is unloaded', 13, 10, '$'
STATUS_OFF db 'The handler is loaded', 13, 10, '$'

UNLOAD_STR db '/un', 13, 10, '$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:aSTACK

HANDLER PROC far

	jmp code_handler
	
	PSW dw 9999h
	data_handler:
	HANDLER_STACK dw 100h dup(0)
	KEEP_CS dw 0
	KEEP_IP dw 0 
	KEEP_PSP dw 0
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	CNT dw 0
	CNT_STR db '000000$'

	code_handler:
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
		push bp

		mov ax, seg data_handler
		mov ds, ax

		inc CNT
		mov dx, 0
		mov ax, CNT
		mov si, offset CNT
		add si, 5
		call WRD_TO_DEC

		mov ax, seg CNT_STR
		mov es, ax
		mov bp, offset CNT_STR
		call OUTPUT		
		
		pop bp
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
HANDLER ENDP

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
	push cx
	push dx

	mov ah, 13h
	mov al, 0
	mov bh, 0
	mov dh, 22
	mov dl, 27
	mov cx, 4
	mov bl, 3
	int 10h

	pop dx
	pop cx
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

SET_VECTOR PROC near
	mov ah, 35h
	mov al, 1ch
	int 21h
	ret
SET_VECTOR ENDP

GIVE_VECTOR PROC near
	mov ah, 25h
	mov al, 1ch
	int 21h
	ret
GIVE_VECTOR ENDP

FIND_OUT_STATUS PROC near
	push bx
	push cx
	push es
	push si

	call SET_VECTOR

	mov al, 0
	mov si, offset PSW
	sub si, offset HANDLER
	mov cx, es:[bx+si]
	cmp cx, PSW
	jne print_status

	mov al, 1

	print_status:
	pop si
	pop es
	pop cx
	pop bx
	ret
FIND_OUT_STATUS ENDP


PRINT_IS_HANDLER_LOADED PROC near
	push dx
	cmp al, 1
	je loaded
	jmp not_loaded
	loaded:
		mov dx, offset STATUS_ON
		jmp print_do
	not_loaded:
		mov dx, offset STATUS_OFF
	print_do:
		call PRINT

	pop dx
	ret
PRINT_IS_HANDLER_LOADED ENDP

MAIN:
	mov ax, DATA
	mov ds, ax		

	call FIND_OUT_STATUS		
	call PRINT_IS_HANDLER_LOADED
	cmp al, 1
	je on
		mov KEEP_PSP, es
		
		call SET_VECTOR
		
		mov KEEP_CS, es
		mov KEEP_IP, bx
		mov dx, offset HANDLER
		mov ax, seg HANDLER
		mov ds, ax
		
		call GIVE_VECTOR
		
		mov dx, 100h
		mov ax, 3100h
		int 21h
		jmp fin
	on:
		mov cl, es:[80h]
		cmp cl, 4
		jne fin
		mov cx, 3
		mov si, offset UNLOAD_STR
		mov bx, 82h		
	compare_str:
		
		dec cx
		mov ah, [si]
		cmp byte ptr es:[bx], ah
		jne fin
		inc si
		inc bx
		mov al, 1
		
		cmp cx, 0
		jle compare_str
		
		cli
		
		call SET_VECTOR
		
		mov si, offset KEEP_CS
		sub si, offset HANDLER
		mov ax, es:[bx+si]
		mov si, offset KEEP_IP
		sub si, offset HANDLER
		mov dx, es:[bx+si]
		mov ds, ax
		
		call GIVE_VECTOR
		
		mov si, offset KEEP_PSP
		sub si, offset HANDLER
		mov es, es:[bx+si]
		mov ah, 49h
		int 21h
		mov es, es:[2ch]
		mov ah, 49h
		int 21h		
		sti
	fin:
		call EXIT
CODE ENDS
END MAIN 