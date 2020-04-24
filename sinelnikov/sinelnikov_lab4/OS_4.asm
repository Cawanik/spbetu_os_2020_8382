CODE	SEGMENT
		keep_1c		dd 0
		keep_2f		dd 0 
		keep_PSP   	dw ? 
        ASSUME CS:CODE, DS:DATA, SS:AStack
		
outputAL 		PROC 
		push ax
		push bx
		push cx
		mov ah, 09h
		mov bh, 0
		mov cx, 1
		int 10h
		pop cx
		pop bx
		pop ax
		ret
outputAL 		ENDP

getCurs  PROC
		push ax
		push bx
		mov ah, 03h
		mov bh, 0
		int 10h
		pop bx
		pop ax
		ret
getCurs  ENDP

SetCurs  PROC
		push ax
		push bx
		mov ah, 02h
		mov bh, 0
		int 10h
		pop bx
		pop ax
		ret
SetCurs  ENDP
	
2F	PROC
		cmp ah, 080h 
		jne  not_loaded
		mov  al, 0ffh 
	not_loaded:
		iret
2F	ENDP

1C	PROC
		push ax
		push bx
		push cx
		push dx
		push es
		inc count
		cmp count, 57
		jne show
		mov count, 48
	show:
		
		call getCurs
		mov cx, dx
		mov dh, 23
		mov dl, 33	
		call SetCurs
		push ax
		mov al, count
		call OutputAL
		pop ax
		mov dx, cx
		call SetCurs
		mov al, 20h
		out 20h, al
		pop es
		pop dx
		pop cx
		pop bx
		pop ax
		iret 	
LAST_BYTE:
1C 	ENDP

Un_check  PROC	FAR
		push ax
		
		mov	ax, Keep_PSP
		mov	es, ax
		sub	ax, ax
		cmp	byte ptr es:[82h],'/'
		jne	not_un
		cmp	byte ptr es:[83h],'u'
		jne	not_un
		cmp	byte ptr es:[84h],'n'
		jne	not_un
		mov	flag,0
		
	not_un:
		pop	ax
		ret
Un_check  ENDP

Keep_interr	 PROC
		push ax
		push bx
		push es
		mov ah, 35h 
		mov al, 1Ch
		int 21h
		mov word ptr keep_1c, bx
		mov word ptr keep_1c+2, es
		mov ah, 35h
		mov al, 2Fh
		int 21h	
		mov word ptr keep_2f, bx
		mov word ptr keep_2f+2, es
		pop es
		pop bx
		pop ax
		ret
Keep_interr	 ENDP

Load_interr	 PROC
		push ds
		push dx
		push ax
		call Keep_interr
		push ds
		mov dx, offset 1C
		mov ax, seg 1C	    
		mov ds, ax
		mov ah, 25h		
		mov al, 1Ch         	
    		int 21h
    		mov dx, offset 2F
		mov ax, seg 2F	    
		mov ds, ax
		mov ah, 25h		
		mov al, 2Fh          	
    		int 21h	
		pop ds
		pop ax
		pop dx
		pop ds
		ret
Load_interr  ENDP

Unload_interr  PROC
		push ds
		mov ah, 35h
		mov al, 1Ch
		int 21h
		mov dx, word ptr es:keep_1c
		mov ax, word ptr es:keep_1c+2
		mov word ptr keep_1c, dx
		mov word ptr keep_1c+2, ax

		mov ah, 35h
		mov al, 2Fh
		int 21h
		mov dx, word ptr es:keep_2f
		mov ax, word ptr es:keep_2f+2
		mov word ptr keep_2f, dx
		mov word ptr keep_2f+2, ax
		cli
		mov dx, word ptr keep_1c
		mov ax,	word ptr keep_1c+2
		mov ds, ax
		mov ah, 25h
		mov al, 1Ch
		int 21h
		mov dx, word ptr keep_2f
		mov ax,	word ptr keep_2f+2
		mov ds, ax
		mov ah, 25h
		mov al, 2Fh
		int 21h
		sti
		pop ds
		mov es, es:Keep_PSP
		mov ax, 4900h		
		int 21h
		mov flag, 1			
		mov dx, offset Message2
		call Write_message 
		mov es, es:[2ch]	
		mov ax, 4900h	
		int 21h
		mov ax, 4C00h		
		int 21h
Unload_interr  ENDP

Make_resident  PROC
		mov ax, es
		mov Keep_PSP, ax
		mov dx, offset LAST_BYTE
		add dx,200h	
		mov ah, 31h
		mov al, 0 
		int 21h
Make_resident  ENDP

; функция вывода сообщения на экран
Write_message	PROC
		push ax
		mov ah, 09h
		int 21h
		pop ax
		ret
Write_message		ENDP

; Главная функция
Main 	PROC  
		push ds
		xor ax, ax
		push ax
   		mov ax, data             
  		mov ds, ax
		mov Keep_PSP, es 
		mov Count, 48
		mov ax, 8000h
		int 2Fh
		cmp sal,0ffh
		jne loading
		call Un_check
		cmp flag, 0
		jne alr_loaded
		call Unload_interr	
	loading:				
		call Load_interr
		lea DX, Message1
		call Write_message
		call Make_resident
	alr_loaded:				
		lea dx, Message3
		call Write_message
		mov ax, 4C00h
		int 21h
Main 	ENDP
CODE    		ENDS

AStack		SEGMENT  STACK
        DW 256 DUP(?)			
AStack  	ENDS

DATA		SEGMENT
	Count 	 		db ?
    flag			dw 1
    Message1        db 'Interruption program was loaded', 0dh, 0ah, '$'
    Message2	    db 'Interruption program unloaded', 0dh, 0ah, '$'
    Message3		db 'Interruption program is already loaded', 0dh, 0ah, '$'
DATA 		ENDS
        	END Main
