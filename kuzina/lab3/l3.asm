STT	SEGMENT
		ASSUME CS:STT, DS:STT, ES:NOTHING, SS:NOTHING
		ORG 100H 
START:	JMP BEGIN

AM db 'Available memory:       -B', 13,10, '$'
EM db 'Extended memory:       -KB', 13, 10, '$'
McbL db 'MCB:', 13, 10, '$'
Typ db 'Type: ', '$'
Hex db 'h', '$'
Sect db 'Owner address: ', '$'
Siz db 'Size:       -B', '$'
EndLine db ' ', 13, 10, '$'
Tab db '     ', '$'
Info db 'Last bytes info: ', '$'
Mem db ' !Something goes wrong with allocation!', 13, 10, '$'

BEGIN:
;Available memory
	
	mov ah, 4ah
	mov bx, 0ffffh
	int 21h
	mov ax, bx
	mov bx, 10h
	mul bx
	mov si, offset AM
	add si, 23
	call WRDTODEC
	mov	dx, offset AM
	mov ah, 09h
	int 21h
	
;Extended memory	
	mov ax, 0
	mov dx, 0
	mov al, 30h
	out 70h, al
	in al, 71h
	mov bl, al
	mov al, 31h
	out 70h, al
	in al, 71h
	mov bh, al
	mov ax, bx
	mov si, offset EM
	add si, 22
	call WRDTODEC
	mov	dx, offset EM  
	mov ah, 09h
	int 21h  
	
;MCB-s	
	mov ax, 0
	mov ah, 52h
	int 21h
	mov cx, es:[bx-2]
	mov es, cx
	
mcb: 
	mov	dx, offset McbL 
	mov ah, 09h
	int 21h

;MCBtype
	mov dx, offset Tab
	mov ah, 09h
	int 21h
	mov dx, offset typ 
	mov ah, 09h
	int 21h

	mov al, es:[00h] 
	call WRBYTE 
	mov dx, offset Hex
	mov ah, 09h
	int 21h
	mov dx, offset Tab
	mov ah, 09h
	int 21h

;MCBaddress
	mov dx, offset sect 
	mov ah, 09h
	int 21h
	mov bx, es:[01h] 
	mov al, bh
	call WrByte
	mov al, bl
	call WrByte

	
	
	mov dx, offset Hex
	mov ah, 09h
	int 21h
	mov dx, offset Tab
	mov ah, 09h
	int 21h
	
;MCBsize
	mov ax, es:[03h] 
	mov bx, 10h 
	mul bx 
	mov si, offset siz 
	add si, 11
	call WRDTODEC 
	mov dx, offset siz 
	mov ah, 09h
	int 21h
	mov dx, offset EndLine
	mov ah, 09h
	int 21h
	mov dx, offset Tab
	mov ah, 09h
	int 21h
	

;info
	mov dx, offset info 
	mov ah, 09h
	int 21h
	mov bx, 0 
fin:	
	mov dl, es:[08h + bx] 
	mov ah, 02h 
	int 21h 
	inc bx 
	cmp bx, 8h 
		jl fin 
		
	mov dx, offset EndLine
	mov ah, 09h
	int 21h
;5Ah - last one  
	mov al, es:[00h] 
	cmp al, 5Ah 
		je ext 
 
	mov bx, es 
	add bx, es:[03h] 
	inc bx 
	mov es, bx 
		jmp mcb 

ext:		
	xor al, al
	mov ah, 4Ch
	int 21h

;/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\	

	
WrByte PROC near
	push ax
	push dx
	push cx
	call BYTETOHEX
	xor cx, cx
	mov ch, ah
	mov dl, al
	mov ah, 02h
	int 21h
	mov dl, ch
	mov ah, 02h
	int 21h
	pop cx
	pop dx
	pop ax
	ret
WrByte ENDP	
	
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

WrdToDec PROC NEAR
	push cx
	push dx
	mov cx,10
loop_b: 
	div cx
		or 	dl,30h
	mov [si],dl
	dec si
	xor dx,dx
	cmp ax,10
		jae loop_b
	cmp al,00h
		je 	endl
		or 	al,30h
	mov [si],al
endl:
	pop dx
	pop cx
	ret
WrdToDec ENDP
	
OURMEM:	
STT	ENDS
		END START