CODE SEGMENT
		ASSUME SS:AStack,DS:DATA,CS:CODE
		
HANDLER PROC FAR
	jmp HANDLERcode
intdata:
	KEY db 0
	PSW dw 9999h
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_PSP dw 0
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	HANDLER_STACK dw 100h dup(?)
handlercode:
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	mov ax, seg HANDLER_STACK
	mov ss, ax
	mov sp, offset HANDLER_STACK
	add sp, 100h
	push bx
	push cx
	push dx
	push si
	push ds
	mov ax, seg intdata 
	mov ds, ax
	
	in al, 60h
	cmp al, 2
	je one
	cmp al, 3
	je two
	cmp al, 4
	je three
	cmp al, 5
	je four
	cmp al, 6
	je five
	cmp al, 7
	je six
	cmp al, 8
	je seven
	cmp al, 9
	je eight
	cmp al, 0ah
	je nine
	pushf
	call dword ptr cs:KEEP_IP
	jmp endint
one:
	mov KEY, 'c'
	jmp secure
two:
	mov KEY, 'a'
	jmp secure
three:
	mov KEY, 'w'
	jmp secure
four:
	mov KEY, 'a'
	jmp secure
five:
	mov KEY, ' '
	jmp secure
six:
	mov KEY, 'n'
	jmp secure
seven:
	mov KEY, 'i'
	jmp secure
eight:
	mov KEY, 'k'
	jmp secure
nine:
	mov KEY, 't'
secure:
	in al, 61h
	mov ah, al	
	or al, 80h
	out 61h, al
	xchg al, al
	out 61h, al
	mov al, 20h
	out 20h, al
buffer:
	mov ah, 5
	mov cl, KEY
	mov ch, 0
	int 16h
	or al, al
	jz endint
	push es
	mov ax, 0040h
	mov es, ax
	mov ax, es:[1ah]
	mov es:[1ch], ax
	pop es
	jmp buffer
endint:
	pop ds
	pop si
	pop dx
	pop cx
	pop bx
	mov sp, KEEP_SP
	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov al, 20h
	out 20h, al
	iret
HANDLER ENDP

endhandler:

CHECKTOUNLOAD PROC
	push ax
	push es
	mov ax, KEEP_PSP
	mov es, ax
	cmp byte ptr es:[82h], '/'
	jne checkunend
	cmp byte ptr es:[83h], 'u'
	jne checkunend
	cmp byte ptr es:[84h], 'n'
	jne checkunend
	mov flag_tounload, 1
checkunend:
	pop es
	pop ax
	ret
CHECKTOUNLOAD ENDP

CHECKINTLOADED PROC
	push bx
	push si
	push ax
	mov ah, 35h
	mov al, 09h
	int 21h
	mov si, offset PSW
	sub si, offset HANDLER
	mov ax, es:[bx+si]
	cmp ax, 9999h
	jne checkintend
	mov flag_loaded, 1
checkintend:	
	pop ax
	pop si
	pop bx
	ret
CHECKINTLOADED ENDP

LOADINT PROC
	
	push cx
	push dx
	push es
	push ax
	push bx

	mov ah, 35h
	mov al, 09h
	int 21h
	mov KEEP_CS, es
	mov KEEP_IP, bx
	
	push ds
	mov dx, offset HANDLER
	mov ax, seg HANDLER
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	
	mov dx, offset endhandler
	add dx, 10fh
	mov cl, 4
	shr dx, cl
	inc dx
	xor ax, ax
	mov ah, 31h
	int 21h
	
	pop bx
	pop ax
	pop es
	pop dx
	pop cx
	
	ret
LOADINT ENDP

UNLOADINT PROC
	cli
	push ax
	push bx
	push dx
	push si
	push es
	
	mov ah, 35h
	mov al, 09h
	int 21h
	mov si, offset KEEP_IP
	sub si, offset HANDLER
	mov dx, es:[bx+si]
	mov ax, es:[bx+si+2]
	
	push ds
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	
	mov es, es:[bx+si+4]
	push es
	mov es, es:[2ch]
	mov ah,49h
	int 21h
	pop es
	mov ah, 49h
	int 21h
	
	pop es
	pop si
	pop dx
	pop bx
	pop ax
	sti
	ret
UNLOADINT ENDP

BEGIN PROC  
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es
	call CHECKINTLOADED
	call CHECKTOUNLOAD
	cmp flag_tounload, 1
	je unload
	cmp flag_loaded, 1
	jne load
	mov dx, offset intexist
	mov ah, 09h
	int 21h
	jmp endlr
unload:
	cmp flag_loaded, 1
	jne nothingtounload
	call UNLOADINT
	mov dx, offset intunloaded
	mov ah, 09h
	int 21h
	jmp endlr
nothingtounload:
	mov dx, offset intnotexist
	mov ah, 09h
	int 21h
	jmp endlr
load:
	mov dx, offset intloaded
	mov ah, 09h
	int 21h
	call LOADINT
endlr:
	xor AL,AL
	mov AH,4Ch
	int 21H
BEGIN  	ENDP

CODE    ENDS

AStack SEGMENT STACK 'STACK'
	DW 100h DUP(?)
AStack ENDS

DATA SEGMENT
	flag_loaded db 0
	flag_tounload db 0
	intloaded db 'interrupt has been loaded', 13, 10, '$'
	intexist db 'interrupt is already loaded', 13, 10, '$'
	intunloaded db 'interrupt has been unloaded', 13, 10, '$'
	intnotexist db "interrupt hasn't been loaded", 13, 10, '$'
DATA ENDS
 
END     BEGIN 