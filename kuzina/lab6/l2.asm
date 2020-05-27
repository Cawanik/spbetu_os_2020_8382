STT	SEGMENT
		ASSUME CS:STT, DS:STT, ES:NOTHING, SS:NOTHING
		ORG 100H 
START:	JMP BEGIN

MemAdd db  '   Unavailable memory address:        ',13,10,'$'
EnvAdd db  '   Environment address:     ', 13, 10, '$'
LineTail db'   Command line tail: ', '$'
EndLine db ' ', 13, 10, '$'
Tab db '      ', '$'
EnvCon db  '   Enviroment contents: ', '$'
Path db    '   Load module path: ', '$'

BEGIN:

;Memory adress
	mov ax, ss:[02h]
	mov di, offset MemAdd
	add di, 34
	call WrdToHex
	mov [di], ax
	mov dx, offset MemAdd
	mov ah, 09h
	int 21h
;environment address
	mov ax, ss:[2Ch]
	mov di, offset EnvAdd
	add di, 28
	call WrdToHex
	mov [di], ax
	mov dx, offset EnvAdd
	mov ah, 09h
	int 21h
;command line tail
	mov bx, 0
	mov cl, ss:[80h]
	mov ax, ss:[81h]
	mov dx, offset LineTail
	mov ah, 09h
	int 21h
	cmp cl, 0
		je writel
	mov ah, 02h
line:
	mov dl, ss:[81h + bx]
	int 21h
	inc bx
	loop line
writel:	
	mov dx, offset EndLine
	mov ah, 09h
	int 21h
;enviroment contents	
	mov dx, offset EnvCon
	mov ah, 09h
	int 21h
	mov bx, 0	
	mov es, ss:[2Ch]
envir:   
	mov dx, offset EndLine
	mov ah, 09h
	int 21h
	mov dl, 0
	cmp dl, es:[bx]
	je mpath
	mov dx, offset Tab
	int 21h
envirloop:
	mov ah, 02h
	mov dl, es:[bx]
	int 21h
	inc bx
	cmp dl, 0
		je envir
		jmp envirloop
mpath:
;load module path
	mov dx, offset Path
	mov ah, 09h
	int 21h	
	mov ah, 02h
	add bx, 3
pathloop:
	mov dl, es:[bx]
	int 21h
	inc bx
	cmp dl, 0
		jne pathloop
	
	mov dx, offset EndLine
	mov ah, 09h
	int 21h
ext:		
	xor al, al
	mov ah, 01h
	int 21h
	
	
	mov ah, 4Ch
	int 21h

;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
	
TetrToHex PROC near
	and al,0Fh
	cmp al,09
		jbe next
	add al,07
next:
	add al,30h
	ret
TetrToHex ENDP

ByteToHex PROC near
	push cx
	mov ah,al
	call TetrToHex
	xchg al,ah
	mov cl,4
	shr al,cl
	call TetrToHex
	pop cx
	ret
ByteToHex ENDP

WrdToHex PROC near
	push bx
	mov bh,ah
	call ByteToHex
	mov [di],ah
	dec di
	mov [di],al
	dec di
	mov al,bh
	call ByteToHex
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
WrdToHex ENDP
	
STT	ENDS
		END START