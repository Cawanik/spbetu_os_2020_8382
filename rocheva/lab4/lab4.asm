AStack SEGMENT STACK
    dw 100h dup(?)
AStack ENDS

DATA SEGMENT
	INT_LOADED db 0
	MESSAGE_INT_LOADED db 'Interruption loaded$'
	MESSAGE_INT_NOT_LOADED db 'Interruption unloaded$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack
	
	
ROUT PROC FAR
	jmp Start
	INT_COUNT db 'Interruption: 0000$'
	INT_ID dw 4040h
	KEEP_AX dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_PSP DW 0
	INT_STACK dw 100h dup(0)

Start:
	mov KEEP_SS, ss
 	mov KEEP_SP, sp
  	mov KEEP_AX, ax
	mov ax, seg INT_STACK
	mov ss, ax
	mov ax, offset INT_STACK
	add ax, 100h
	mov sp, ax
	
	push bx
	push cx
	push dx
	push si
	push ds
	push bp
	push es
		
	mov ah, 03h
	mov bh, 00h
	int 10h
	push dx

	mov ah, 09h
	mov bh, 0 
	mov cx, 0
	int 10h

	mov ah, 02h
	mov bh, 0
	mov dh, 23
	mov dl, 20
	int 10h
		
	mov ax, seg INT_COUNT
	push ds
	push bp
	mov ds, ax
	mov si, offset INT_COUNT
	add si, 13
	mov cx, 4

Cycle:
	mov bp, cx
   	mov ah, [si+bp]
	inc ah
	mov [si+bp], ah
	cmp ah, ':'
	jne CycleEnd
	mov ah, '0'
	mov [si+bp], ah
	loop CYCLE
	
CycleEnd:
	pop bp
	pop ds
	push es
	push bp
	mov ax, seg INT_COUNT
	mov es, ax
	mov bp, offset INT_COUNT
	call outputBP
	pop bp
	pop es
	
	pop dx
	mov ah, 02h
	mov bh, 0
	int 10h

	pop es
	pop bp
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
ROUT ENDP
LAST_BYTE:


outputBP PROC near
	push ax
	push bx
	mov ah, 13h
	mov al, 1
	mov bl, 04h ;красный цвет
	mov cx, 18
	mov bh, 0
	int 10h
	pop bx
	pop ax
	ret
outputBP ENDP


LOAD_INT PROC near
	push ax
	push bx
	push cx
	push dx
	push ds
	push es


	mov ah, 35h ; функция получения вектора
	mov al, 1Ch ; номер вектора
	int 21h
	mov KEEP_IP, bx ; запоминание смещения
	mov KEEP_CS, es ; и сегмента

	
	push ds
	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds, ax
	mov ah, 25h
	mov al, 1ch
	int 21h ; восстанавливаем вектор
	pop ds

	mov dx, offset LAST_BYTE
	mov cl, 4h ; перевод в параграфы
	shr dx, cl
	add dx, CODE
	inc dx 
	xor ax, ax
	mov ah, 31h
	int 21h

	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD_INT ENDP


INT_UNLOAD PROC near
	push ax
	push bx
	push dx
	push ds
	push es
	push si
		
	cli
	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov si, offset KEEP_IP
	sub si, offset ROUT
	mov dx, es:[bx+si]
	mov ax, es:[bx+si+2]
	push ds
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	mov ax, es:[bx+si+4]
	mov es, ax
	push es
	mov ax, es:[2Ch]
	mov es, ax
	mov ah, 49h
	int 21h
	
	pop es
	mov ah, 49h
	int 21h
	sti
		
	pop si
	pop es
	pop ds
	pop dx
	pop bx
	pop ax
	ret
INT_UNLOAD ENDP


CHECK_INT PROC near
	push ax
	push bx
	push si

	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov si, offset INT_ID
	sub si, offset ROUT
	mov ax, es:[bx+si]
	cmp ax, 4040h
	jne EndCheck
	mov INT_LOADED, 1

EndCheck:
	pop si
	pop bx
	pop ax
	ret
CHECK_INT ENDP


WRITE PROC near
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
WRITE ENDP


MAIN PROC FAR
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es	
	
	call CHECK_INT
	
	mov ax, KEEP_PSP
	mov es, ax
	cmp byte ptr es:[81h+1], '/'
	jne WithoutUN
	cmp byte ptr es:[81h+2], 'u'
	jne WithoutUN
	cmp byte ptr es:[81h+3], 'n'
	jne WithoutUN
	mov dx, offset MESSAGE_INT_NOT_LOADED
	call WRITE
	call INT_UNLOAD
	jmp EndInt
	
WithoutUN:
	mov al, INT_LOADED 
	cmp al, 1
	je EndInt
	mov dx, offset MESSAGE_INT_LOADED
	call WRITE
	call LOAD_INT
	jmp EndInt


EndInt:
	xor al, al
	mov ah, 4Ch
	int 21h
MAIN ENDP
CODE ENDS
END MAIN
