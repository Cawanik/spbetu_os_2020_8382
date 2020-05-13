TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

EOF EQU '$'
space db ' ', EOF
endl db ' ', 13, 10, EOF
inaccess_data db 'Segment of inaccess data: ', EOF
enironment_segment db 'Segment of environment: ', EOF
tail_of_cmd db 'Command line tail: ', EOF
environment_data db 'Environment data: ', EOF
pwd db 'Path to file: ', EOF

print PROC near
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
print ENDP

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

BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP

BEGIN:
	mov dx, offset inaccess_data
	mov ah, 09h
	int 21h
	
	mov ax, ds:[03h]
	call print
	
	mov ax, ds:[02h]
	call print
	
	mov dx, offset endl
	mov ah, 09h
	int 21h
	
	mov dx, offset enironment_segment
	mov ah, 09h
	int 21h
	
	mov ax, ds:[2dh]
	call print
	
	mov ax, ds:[2ch]
	call print
	
	mov dx, offset endl
	mov ah, 09h
	int 21h
	
	mov dx, offset tail_of_cmd
	mov ah, 09h
	int 21h
	
	mov dl, ds:[80h]
	mov bx, 0
tail_loop:
	cmp dl, 0
	je end_tail_loop
	mov al, ds:[81h+bx]
	
	push dx
	push ax
	mov dx, ax
	
	mov ah, 02h
	int 21h
	
	pop ax
	pop dx
	inc bx
	dec dl
	jmp tail_loop
end_tail_loop:
	mov dx, offset endl
	mov ah, 09h
	int 21h
	
	mov dx, offset environment_data
	mov ah, 09h
	int 21h
	
	mov ss, ds:[2ch]
	mov bx, 0
loop_env:
	mov al, ss:[bx]
	cmp al, 0
	je skip
	
	push dx
	push ax
	mov dx, ax
	mov ah, 02h
	int 21h
	pop ax
	pop dx
	inc bx
	jmp loop_env
skip:
	mov al, ss:[bx+2]
	cmp al, 0
	je end_loop_env
	
	inc bx
	mov dx, offset space
	mov ah, 09h
	int 21h
	jmp loop_env
end_loop_env:
	mov dx, offset endl
	mov ah, 09h
	int 21h
	
	mov dx, offset pwd
	mov al, 09h
	int 21h
	
	add bx, 3
loop_pwd:
	mov al, ss:[bx]
	cmp al, 0
	je _end
	push dx
	push ax
	mov dx, ax
	mov ah, 02h
	int 21h
	
	pop ax
	pop dx
	inc bx
	jmp loop_pwd
_end:
	xor al, al
	mov ah, 4ch
	int 21h
TESTPC ENDS
	END START;
