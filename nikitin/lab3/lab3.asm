TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

mem db 'Available memory -        b','$'
exmem db'Extended memory -       b','$'

typeln db 'Type - ','$'
sectorln db ' Sector - ','$'
free db 'FREE    ', '$'
xms db 'OS XMS UMB', '$'
driver db 'excluded upper driver memory', '$'
msdos db 'MS DOS  ', '$'
occup db '386MAX UMB occupied', '$'
blocked db '386MAX UMB blocked', '$'
maxumb db '386MAX UMB', '$'
ending db '$'
padding db ';  ','$'
aftersec db '  ', '$'
mcbsize db ' Size -        b','$'
lbytes db 'Last 8 bytes - ','$'
endln db 13,10, '$'

PRINT PROC near
	push CX
	push DX

	call BYTE_TO_HEX
	mov CH, AH

	mov DL, AL
	mov AH, 02h
	int 21h

	mov DL, CH
	mov AH, 02h
	int 21h

	pop DX
	pop CX
	ret
PRINT ENDP

TETR_TO_HEX PROC near 
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

WRD_TO_DEC PROC NEAR
		push 	cx
		push 	dx
		mov 	cx,10
loop_b: div 	cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor 	dx,dx
		cmp 	ax,0
		jnz 	loop_b
endl:	pop 	dx
		pop 	cx
		ret
WRD_TO_DEC ENDP

BEGIN:
	mov ah, 4ah
	mov bx, 0ffffh
	int 21h
	mov ax, bx
	mov cx, 16
	mul cx 
	mov si, offset mem + 24
	call WRD_TO_DEC
	mov dx, offset mem
	mov ah, 09h
	int 21h
	
	mov dx, offset padding
	mov ah, 09h
	int 21h
	
	mov dx, offset endln
	mov ah, 09h
	int 21h
	
	xor ax, ax
	xor dx, dx
	mov al, 30h
	out 70h, al
	in al, 71h
	mov bl, al
	mov al, 31h
	out 70h, al
	in al, 71h
	mov bh, al
	mov ax, bx
	mov si, offset exmem + 22
	call WRD_TO_DEC
	mov	dx, offset exmem
	mov ah, 09h
	int 21h
	
	mov dx, offset padding
	mov ah, 09h
	int 21h
	
	mov dx, offset endln
	mov ah, 09h
	int 21h
	
	xor ax, ax
	mov ah, 52h
	int 21h
	mov es, es:[bx-2]
main_loop:
	mov	dx, offset typeln
	mov ah, 09h
	int 21h
	mov al, es:[0]
	call PRINT
	
	mov	dx, offset sectorln
	mov ah, 09h
	int 21h
	mov ax, es:[1]
	mov DX, offset free
	cmp ax, 0000h
	je escape
	mov DX, offset xms
	cmp ax, 0006h
	je escape
	mov DX, offset driver
	cmp ax, 0007h
	je escape
	mov DX, offset msdos
	cmp ax, 0008h
	je escape
	mov DX, offset occup
	cmp ax, 0fffah
	je escape
	mov DX, offset blocked
	cmp ax, 0fffdh
	je escape
	mov DX, offset maxumb
	cmp ax, 0fffeh
	je escape
	mov DX, offset ending
	xchg ah, al
	mov cl, ah
	call print
	mov al, cl
	call print
	
	mov dx, offset aftersec
	mov ah, 09h
	int 21h
	
	escape:
		mov AH,09h
		int 21h
	
	
		mov ax, es:[3]
		mov cx, 16
		mul cx 
		mov si, offset mcbsize + 13
		call WRD_TO_DEC
		mov dx, offset mcbsize
		mov ah, 09h
		int 21h
		
		mov dx, offset padding
		mov ah, 09h
		int 21h
		
		mov dx, offset lbytes
		mov ah, 09h
		int 21h
	
		mov cx,8
		mov si,8
		mov ah, 2
		not_eight:	
			mov dl, es:[si]
			int 21h
			inc si
			loop not_eight
			mov dx, offset endln
			mov ah, 09h
			int 21h
			mov al, es:[0]
			cmp al, 5Ah
			je return
			mov bx, es
			add bx, es:[3]
			inc bx
			mov es, bx
			jmp main_loop
	
return:
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
	END START;