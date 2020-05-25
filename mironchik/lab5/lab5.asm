CODE    SEGMENT
        ASSUME cs:CODE, ds:CODE, ss:NOTHING
        org 100h

START: jmp BEGIN

INSTALLING_STR          DB      'Installing...',10,13,'$'
ALREADY_INSTALLED_STR   DB      'Interraption is already installed',10,13,'$'
NOT_INSTALLED_STR       DB      'Interruption is not installed',10,13,'$'
RESTORING_STR           DB      'Restoring default interruption...',10,13,'$'       

INT_KEY PROC FAR              ;--------------------------------- INT_KEY PROC FAR
        jmp INT_KEY_begin

 INT_KEY_data:
        ; data
        INT_KEY_sign          DW      1234h
        INT_KEY_stack         DB      100h DUP(0)
        INT_KEY_keep_int_ip   DW      0
        INT_KEY_keep_int_cs   DW      0
        INT_KEY_keep_ss       DW      0
        INT_KEY_keep_sp       DW      0

        ; code
INT_KEY_begin:
        push ds
        push ax
        mov ax, cs
        mov ds, ax

        mov INT_KEY_keep_ss, ss
        mov INT_KEY_keep_sp, sp

        mov ax, cs
        mov ss, ax
        mov sp, offset INT_KEY_stack
        add sp, 100h

        push es
        push bp
        push cx
        push bx
        push dx
        push di
        push si
        
        in al, 60h
        cmp al, 10h
        je INT_KEY_q
        jmp INT_KEY_default
        INT_KEY_default:
                pushf
                call dword ptr INT_KEY_keep_int_ip
                jmp INT_KEY_finish

        INT_KEY_q:
                mov cl, '1'
                jmp INT_KEY_handler

        INT_KEY_handler:
                in al, 61h
                mov ah, al
                or al, 80h
                out 61h, al
                xchg ah, al
                out 61h, al
                mov al, 20h
                out 20h, al
                
                mov ah, 05h 
                mov ch, 00h
                int 16h
                jmp INT_KEY_finish

INT_KEY_finish:
        pop si
        pop di
        pop dx
        pop bx
        pop cx
        pop bp
        pop es

        mov ss, INT_KEY_keep_ss
        mov sp, INT_KEY_keep_sp
        pop ax
        pop ds

        mov al, 20h
        out 20h, al
        iret
INT_KEY ENDP                  ;--------------------------------- INT_KEY ENDP


WRD_TO_DEC PROC near            ;--------------------------------- WRD_TO_DEC PROC NEAR
; input ax - value
;       di - lower num address
;       si - address of highest available num position (DI-max), or 0 if 
;            prefix isn't need  
;
; converts AX to DEC and writes to di address (to DI, DI-1, DI-2, ...)
	push bx
        push dx
        push di
        push si
        push ax

  	mov bx, 10
  	WRD_TO_DEC_loop:
                div bx
                add dl, '0'
                mov [di], dl
                xor dx, dx
                dec di
                cmp ax, 0
                jne WRD_TO_DEC_loop

        cmp si, 0
        je WRD_TO_DEC_no_prefix
        cmp si, di
        jge WRD_TO_DEC_no_prefix
        WRD_TO_DEC_prefix_loop:
                mov dl, '0'
                mov [di], dl
                dec di
                cmp di, si
                jl WRD_TO_DEC_prefix_loop

WRD_TO_DEC_no_prefix:
        pop ax
        pop si
        pop di
        pop dx
	pop bx
  	ret
WRD_TO_DEC ENDP                 ;--------------------------------- WRD_TO_DEC ENDP


LOAD_INT PROC NEAR              ;--------------------------------- LOAD_INT PROC NEAR
        mov ah, 35h
        mov al, 09h
        int 21h
        mov INT_KEY_keep_int_ip, bx
        mov INT_KEY_keep_int_cs, es

        mov dx, offset INT_KEY
        mov ah, 25h
        mov al, 09h
        int 21h

        mov dx, offset PROGRAM_END_BYTE
        mov cl, 4
        shr dx, cl
        inc dx
        mov ah, 31h
        int 21h
LOAD_INT ENDP                   ;--------------------------------- LOAD_INT ENDP


RELOAD_INT PROC NEAR            ;--------------------------------- RELOAD_INT PROC NEAR
        push dx
        push ds
        push es
        push bx

        mov ah, 35h
        mov al, 09h
        int 21h

        mov ax, es
        mov ds, ax
        mov dx, INT_KEY_keep_int_ip
        mov ax, INT_KEY_keep_int_cs
        mov ds, ax
        mov ah, 25h
        mov al, 09h
        int 21h

        push es
        mov ax, es:[2Ch]
        mov es, ax
        mov ah, 49h
        int 21h
        pop es
        int 21h

        pop bx
        pop es
        pop ds
        pop dx
        ret
RELOAD_INT ENDP                 ;--------------------------------- RELOAD_INT ENDP


CHECK_INT PROC NEAR             ;--------------------------------- CHECK_INT PROC NEAR
        push ax
        push bx
        push es

        mov ah, 35h
        mov al, 09h
        int 21h

        push ds
        mov ax, es
        mov ds, ax
        mov ax, INT_KEY_sign
        cmp ax, 1234h
        pop ds

        pop es
        pop bx
        pop ax
        ret
CHECK_INT ENDP                  ;--------------------------------- CHECK_INT ENDP


BEGIN:
        cmp byte ptr es:[81h+1], '/'
        jne LOAD_IF_NEED
        cmp byte ptr es:[81h+2], 'u'
        jne LOAD_IF_NEED
        cmp byte ptr es:[81h+3], 'n'
        jne LOAD_IF_NEED

        call CHECK_INT
        jne NOT_INSTALLED
        call RELOAD_INT
        mov dx, offset RESTORING_STR
        mov ah, 09h
        int 21h
        jmp EXIT

NOT_INSTALLED:
        mov dx, offset NOT_INSTALLED_STR
        mov ah, 09h
        int 21h
        jmp EXIT

LOAD_IF_NEED:
        call CHECK_INT
        je INSTALLED
        mov dx, offset INSTALLING_STR
        mov ah, 09h
        int 21h
        call LOAD_INT
        jmp EXIT

INSTALLED:
        mov dx, offset ALREADY_INSTALLED_STR
        mov ah, 09h
        int 21h
        jmp EXIT

EXIT:
        xor     al,al
        mov     ah,4Ch
        int     21h   
 
PROGRAM_END_BYTE:
CODE    ENDS
END START