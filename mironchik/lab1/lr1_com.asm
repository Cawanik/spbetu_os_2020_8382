MAIN    SEGMENT
        ASSUME CS:MAIN, DS:MAIN, SS:NOTHING
        ORG 100H

START:  JMP BEGIN
; DATA
FF_name db 'PC',13,10,'$'
FE_name db 'PC/XT',13,10,'$'
FB_name db 'PC/XT',13,10,'$'
FC_name db 'AT',13,10,'$'
FA_name db 'PS2 model 30',13,10,'$'
F8_name db 'PS2 model 80',13,10,'$'
FD_name db 'PCjr',13,10,'$'
F9_name db 'PC Convertible',13,10,'$'
dos_version db '00.00',13,10,'$'
serial_number db 13,10,'Serial number OEM: $'
user_serial_number db 13,10,'User serial number: $'
ENDL db 13,10,'$'

; PROCEDURES
TETR_TO_HEX     PROC    near
        and     AL, 0Fh
        cmp     AL, 09
        jbe     NEXT
        add     al,07
NEXT:   add     al, 30h
        ret
TETR_TO_HEX     ENDP
;--------------------------
BYTE_TO_HEX     PROC    near   
; input:        AL=F8h (число)
; output:       AL={f}, AH={8} (в фигурных скобках символы)
;
; переводит AL в два символа в 16-й сс в AX
; в AL находится старшая, в AH младшая цифры
        push    cx
        mov     ah,al
        call    TETR_TO_HEX
        xchg    al,ah
        mov     cl,4
        shr     al,cl
        call    TETR_TO_HEX
        pop     cx
        ret
BYTE_TO_HEX     ENDP
;--------------------------
WRD_TO_HEX      PROC    near
; input:        AX=FH7Ah (число)
;               DI={адрес} (указатель на последний символ в памяти, куда будет записан результат)
; output:       начиная с [DI-3] лежат символы числа в 16-й сс
;               AX не сохраняет начальное значение
;
; перевод AX в 16-ю сс
        push    bx
        mov     bh,ah
        call    BYTE_TO_HEX
        mov     [di],ah
        dec     di
        mov     [di],al
        dec     di
        mov     al,bh
        call    BYTE_TO_HEX
        mov     [di],ah
        dec     di
        mov     [di],al
        pop     bx
        ret
WRD_TO_HEX      ENDP

BYTE_TO_DEC     PROC    near
; input:        AL=0Fh (число)
;               SI={адрес} (адрес поля младшей цифры)
;
; перевод AL в 10-ю сс
        push    cx
        push    dx
        push    ax
        xor     ah,ah
        xor     dx,dx
        mov     cx,10
loop_bd:
        div     cx
        or      dl,30h
        mov     [si],dl
        dec     si
        xor     dx,dx
        cmp     ax,10
        jae     loop_bd
        cmp     ax,10
        je      end_l
        or      al,30h
        mov     [si],al
end_l:
        pop     ax
        pop     dx
        pop     cx
        ret
BYTE_TO_DEC     ENDP

WRITE_AL_HEX PROC NEAR
        push ax
        push dx
        call BYTE_TO_HEX

        mov dl, al
        mov al, ah
        mov ah, 02h
        int 21h

        mov dl, al
        int 21h
        pop dx
        pop ax
        ret
WRITE_AL_HEX ENDP

;--------------------------
; CODE
BEGIN:
        mov ax,0F000h
        mov es,ax
        mov al,es:[0FFFEh]
        call BYTE_TO_HEX

        mov dx, offset FF_name
        mov cx, 0FFh
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset FE_name
        mov cx, 0FEh
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset FB_name
        mov cx, 0FBh
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset FC_name
        mov cx, 0FCh
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset FA_name
        mov cx, 0FAh
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset F8_name
        mov cx, 0F8h
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset FD_name
        mov cx, 0FDh
        cmp cx, ax
        je WRITE_TYPE

        mov dx, offset F9_name
        mov cx, 0F9h
        cmp cx, ax
        je WRITE_TYPE

WRITE_TYPE:
        mov ah,09h
        int 21h

        ; Вывод версии системы
        mov ah, 30h
        int 21h

        mov si, offset dos_version
        add si,1
        call BYTE_TO_DEC

        mov si, offset dos_version
        add si, 4
        mov al, ah
        call BYTE_TO_DEC

        mov dx, offset dos_version
        mov ah, 09h
        int 21h

        ; Серийный номер OEM
        mov ah, 30h
        int 21h

        mov al, bh
        call WRITE_AL_HEX

        mov dx, offset ENDL
        mov ah, 09h
        int 21h

        ; Серийный номер пользователя
        mov ah, 30h
        int 21h

        mov al, bl
        call WRITE_AL_HEX
        mov al, ch
        call WRITE_AL_HEX
        mov al, cl
        call WRITE_AL_HEX


; Выход в DOS
        xor     al,al
        mov     ah,4Ch
        int     21h
MAIN    ENDS
        END START