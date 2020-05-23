TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

;
type_ db 'MCB Type - $'
sector db ' Sector - $'
mem db 'Available memory -        B.', 13, 10, '$'
x_mem db 'Extended memory -       B.', 13, 10, '$'
FREE db 'FREE$'
XMS db 'OS XMS UBM $'
DRIVER db 'DRIVER MEMORY $'
MS_DOS db 'MS DOS$'
OCCUPIED db 'OCCUPIED BY 386MAX UMB $'
BLOCKED db 'BLOCKED BY 386MAX UMB $'
MAX_UBM db '386MAX UMB $'

MCB_SIZE db ' Size -       $'
LAST_BYTES db ' Bytes. Last 8 bytes - $'
endl db 13, 10, '$'
MT db '$'

;
PRINT PROC near ;check
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

TETR_TO_HEX PROC near ;check
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near ;check
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

WORD_TO_DEC PROC near ;check
	push cx
	push dx
	mov cx, 10
loc_loop:
	div cx
	or dl, 30h
	mov [si], dl
	dec si
	xor dx, dx
	cmp ax, 0
	jnz loc_loop
end_loop:
	pop dx
	pop cx
	ret
WORD_TO_DEC ENDP

BEGIN:
	mov ah, 4ah
	mov bx, 0ffffh
	int 21h
	
	mov ax, bx
	mov cx, 16
	mul cx
	mov si, offset mem + 24;;;
	call WORD_TO_DEC
	mov dx, offset mem
	mov ah, 09h
	int 21h

    ; отличие от lr3-1 отсюда
    mov ah, 4ah
    mov bx, offset end_
    int 21h
    ; досюда

	xor ax, ax
	xor dx, dx
	mov al, 30h ; запись адреса ячейки CMOS
	out 70h, al
	in al, 71h  ; чтение младшего байта
	mov bl, al  ; расщиренной памяти
	mov al, 31h ; запись адреса ячейки CMOS
	out 70h, al
	in al, 71h  ; чтение старшего байта
				; размера расширенной памяти
	mov bh, al
	mov ax, bx
	mov si, offset x_mem + 22
	call WORD_TO_DEC
	mov dx, offset x_mem
	mov ah, 09h
	int 21h
	
	xor ax, ax
	mov ah, 52h
	int 21h
	mov es, es:[bx-2]
l00p: ; yes that's a loop
	mov dx, offset type_
	mov ah, 09h
	int 21h
	mov al, es:[0]
	call PRINT

	mov dx, offset sector ; check
	mov ah, 09h
	int 21h
	mov ax, es:[1]
	mov dx, offset FREE ; check
	cmp ax, 0000h
	je skip
	mov dx, offset XMS ; check
	cmp ax, 0006h
	je skip
	mov dx, offset DRIVER ; check
	cmp ax, 0007h
	je skip
	mov dx, offset MS_DOS ; check
	cmp ax, 0008h
	je skip
	mov dx, offset OCCUPIED ; check
	cmp ax, 0fffah
	je skip
	mov dx, offset BLOCKED ; check
	cmp ax, 0fffdh
	je skip
	mov dx, offset MAX_UBM ; check
	cmp ax, 0fffeh
	je skip
	mov dx, offset MT
	xchg ah, al
	mov cl, ah
	call print
	mov al, cl
	call print
skip:
	mov ah, 09h
	int 21h
	;
	;
	mov ax, es:[3]
	mov cx, 16
	mul cx
	mov si, offset MCB_SIZE + 13
	call WORD_TO_DEC
	mov dx, offset MCB_SIZE
	mov ah, 09h
	int 21h
	mov dx, offset LAST_BYTES
	mov ah, 09h
	int 21h
	
	mov cx, 8
	mov si, 8
	mov ah, 2
tt:
	mov dl, es:[si]
	int 21h
	inc si
	loop tt
	
	mov dx, offset endl
	mov ah, 09h
	int 21h
	mov al, es:[0]
	cmp al, 5ah
	je exit
	
	mov bx, es
	add bx, es:[3]
	inc bx
	mov es, bx
	jmp l00p
exit:
	xor al, al
	mov ah, 4ch
	int 21h
end_:
TESTPC ENDS
	END START;