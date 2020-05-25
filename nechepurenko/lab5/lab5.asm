codeseg segment
    assume cs:codeseg, ss:astack, ds:dataseg

main PROC FAR
	jmp resident_start
		
resident_data:
	inter_signature dw 1337h 
	keep_ip dw 0
	keep_cs dw 0
	keep_psp dw 0
	keep_ss	dw 0
	keep_sp	dw 0
	keep_ax	dw 0
	inter_stack dw 100 dup("?")
		
resident_start:
	mov keep_ss, ss
	mov keep_sp, sp
	mov keep_ax, ax
	
	mov ax, seg inter_stack
	mov ss, ax
	mov sp, offset resident_start
		
	push bx
	push cx
	push dx
	push si
	push ds
	push es

    in al, 60h 
    cmp al, 10h
    je resident_q
    cmp al, 11h
    je resident_w
    cmp al, 12h
    je resident_e

resident_default:
	pushf
	call dword PTR cs:keep_ip
	jmp resident_final

resident_q:
    mov cl, 'r'
    jmp resident_handler
resident_w:
    mov cl, 't'
    jmp resident_handler
resident_e:
    mov cl, 'y'
    jmp resident_handler
	
resident_handler:		
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
	
resident_final:
	pop es
	pop ds
	pop si
	pop dx
	pop cx
	pop bx
	
	mov sp, keep_sp
	mov ax, keep_ss
	mov ss, ax
	mov ax, keep_ax 
		
	mov al, 20h
	out 20h, al 
		
	iret
main ENDP
resident_part_end:


init proc far
    mov ax, dataseg
    mov ds, ax
    mov keep_psp, es
    call check_un
    mov ax, un_flag
    cmp ax, 0
    jne init_reset
    call set_inter
    jmp init_final
init_reset:
    call reset_inter
init_final:
    mov ax, 4c00h
    int 21h
    ret
init endp

set_inter proc near
    push ax
    push bx
    push dx
    push di
    push si
    push cx
    push ds
    push es


set_inter_get_prev:
    mov ax, 3509h
    int 21h
    mov keep_cs, es
    mov keep_ip, bx

set_inter_check:
    mov si, offset inter_signature
    sub si, offset main
    mov ax, es:[bx+si] ; get resident_data
    cmp ax, 1337h ; check signature to be equal 1337h
    jne set_inter_set_new

set_inter_already_set:
    mov di, offset msg_inter_already
    call print
    jmp set_inter_final

set_inter_set_new:
    push ds
    mov dx, offset main
    mov ax, seg main
    mov ds, ax
    mov ax, 2509h
    int 21h
    pop ds

    mov di, offset msg_inter_loaded
    call print

set_inter_make_resident:
    mov dx, offset resident_part_end
    xor cx, cx
    mov cl, 4
    shr dx, cl
    add dx, 16h
    inc dx
    mov ah, 31h
    int 21h
set_inter_final:
    pop es
    pop ds
    pop cx 
    pop si
    pop di
    pop dx
    pop bx
    pop ax
    ret
set_inter endp


reset_inter proc near
    push ax
    push bx
    push dx
    push ds
    push es
    push si
    push di
reset_inter_get_prev:
    mov ax, 3509h
    int 21h
    mov si, offset inter_signature
    sub si, offset main
    mov ax, es:[bx+si] ; get resident_data
    cmp ax, 1337h ; check signature to be equal 1337h
    jne reset_inter_final

reset_inter_restore:
    cli  
    push ds
    mov dx, es:[bx+si+2]; cs
    mov ax, es:[bx+si+4]; ip
    mov ds, ax
    mov ax, 2509h
    int 21h
    pop ds   
    sti
reset_inter_free_memory:
    mov ax, es:[bx+si+6]; keep_psp
    mov es, ax
    push es
    mov ax, es:[2ch]; there is adr in psp of memory needs to be free
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h
    mov di, offset msg_inter_unloaded
    call print

reset_inter_final:
    pop di
    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax
    ret
reset_inter ENDP

check_un proc near
    push ax
    push es
    mov ax, keep_psp
    mov es, ax
    ; check cmd tail
    cmp byte ptr es:[81h+1], "/"
    jne check_un_final
    cmp byte ptr es:[81h+2], "u"
    jne check_un_final
    cmp byte ptr es:[81h+3], "n"
    jne check_un_final
    cmp byte ptr es:[81h+4], 13
    jne check_un_final
    mov ax, 1
    mov un_flag, ax
check_un_final:
    pop es
    pop ax
    ret
check_un endp

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

codeseg ends

astack segment stack
    dw 100 dup("?")
astack ends

dataseg segment 
    un_flag dw 0
    msg_inter_loaded db "Interruption has been loaded", 13, 10, "$"
    msg_inter_unloaded db "Interruption has been unloaded", 13, 10, "$"
    msg_inter_already db "Interruption is already loaded", 13, 10, "$"
dataseg ends

end init