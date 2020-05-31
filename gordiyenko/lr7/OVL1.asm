CODE SEGMENT
AssUME cs:CODE, ds:NOTHING, ss:NOTHING, es:NOTHING

MAIN PROC FAR
	push ds
	push di
	push ax
	push dx

	mov ax, cs
	mov ds, ax

	mov di, offset str1
	add di, 25
	call WORD_TO_HEX
	mov dx, offset str1
	call PRINT

	pop dx
	pop ax
	pop di
	pop ds
	RETF
MAIN ENDP

str1 db 13, 10, 'First overlay -           $'

PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

TETR_TO_HEX PROC NEAR
	and al, 0fh
	cmp al, 09
	jbe NEXT
	add al, 07
NEXT: 	
	add al, 30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX
	pop cx
	ret 
BYTE_TO_HEX ENDP

WORD_TO_HEX PROC NEAR
	push bx
	mov bh, ah
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	dec di
	mov al, bh
	xor ah, ah
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	pop bx
	ret
WORD_TO_HEX ENDP
CODE ENDS
END