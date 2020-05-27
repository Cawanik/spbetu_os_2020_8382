CODE SEGMENT
ASSUME cs:CODE, ds:DATA, ss:AStack
ROUT PROC far
    jmp handler_start
    HANDLER_SIGN DW 4200h
    KEEP_IP DW 0
    KEEP_CS DW 0
    KEEP_PSP DW 0
    KEEP_SS DW 0
    KEEP_SP DW 0
    KEEP_AX DW 0
    COUNT DW 0
    M_COUNT DB '00000',0Dh,0Ah,'$'
    HANDLER_STACK DW 100 DUP(0)
    stack_top:
handler_start: 
    mov KEEP_SS, ss
    mov KEEP_SP, sp
    mov KEEP_AX, ax
    mov ax, seg HANDLER_STACK
    mov ss, ax
    lea sp, stack_top
    push ax
    push bx
    push cx
    push dx
    push si
    push ds
    push bp
    push es
    
    mov ax, seg HANDLER_STACK
    mov ds, ax
    inc COUNT
    mov ax, COUNT
    xor dx, dx
    lea si, M_COUNT
    add si, 4
    call WRD_TO_DEC
;getCurs
    mov ah, 03h
    mov bh, 0
    int 10h
    push dx
;setCurs
    mov ah, 02h
    mov bh, 0
    mov dh, 22
    mov dl, 40
    int 10h
;output
    mov ax, seg M_COUNT
    mov es, ax
    lea bp, M_COUNT
    mov ah, 13h
    mov al, 1
    mov bh, 0
    mov cx, 5
    int 10h

;setCurs
    pop dx
    mov ah, 02h
    mov bh, 0
    int 10h

    pop es
    pop bp
    pop ds
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, KEEP_SP
    mov ax, KEEP_SS
    mov ss, ax
    mov ax, KEEP_AX
    mov al, 20h
    out 20h, al
    iret
ROUT ENDP
LAST_BYTE:

CHECK_IS_LOAD proc near
    push ax 
    push bx
    push si
    push dx
    push es
    mov ah, 35h
    mov al, 1ch
    int 21h
    lea si, HANDLER_SIGN
    sub si, offset ROUT
    mov ax, es:[bx+si]
    cmp ax, 4200h
    jne END_CHECK
    mov IS_LOAD, 1
END_CHECK:
    pop es
    pop dx
    pop si
    pop bx
    pop ax
    ret
CHECK_IS_LOAD ENDP

WRD_TO_DEC proc near
   push ax
   push cx
   push DX
   mov cx,10
loop_wd:
   div cx
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp ax,0
   jnz loop_wd
end_l1:
   pop DX
   pop cx
   pop ax
   ret
WRD_TO_DEC ENDP


LOAD proc near
    push ax
    push bx
    push cx
    push dx
    push ds
    push es
    
    mov ah, 35h
    mov al, 1ch
    int 21h
    mov KEEP_IP, bx
    mov KEEP_CS, es
    
    push ds
    lea dx, ROUT
    mov ax, seg ROUT
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h
    pop ds

    lea dx, LAST_BYTE
    mov cl, 4
    shr dx, cl
    add dx, 16h
    inc dx
    mov ah, 31h
    int 21h

    pop es
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LOAD ENDP

UNLOAD proc near
    cli
    push ax
    push bx
    push dx
    push es
    push si
    push ds

    mov ah, 35h
    mov al, 1ch
    int 21h
    lea si, KEEP_IP
    sub si, offset ROUT
    
    mov dx, es:[bx+si]
    mov ax, es:[bx+si+2]
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h
    pop ds
    
    mov ax, es:[bx+si+4]
    mov es, ax

    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    
    mov ah, 49h
    int 21h

end_unload:
    pop si
    pop es
    pop dx
    pop bx
    pop ax
    sti
    ret
UNLOAD ENDP

WRITE proc near 
        push ax
        mov ah,09h
        int 21h
        pop ax
        ret
WRITE ENDP

MAIN proc far
    mov ax, DATA
    mov ds, ax
    mov KEEP_PSP, es
    call CHECK_IS_LOAD
    mov al, IS_LOAD
    cmp al, 1
    je loaded
    jmp n_loaded
loaded:
    cmp byte ptr es:[81h+1], '/'
    jne end_main_loaded
    cmp byte ptr es:[81h+2], 'u'
    jne end_main_loaded
    cmp byte ptr es:[81h+3], 'n'
    jne end_main_loaded
    call UNLOAD
    jmp end_main_not_loaded
n_loaded:
    cmp byte ptr es:[81h+1], '/'
    jne load_handler
    cmp byte ptr es:[81h+2], 'u'
    jne load_handler
    cmp byte ptr es:[81h+3], 'n'
    jne load_handler
    jmp end_main_not_loaded
load_handler:
    call LOAD
    
end_main_loaded:
    lea dx, M_ALREADY_LOADED
    call WRITE
    jmp exit
end_main_not_loaded:
    lea dx, M_NOT_LOADED
    call WRITE
exit:
    xor al, al
    mov ah, 4ch
    int 21h    
MAIN ENDP
CODE ENDS
AStack SEGMENT STACK
    DW 100h DUP(?)
AStack ENDS

DATA SEGMENT
    IS_LOAD DB 0
    M_LOADED DB 'Обработчик загружен!',0Dh,0Ah,'$'
    M_NOT_LOADED DB 'Обработчик выгружен!',0Dh,0Ah,'$'
    M_ALREADY_LOADED DB 'Обработчик уже загружен!' ,0Dh,0Ah,'$'
DATA ENDS

END MAIN