CODE SEGMENT
    assume ss:AStack, ds:DATA, cs:CODE

LOCINT PROC FAR
    jmp self
data_:
    counter dw 0
    str db 'aaaaa - ####' ;;;;;;;
    flag dw 0110h 
    loc_cs dw 0
    loc_ip dw 0
    loc_psp dw 0
    loc_ax dw 0
    loc_ss dw 0
    loc_sp dw 0
    loc_stack dw 100h dup(?)
self:
    mov loc_ax, ax
    mov loc_ss, ss
    mov loc_sp, sp
    mov ax, seg loc_stack
    mov ss, ax
    mov sp, 100h
    push bx
    push cx
    push dx
    push si
    push ds
    mov ax, seg data_
    mov ds, ax

    inc counter
    mov ax, counter
    mov dx, 0
    mov si, offset str
    add si, 11
    call WORD_TO_DEC

    mov ah, 3 ; функция получения позиции курсора
    mov bh, 0 ; номер страницы
    int 10h
    push dx ; запоминаем 

    mov ah, 2 ; функция установки позиции курсора
    mov bh, 0 ; номер страницы
    mov dx, 0110h ; номер DH = строка, DL = столбец
    int 10h

    push es
    push bp
    mov ax, seg str
    mov es, ax
    mov bp, offset str

    mov al, 1 ; устанавливаем позицию курсора
    mov bh, 0 ; номер страницы
    mov bl, 10h ; цвет
    mov cx, 12; длина строки str
    mov ah, 13h ; вывести строку
    int 10h

    pop bp
    pop es
    pop dx
    mov ah, 2
    mov bh, 0
    int 10h

    pop ds
    pop si
    pop dx
    pop cx
    pop bx

    mov sp, loc_sp
    mov ax, loc_ss
    mov ss, ax
    mov ax, loc_ax
    mov al, 20h
    out 20h, al
    iret
LOCINT ENDP

WORD_TO_DEC PROC NEAR
    push cx
    push dx
    mov cx, 10
loop_:
    div cx
    or dl, 30h
    mov [si], dl
    dec si
    xor dx, dx
    cmp ax, 0
    jnz loop_
endloop_:
    pop dx
    pop cx
    ret
WORD_TO_DEC ENDP

point:

CHECKUNLOAD PROC
    push ax
    push es
    mov ax, loc_psp
    mov es, ax
    cmp byte ptr es:[82h], '/'
    jne skip_
    cmp byte ptr es:[83h], 'u'
    jne skip_
    cmp byte ptr es:[84h], 'n'
    jne skip_
    mov check_unload, 1
skip_:
    pop es
    pop ax
    ret
CHECKUNLOAD ENDP

CHECKLOAD PROC
    push bx
    push si
    push ax
    mov ah, 35h
    mov al, 1ch
    int 21h

    mov si, offset flag
    sub si, offset LOCINT
    mov ax, es:[bx+si]
    cmp ax, 0110h
    jne skip
    mov check_load, 1
skip:
    pop ax
    pop si
    pop bx
    ret
CHECKLOAD ENDP

LOAD PROC
    push ax
    push bx
    push cx
    push dx
    push es

    mov ah, 35h
    mov al, 1ch
    int 21h

    mov loc_cs, es
    mov loc_ip, bx

    push ds
    mov dx, offset LOCINT
    mov ax, seg LOCINT
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h

    pop ds
    mov dx, offset point
    add dx, 10fh
    mov cl, 4
    shr dx, cl
    inc dx
    xor ax, ax
    mov ah, 31h
    int 21h

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LOAD ENDP

UNLOAD PROC
    cli
    push ax
    push bx
    push dx
    push es
    push si

    mov ah, 35h
    mov al, 1ch
    int 21h
    mov si, offset loc_cs
    sub si, offset LOCINT
    mov ax, es:[bx+si]
    mov dx, es:[bx+si+2]
    
    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 1ch
    int 21h
    pop ds

    mov es, es:[bx+si+4]
    push es
    mov es, es:[2ch]
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

    pop si
    pop es
    pop dx
    pop bx
    pop ax
    sti
    ret
UNLOAD ENDP

BEGIN PROC
    mov ax, DATA
    mov ds, ax
    mov loc_psp, es
    call CHECKLOAD
    call CHECKUNLOAD

    cmp check_unload, 1
    je unload_
    cmp check_load, 1
    jne load_
    mov dx, offset str2
    mov ah, 09h
    int 21h
    jmp exit
unload_:
    cmp check_load, 1
    jne exception1
    call UNLOAD
    mov dx, offset str3
    mov ah, 09h
    int 21h
    jmp exit
exception1:
    mov dx, offset str4
    mov ah, 09h
    int 21h
    jmp exit
load_:
    mov dx, offset str1
    mov ah, 09h
    int 21h
    call LOAD
exit:
    xor al, al
    mov ah, 4ch
    int 21h
BEGIN ENDP

CODE ENDS

AStack SEGMENT STACK 'STACK'
    DW 100h DUP(?)
AStack ENDS

DATA SEGMENT
    str1 db 'Loaded', 13, 10, '$'
    str2 db 'Already loaded', 13, 10, '$'
    str3 db 'Unloadded', 13, 10, '$'
    str4 db 'Nothing to unload', 13, 10, '$'
    check_load dw 0
    check_unload dw 0
DATA ENDS

END BEGIN