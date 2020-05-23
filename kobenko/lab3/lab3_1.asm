TESTPC     SEGMENT
           ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		   ORG 100H
START:     JMP MAIN

eMSG_PSP  EQU 18

MSG_MEM db 13,10, "Size available(mem/b): $" 
MSG_ENV_MEM db 13,10, "Size extended(mem/kb): $" 
MSG_NUM db 13,10,"Num: $"
MSG_PSP db 13,10,"PSP address:            $" 
MSG_SIZE db 13,10, "Size(b): $"
MSG_NAME_PROG db 13,10, "Name: $"
SPACE db 13,10, " $"
       
PRINT PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

TETR_TO_HEX   PROC  near
    and      AL,0Fh
    cmp      AL,09
    jbe      NEXT
	add      AL,07
NEXT: add      AL,30h
    ret
TETR_TO_HEX   ENDP

BYTE_TO_HEX   PROC  near
    push     CX
    mov      AH,AL
    call     TETR_TO_HEX
    xchg     AL,AH
    mov      CL,4
    shr      AL,CL
    call     TETR_TO_HEX 
    pop      CX          
    ret
BYTE_TO_HEX  ENDP

WRD_TO_HEX   PROC  near
    push     BX
    mov      BH,AH
    call     BYTE_TO_HEX
    mov      [DI],AH
    dec      DI
    mov      [DI],AL
    dec      DI
    mov      AL,BH
    call     BYTE_TO_HEX
    mov      [DI],AH
    dec      DI
    mov      [DI],AL
    pop      BX
    ret
WRD_TO_HEX ENDP

BYTE_TO_DEC   PROC  near
    push     CX
    push     DX
    xor      AH,AH
    xor      DX,DX
    mov      CX,10
_loop_bd:
    div      CX
    or       DL,30h
    mov      [SI],DL
	dec		si
    xor      DX,DX
    cmp      AX,10
    jae      _loop_bd
    cmp      AL,00h
    je       _end_l
    or       AL,30h
    mov      [SI],AL	   
_end_l:     
	pop      DX
    pop      CX
    ret
BYTE_TO_DEC    ENDP

PRINT_DEC_NUM PROC near
    xor cx, cx    
    mov bx, 10    
_start:               
    div bx
    push dx
	xor dx,dx
    inc cx
    test ax, ax
    jnz _start
_cycle:
	pop dx
    add dl, '0'
	mov ah, 02h
	int 21h
    loop _cycle  
    ret
PRINT_DEC_NUM ENDP

PRINT_MEM PROC near
	push dx
	mov dx, offset MSG_MEM
	call PRINT
	mov ah,4ah
	mov bx,0ffffh
	int 21h
	mov ax, bx
	mov bx,10h
	mul bx
	call PRINT_DEC_NUM
	pop dx
    ret	
PRINT_MEM ENDP

PRINT_EXT_MEM PROC near
	mov dx, offset MSG_ENV_MEM
	call PRINT
	mov al, 30h  
	out 70h, al   
	in al, 71h   
	mov bl, al   
	mov al, 31h  
	out 70h, al
	in al, 71h   
	mov bh, al
	mov ax, bx
	xor dx, dx
	call PRINT_DEC_NUM
	ret
PRINT_EXT_MEM ENDP

PRINT_MCB PROC near
	push AX
	push BX
	push CX
	push DX
	push ES
	push SI
	mov dx, offset SPACE
    call PRINT
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]   
	mov es, ax
	mov di, 1
_cycle_msb:
	mov dx, offset MSG_NUM
	call PRINT
	mov ax, di
	mov dx, 0
	call PRINT_DEC_NUM
	mov ax, es:[01h]
	push di
	mov di, offset MSG_PSP
	add di, eMSG_PSP
	call WRD_TO_HEX
	pop di
	mov dx, offset MSG_PSP
	call PRINT
	mov dx, offset MSG_SIZE
	call PRINT
	mov ax, es:[03h]
	mov bx,10h
	mul bx
	call PRINT_DEC_NUM
	mov dx, offset MSG_NAME_PROG
	call PRINT
	mov si, 0
	mov cx, 8
	jcxz _exit
_cycle_name:
	mov dl, es:[si+08h]
	mov ah, 02h
	int 21h
    dec cx
	inc si
    cmp cx, 0
	jne _cycle_name 
_exit:	
	mov al, es:[00h]
	cmp al, 5Ah
	je _end
	mov ax, es:[03h]
	mov bx, es
	add bx, ax
	inc bx
	mov es, bx
	mov dx, offset SPACE
	call PRINT
	inc di
    jmp _cycle_msb
_end:
	pop SI
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
	ret
PRINT_MCB ENDP

MAIN:
   call PRINT_MEM
   call PRINT_EXT_MEM
   call PRINT_MCB
   xor al, al
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START