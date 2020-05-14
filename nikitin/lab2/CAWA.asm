TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

inaccmem db 'Address of inaccessible memory is $'
addenv db 'Address of program environment is $'
linetail db 'Tail of command line is$'
dataenv db 'Environment data:  $'
path db 'Path of file: $'

endl db 10,13,'$'
space db ' $'

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

PRINT_ENDL PROC near
	mov dx,offset endl
	mov ah,09h
	int 21h
	ret
PRINT_ENDL ENDP

BEGIN:
	mov dx,offset inaccmem
	mov ah,09h
	int 21h
	mov ax,ds:[03h]
	call print
	mov ax,ds:[02h]
	call print
	
	call PRINT_ENDL
	
	mov dx,offset addenv
	mov ah,09h
	int 21h
	mov ax,ds:[2Dh]
	call print
	mov ax,ds:[2Ch]
	call print
	
	call PRINT_ENDL
		
	mov dx, offset linetail
	mov ah,09h
	int 21h
	mov dl, ds:[80h]
	mov bx, 0
tail:
	cmp dl, bl
	je end_tail
	mov al, ds:[81h+bx]
	push dx
	push ax
	mov dx, ax
	mov ah, 02h
	int 21h
	pop ax
	pop dx
	inc bl
	jmp tail	
end_tail:

	call PRINT_ENDL
		
	mov dx, offset dataenv
	mov ah,09h
	int 21h
	mov ss, ds:[2Ch]
	mov bx, 0
loop_env:
	mov al, ss:[bx]
	cmp al, 0
	je is_last
	push dx
	push ax
	mov dx, ax
	mov ah, 02h
	int 21h
	pop ax
	pop dx
	inc bx
	jmp loop_env	
is_last:
	mov al, ss:[bx+2]
	cmp al, 0
	je end_env
	inc bx
	mov dx, offset space
	mov ah,09h
	int 21h
	jmp loop_env	
end_env:
	call PRINT_ENDL
	
	mov dx, offset path
	mov ah,09h
	int 21h
	add bx, 3
loop_path:
	mov al, ss:[bx]
	cmp al, 0h
	je end_path
	push dx
	push ax
	mov dx, ax
	mov ah, 02h
	int 21h
	pop ax
	pop dx
	inc bx
	jmp loop_path
end_path:
	xor AL,AL
	mov AH,4Ch
	int 21H
	
TESTPC ENDS
	END START;