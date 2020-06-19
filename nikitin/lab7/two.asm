CODE SEGMENT
	ASSUME CS:CODE, DS:NOTHING, ES:NOTHING, SS:NOTHING
	
START: JMP BEGIN	
	
OVL_ADR db 13,10,'second overlay segment adress:        ',13,10,'$'

WriteMsg PROC near
	push ax
    mov ah,09h
    int 21h
	pop ax
    ret
WriteMsg ENDP

TETR_TO_HEX PROC near
    and al,0Fh
    cmp al,09
    jbe NEXT
    add al,07
NEXT:   
	add al,30h 
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push cx
    mov ah,al
    call TETR_TO_HEX
    xchg al,ah
    mov cl,4
    shr al,cl
    call TETR_TO_HEX 
    pop cx 
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
        push bx
        mov bh,ah
        call BYTE_TO_HEX
        mov [di],ah
        dec di
        mov [di],al
        dec di
        mov al,bh
        call BYTE_TO_HEX
        mov [di],ah
        dec di
        mov [di],al
        pop bx
        ret
WRD_TO_HEX ENDP

BEGIN proc far
	push ax
	push dx
	push di
	push ds
	
	mov ax, cs
	mov ds, ax
	mov bx, offset OVL_ADR
	add bx, 36
	mov di, bx
	mov ax, cs
	call WRD_TO_HEX
	lea dx, OVL_ADR
	call WriteMsg
	
	pop ds
	pop di
	pop dx
	pop ax
	retf
BEGIN ENDP
CODE ENDS
END