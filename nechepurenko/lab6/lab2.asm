
codeseg segment
    assume cs:codeseg, ds:codeseg, es:nothing, ss:nothing
    org 100h
    start: jmp begin

endline db 13, 10, "$"
inaccesible_memory db "Inaccesible memory starts at     .", 13, 10, "$"
envir_address db "Environment address is     .", 13, 10, "$"
cmd_tail db "Command line tail is ", "$"
envir_content db "Environment content: ", 13, 10, '$'
module_path db "Module path:", "$"


begin:
inaccesible_memory_label:
    mov ax, cs:[2h]
    mov di, offset inaccesible_memory
    push di
    add di, 32
    call WRD_TO_HEX
    pop di
    call print

envir_address_label:
    mov ax, cs:[2ch]
    mov di, offset envir_address
    push di
    add di, 26
    call WRD_TO_HEX
    pop di
    call print

cmd_tail_label:
    mov di, offset cmd_tail
    call print

	xor cx, cx
    mov cl, cs:[80h]
	cmp cx, 0
	je cmd_tail_end
	
	mov si, 81h
	mov ah, 02h
		
cmd_tail_loop:
	mov dl, cs:[si]
	int 21h
	inc si
	loop cmd_tail_loop
    
cmd_tail_end:
    mov di, offset endline
    call print

envir_content_label:
    mov di, offset envir_content
    call print
	mov si, 2Ch
	mov es, [si]
	mov si, 0
	mov ah, 02h
        
envir_content_outer_loop:
	mov dl, 0
	cmp dl, es:[si]
	je envir_content_end
envir_content_inner_loop:
	mov dl, es:[si]
	int 21h
	inc si
	cmp dl, 0
	jne envir_content_inner_loop
	jmp envir_content_outer_loop

envir_content_end:
    mov di, offset endline
    call print	

module_path_label:
    mov di, offset module_path
    call print

    add si, 3
module_path_loop:
    mov dl, es:[si]
    int 21h
    inc si
    cmp dl, 0
    jne module_path_loop

module_path_end:    
    mov di, offset endline
    call print


final:
    mov ax, 100h
    int 21h
    mov ah, 4ch
    int 21h

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

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
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

codeseg ends
end start