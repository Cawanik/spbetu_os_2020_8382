astack segment stack
    dw 100 dup(?)
astack ends

dataseg segment
    msg_shrink_normal db "Normal shrink!", 13, 10, "$"
    msg_shrink_destroyed db "Control block is destroyed!", 13, 10, "$"
    msg_shrink_notenough db "Not enough memory!", 13, 10, "$"
    msg_shrink_invalidadr db "Invalid address!", 13, 10, "$"
    msg_shrink_error_offset dw offset msg_shrink_destroyed
                            dw offset msg_shrink_notenough
                            dw offset msg_shrink_invalidadr
    msg_load_invalid_num_func db "Invalid function number!", 13, 10, "$"
    msg_load_fnf db "File not found!", 13, 10, "$"
    msg_load_disk db "Disk error!", 13, 10, "$"
    msg_load_notenough db "Not enough memory to load!", 13, 10, "$"
    msg_load_envir db "Invalid envir str!", 13, 10, "$"
    msg_load_format db "Invalid format!", 13, 10, "$"
    msg_load_normal db "Load lab2!", 13, 10, "$"
    msg_load_err_offset dw 0
                        dw offset msg_load_invalid_num_func
                        dw offset msg_load_fnf
                        dw 0
                        dw 0
                        dw offset msg_load_disk
                        dw 0
                        dw 0
                        dw offset msg_load_notenough
                        dw 0
                        dw offset msg_load_envir
                        dw offset msg_load_format
    msg_exit_normal db "Normal exit!", 13, 10, "$"
    msg_exit_cbreak db "Ctrl+Break exit!", 13, 10, "$"
    msg_exit_crit db "Critical error exit!", 13, 10, "$"
    msg_exit_resident db "31h exit!", 13, 10, "$"
    msg_exit_code_offset dw offset msg_exit_normal
                         dw offset msg_exit_cbreak
                         dw offset msg_exit_crit
                         dw offset msg_exit_resident
    msg_exit_code db "Exit code is   ", 13, 10, "$"
    parameter_block dw ?
                    dd ?
                    dd ?
                    dd ?
    path db 100h dup("$")
    filename db "lab2.com", 0, "$"
    keep_ss dw 0
    keep_sp dw 0
    keep_ds dw 0
    
dataseg ends

codeseg segment
    assume ds:dataseg, cs:codeseg, ss:astack

shrink_memory proc near
    push ax
    push bx
    push cx
    push di
    push si
    mov bx, offset code_end
    mov ax, es
    sub bx, ax ; get the amount of memory this program use 
    mov cl, 4
    shr bx, cl ; bx / 16 -> in paragraphs
    mov ax, 4a00h
    int 21h
    jc shrink_memory_error_occured
shrink_memory_normal:
    mov di, offset msg_shrink_normal
    call print
    jmp shrink_memory_final
shrink_memory_error_occured:
    sub ax, 7
    shl ax, 1
    mov bx, ax
    mov si, offset msg_shrink_error_offset
    mov di, ds:[si+bx]
    call print
    mov ax, 4c00h
    int 21h
shrink_memory_final:
    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret
shrink_memory endp

construct_param_block proc near
    push ax
    push bx
    push dx
    mov bx, offset parameter_block
    mov ax, 0 ; to inherit envir
    mov [bx], ax
    mov dx, es ; seg
    mov [bx+2], dx
    mov ax, 80h ; offs of num symbols in cmd
    mov [bx+4], ax
    mov [bx+6], dx ; seg
    mov ax, 5Ch ; 1st fcb
    mov [bx+8], ax
    mov [bx+10], dx
    mov ax, 6Ch ; 2nd fcb
    mov [bx+12], ax

construct_param_block_final:
    pop dx 
    pop bx
    pop ax
    ret
construct_param_block endp

construct_path proc near
    push es
    push si
    push di
    push ax
    push cx
    mov es, es:[2Ch] ; envir addr
    mov si, 0
construct_path_skip_envir:
    mov al, es:[si]
    cmp al, 0
    je construct_path_if_all_skipped
    inc si
    jmp construct_path_skip_envir

construct_path_if_all_skipped:
    inc si
    mov al, es:[si]
    cmp al, 0
    jne construct_path_skip_envir

construct_path_find_module_path:
    add si, 3
    mov di, offset path
construct_path_copy:
    mov al, es:[si]
    cmp al, 0
    je construct_path_copy_name
    mov [di], al
    inc di
    inc si
    jmp construct_path_copy

construct_path_copy_name:
    sub di, 8
    mov cx, 9
    mov si, offset filename
construct_path_copy_name_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop construct_path_copy_name_loop

construct_path_final:
    mov di, offset path
    call print
    pop bx
    pop ax
    pop di
    pop si
    pop es
    ret
construct_path endp

load_lab2 proc near
    mov keep_ss, ss
    mov keep_sp, sp
    mov keep_ds, ds
    push bx
    push dx
    push ax
    push si
    push di

    mov bx, offset parameter_block
    mov dx, offset path
    mov ax, 4b00h
    int 21h ; call lab2
    jnc load_lab2_loaded
    mov bx, ax
    mov ax, keep_ss
    mov ss, ax
    mov sp, keep_sp
    mov ax, keep_ds
    mov ds, ax
    mov si, offset msg_load_err_offset
    shl bx, 1
    mov di, ds:[si+bx]
    call print
    mov ax, 4c00h
    int 21h
load_lab2_loaded:
    mov di, offset msg_load_normal
    call print
    mov ax, 4d00h ; get exit code of last proc
    int 21h ; ax = [reason][code]
    xor bx, bx
    mov bl, ah
    shl bx, 1
    mov si, offset msg_exit_code_offset
    mov di, ds:[si+bx]
    call print

load_lab2_exit_code:
    mov di, offset msg_exit_code
    push di
    add di, 13
    call BYTE_TO_HEX
    mov [di], al
    inc di
    mov [di], ah
    pop di
    call print 

load_lab2_final:
    pop di
    pop si
    pop ax
    pop dx
    pop bx
    mov ax, 4c00h
    int 21
    ret
load_lab2 endp

main proc near
    mov ax, dataseg
    mov ds, ax
    call shrink_memory
    call construct_param_block
    call construct_path
    call load_lab2

    mov ax, 4c00h
    int 21h

main endp

print proc near
    ; prints di content
    push dx
    push ax
    mov ah, 9h
    mov dx, di
    int 21h
    pop ax
    pop dx
    ret
print endp

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP

code_end:
codeseg ends
    end main
