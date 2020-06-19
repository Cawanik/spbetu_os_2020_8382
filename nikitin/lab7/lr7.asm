AStack SEGMENT STACK 'STACK'
	DW 100h DUP(?)
AStack ENDS

DATA SEGMENT
	err1 db 'memory control block ruined',10,13,'$'
	err2 db 'not enough memory',10,13,'$'
	err3 db 'wrong memory block address',10,13,'$'
	DTA db 43 dup (?)
	KEEP_PSP dw 0
	KEEP_DS dw 0
	KEEP_SP dw 0
	KEEP_SS dw 0
	PATH db 100h dup (0), '$'
	one db 'one.ovl',0
	two db 'two.ovl',0
	notfile db 'file not found',10,13,'$'
	notpath db 'path not found',10,13,'$'
	notmem db 'memory error',10,13,'$'
	block dw 0
	address dd 0
	manyfiles db 'many files loaded',10,13,'$'
	noaccess db 'no access',10,13,'$'
	notexist db 'not exist',10,13,'$'
	notenoughmemory db 'not enough memory',10,13,'$'
	wrongenv db 'wrong environment',10,13,'$'
DATA ENDS
 
CODE SEGMENT
		ASSUME SS:AStack,DS:DATA,CS:CODE
	
FREEMEM PROC near
	mov bx, offset FLAG
	mov ax, ds
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov ah, 4ah
	int 21h
	jc err_free
	jmp endfree
err_free:
	cmp ax, 7
	je exc1
	cmp ax, 8
	je exc2
	cmp ax, 9
	je exc3
exc1:
	mov dx, offset err1
	jmp end_exc
exc2:
	mov dx, offset err2
	jmp end_exc
exc3:
	mov dx, offset err3
end_exc:
	mov ah, 9
	int 21h
	xor ax, ax
	mov ah, 4ch
	int 21h
endfree:
	ret
FREEMEM ENDP

PATHSTR PROC near 
	push dx
	push ds
	mov dx, seg DTA
	mov ds, dx
	mov dx, offset DTA
	mov ah, 1ah
	int 21h
	pop ds
	pop dx
	
	mov es, KEEP_PSP
	
	push es
	push dx
	push si
	push di
	mov es, es:[2ch]
	mov di, 0
loop1:
	mov dl, es:[di]
	cmp dl, 0
	je loop2
	inc di
	jmp loop1
loop2:
	inc di
	mov dl, es:[di]
	cmp dl, 0
	jne loop1
	add di, 3
	mov si, offset PATH
path_loop:
	mov dl, es:[di]
	cmp dl, 0
	je end_path
	mov [si], dl
	inc si
	inc di
	jmp path_loop
end_path:
	mov di, cx
	sub si, 7
not_ready:
	mov dl, byte ptr [di]
	mov byte ptr [si], dl
	inc di
	inc si
	cmp dl, 0
	jne not_ready

	mov dl, '$'
	mov byte ptr [si], dl
	pop di
	pop si
	pop dx
	pop es
	ret
PATHSTR ENDP

OVERLAYSIZE PROC near 
	push ax
	push cx
	push dx
	push es
	push di
	push ds
	

	mov ax, seg PATH
	mov ds, ax
	mov dx, offset PATH
	mov ah, 4eh
	int 21h
	jc err4e
	mov di, offset DTA
	mov ax, [di+1ah]
	mov bx, [di+1ch]
	mov cl, 4
	shr ax, cl
	mov cl, 12
	shl bx, cl
	add bx, ax
	inc bx
	mov ah, 48h
	int 21h
	jc err_48h
	mov block, ax

	
	pop ds
	pop di
	pop es
	pop dx
	pop cx
	pop ax
	ret
err4e:
	cmp ax, 2
	je nofile
	cmp ax, 3
	je nopath
nofile:
	mov dx, offset notfile
	jmp quit
nopath:
	mov dx, offset notpath
	jmp quit
err_48h:
	mov dx, offset notmem
quit:
	mov ah, 9
	int 21h
	pop di
	pop ds
	pop es
	pop dx
	pop cx
	pop ax
	mov al, 0
	mov ah, 4Ch
	int 21h
OVERLAYSIZE ENDP

OVERLAYRUN PROC near 
	push ax
	push bx
	push cx
	push dx
	push es
	
	push es
	mov KEEP_DS, ds
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	mov bx, seg block
	mov es, bx
	mov bx, offset block
	mov dx, offset PATH
	mov ah, 4bh
	mov al, 3
	int 21h
	mov dx, KEEP_DS
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	pop es
	
	jc err_run
	mov ax, block
	mov word ptr address+2, ax
	call address
	mov ax, block
	mov es, ax
	mov ah, 49h
	int 21h

	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	mov es, KEEP_PSP
	ret
err_run:
	cmp	ax, 1
	je errrun1
	cmp	ax, 2
	je errrun2
	cmp	ax, 3
	je errrun3
	cmp	ax, 4
	je errrun4
	cmp	ax, 5
	je errrun5
	cmp	ax, 8
	je errrun8
	cmp	ax, 10
	je errrun10
	jmp quit_ovl
errrun1:
	mov dx, offset notexist
	jmp quit_ovl
errrun2:
	mov dx, offset notfile
	jmp quit_ovl
errrun3:
	mov dx, offset notpath
	jmp quit_ovl
errrun4:
	mov dx, offset manyfiles
	jmp quit_ovl
errrun5:
	mov dx, offset noaccess
	jmp quit_ovl
errrun8:
	mov dx, offset notenoughmemory
	jmp quit_ovl
errrun10:
	mov dx, offset wrongenv

quit_ovl:
	mov ah, 9
	int 21h
	pop es
	pop dx
	pop bx
	pop ax
	mov es, KEEP_PSP
	ret
OVERLAYRUN ENDP

BEGIN PROC  far
	mov bx, es
	mov ax, DATA
	mov ds, ax
	
	mov KEEP_PSP, es
	
	call FREEMEM
	mov cx, offset one
	call PATHSTR
	call OVERLAYSIZE
	call OVERLAYRUN
	
	xor bx, bx
	mov cx, offset two
	call PATHSTR
	call OVERLAYSIZE
	call OVERLAYRUN
	
	xor AL,AL
	mov AH,4Ch
	int 21H
BEGIN  	ENDP

CODE    ENDS
FLAG SEGMENT
FLAG ENDS
END     BEGIN 