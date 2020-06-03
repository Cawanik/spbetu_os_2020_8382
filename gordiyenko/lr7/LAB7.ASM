DATA SEGMENT
	mem_freed db "Memory was freed successfully", 13, 10, "$"
	mem_not_freed db 13, 10, "Memory wasn't freed: $"
	mem_err_code_7 db "Memory control block destroyed$"
	mem_err_code_8 db "Not enough memory to execute function$"
	mem_err_code_9 db "Invalid memory block address$"
	
	size_err db 13, 10, "Size of the ovl wasn't get: $"
	size_err_code_2 db "File not found$"
	size_err_code_3 db "Path not found$"
	
	load_error db 13, 10, "Overline module wasn't load: $"
	load_err_code_1 db "Non-existent function$"
	load_err_code_2 db "File not found$"
	load_err_code_3 db "Path not found$"
	load_err_code_4 db "Too many open files$"
	load_err_code_5 db "No access$"
	load_err_code_8 db "No memory$"
	load_err_code_10 db "Wrong environment$"	

	ovl1 db "OVL1.OVL", 0
	ovl2 db "OVL2.OVL", 0
	
	DTA db 43 DUP(?)
	
	file_path db 100h	DUP(?)
	pos dw 0
	
	ovl_seg dw 0
	ovl_adress dd 0

	end_data db 0
DATA ENDS

AStack	SEGMENT	STACK
	db 200h DUP(?)
AStack ENDS

CODE SEGMENT
	assume cs:CODE, ds:DATA, ss:AStack 

PRINT PROC NEAR
    push ax
    mov ah, 09h
    int 21h
    pop ax 
    ret
PRINT  	ENDP

SET_PATH PROC
    push ax
    push di
    push si
    push es
    mov es, es:[2ch]
    mov si, 0

loop_:
    mov ax, es:[si]
    inc si
    cmp ax, 0
    jne loop_
    
    add si, 3
    mov di, 0
write_:
    mov al, es:[si]
    cmp al, 0
    je write_prog_name
    cmp al, '\'
    jne add_symb
    mov pos, di
add_symb:
    mov byte ptr[file_path + di], al
    inc si
    inc di
    jmp write_
    
write_prog_name:
    cld
    mov di, pos
    inc di
    add di, offset file_path
    mov si, dx
    mov ax, DATA
    mov es, ax
    
rewrite_symb:
    lodsb
    stosb
    cmp 	al, 0
    jne		rewrite_symb
    pop 	es
    pop 	si
    pop 	di
    pop		ax
    ret
SET_PATH ENDP

CHECKSIZE PROC
    push ax
    push bx 
    push cx
    push dx
    push si

    mov ax, 1a00h
    mov dx, offset DTA
    int 21h
    
    mov ax, 4e00h
    mov	cx, 0
    mov dx, offset file_path
    int 21h
    
    jnc size_ok
    
    mov	dx, offset size_err
    call PRINT
    cmp ax, 2
    je size_err_2
    cmp ax, 3
    je size_err_3
size_err_2:
    mov dx, offset size_err_code_2
    call PRINT
    jmp size_end
size_err_3:
    mov dx, offset size_err_code_3
    call PRINT
    jmp size_end
size_ok:
    mov si, offset DTA
    add si, 1ah
    mov bx, [si]
    mov ax, [si+2]
    mov cl, 4
    shr bx, cl

    mov cl, 12
    shl ax, cl

    add bx, ax
    add bx, 2

    mov ax, 4800h
    int 21h
    
    jnc set_size

    mov dx, offset mem_not_freed
    call PRINT
    jmp size_end
    
set_size:
    mov ovl_seg, ax

size_end:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CHECKSIZE ENDP

LOAD 	PROC
    push ax
    push bx
    push dx
    push es
    
    push ds
    pop  es
    mov	 bx, offset ovl_seg
    mov	 dx, offset file_path
    mov  ax, 4b03h
    int	 21h

    jnc load_ok
    
    mov dx, offset load_error
    call PRINT

    cmp ax, 1
    je load_err_1
    cmp ax, 2
    je load_err_2
    cmp ax, 3
    je load_err_3
    cmp ax, 4
    je load_err_4
    cmp ax, 5
    je load_err_5
    cmp ax, 8
    je load_err_8
    cmp ax, 10
    je load_err_10    
load_err_1:
    mov dx, offset load_err_code_1
    call PRINT
    jmp load_end
load_err_2:
    mov		dx, offset load_err_code_2
    call	PRINT
    jmp 	load_end
load_err_3:
    mov		dx, offset load_err_code_3
    call	PRINT
    jmp 	load_end
load_err_4:
    mov		dx, offset load_err_code_4
    call	PRINT
    jmp 	load_end
load_err_5:
    mov		dx, offset load_err_code_5
    call	PRINT
    jmp 	load_end
load_err_8:
    mov		dx, offset load_err_code_8
    call	PRINT
    jmp 	load_end
load_err_10:
    mov		dx, offset load_err_code_10
    call	PRINT
    jmp 	load_end
load_ok:
    mov ax, ovl_seg
    mov es, ax
    mov WORD ptr ovl_adress + 2, ax
    call ovl_adress
    mov es, ax
    mov ah, 49h
    int 21h
load_end:
    pop es
    pop dx
    pop bx
    pop ax
    ret
LOAD ENDP

Begin PROC FAR   
    mov 	ax, DATA
    mov 	ds, ax
    ;Попытка освобождения памяти
    mov bx, offset code_end
    add bx, offset end_data
    add bx, 300h

    mov cl, 4
    shr bx, cl

    add bx, 1
    
    mov ax, 4a00h
    int 21h
    
    jnc mem_freed_
    
    cmp ax, 7
    je mem_err_7
    cmp ax, 8
    je mem_err_8
    cmp ax, 9
    je mem_err_9
mem_err_7:
    mov dx, offset mem_err_code_7
    call PRINT
    jmp exit
mem_err_8:
    mov		dx, offset mem_err_code_8
    call 	PRINT		
    jmp 	exit
    
mem_err_9:
    mov		dx, offset mem_err_code_9
    call 	PRINT		
    jmp 	exit
mem_freed_:		
    mov dx, offset mem_freed
    call PRINT

    ;получаем путь до 1го оверлейного модуля
    mov dx, offset ovl1
    call SET_PATH
    call CHECKSIZE
    call LOAD
    
    ;получаем путь до 2го оверлейного модуля
    mov dx, offset ovl2
    call SET_PATH
    call CHECKSIZE
    call LOAD
exit:
    mov ah, 4ch
    int 21h
code_end:
Begin ENDP
CODE ENDS 

END Begin
