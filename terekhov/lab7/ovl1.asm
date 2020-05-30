OVERLAY SEGMENT
    assume cs:OVERLAY, ds:OVERLAY
    S:jmp MAIN
    M_ADDRESS db 'OVERLAY1:      ',0Dh,0Ah,'$'

MAIN proc near
    push ax
    push dx
    push ds
    push di
    mov ax, cs
    mov ds, ax
    lea di, M_ADDRESS
    add di, 13
    call WRD_TO_HEX
    lea dx, M_ADDRESS
    call WRITE
    pop di
    pop ds
    pop dx
    pop ax
    retf
MAIN ENDP

WRITE proc near 
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
WRITE ENDP

TETR_TO_HEX PROC near
        and al,0Fh
        cmp al,09
        jbe NEXT
        add al,07
NEXT:   add al,30h
        ret
TETR_TO_HEX ENDP
;-----------------------------------------------------
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
;-----------------------------------------------------
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
OVERLAY ENDS
END S