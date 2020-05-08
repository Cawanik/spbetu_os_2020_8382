ASTACK  SEGMENT STACK
        DW 20h DUP(?)
ASTACK ENDS 

DATA SEGMENT
    PC_TYPE db "PC type - $"
    OC_VERSION db 13, 10, "OC version - $"
    OEM_NUM db 13, 10, "OEM number - $"
    S_NUM db 13, 10, "Serial number - $"
    OEM db "   $"
    DOT db ".$"
    T_PC db "PC$"
    T_XT db "PC/XT$"
    T_AT db "AT$"
    T_PS2_30 db "PS2 model 30$"
    T_PS2_50 db "PC2 model 50 or 60$"
    T_PS2_80 db "PC2 model 80$"
    T_PCJR db "PCjr$"
    T_PC_C db "PC Convertable$"
    T_UNKNOWN db "Unknown type : $"
    ENTER_SYMB db "$"
DATA ENDS

CODE	SEGMENT
		ASSUME  CS:CODE, DS:DATA, SS:ASTACK

TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT: add AL, 30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX    
    pop CX              
    ret
BYTE_TO_HEX ENDP

BYTE_TO_DEC PROC near
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd: 
    div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL
end_l: 
    pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP

PRINT_STRING PROC near
    push AX
    mov ah, 09h
	int 21h
    pop AX
    ret
PRINT_STRING ENDP

PRINT_SYMBOL PROC near
	push AX
	push BX
	push DX
	
	mov AH, 0
	mov BL, 16
	div BL
	mov DX, AX
	mov AH, 02h
	add DL, '0'
	int 21h
	mov DL, DH
	add DL, '0'
	int 21h
	
	pop DX
	pop BX
	pop AX
	ret
PRINT_SYMBOL ENDP

PRINT_PC_TYPE PROC near
    push AX
    push ES
    push DX
    mov AX, 0F000h
    mov ES, AX
    mov AL, ES:[0FFFEh]
    mov dx, offset PC_TYPE
    call PRINT_STRING
    cmp AL, 0FFh
    je pc_t
    cmp AL, 0FEh
    je xt_t
    cmp AL, 0FCh
    je at_t
    cmp AL, 0FAh
    je ps2_30_t
    cmp AL, 0FCh
    je ps2_50_t
    cmp AL, 0F8h
    je ps2_80_t
    cmp AL, 0FDh
    je pcjr_t
    cmp AL, 0F9h
    je pc_c_t
    mov dx, offset T_UNKNOWN
    call PRINT_STRING
    call BYTE_TO_HEX
    
    mov dl, al
    call PRINT_SYMBOL
    mov dl, ah
    call PRINT_SYMBOL

    jmp p_out
pc_t:
    mov dx, offset T_PC
    jmp print_end
xt_t:
    mov dx, offset T_XT
    jmp print_end
at_t:
    mov dx, offset T_AT
    jmp print_end
ps2_30_t:
    mov dx, offset T_PS2_30
    jmp print_end
ps2_50_t:
    mov dx, offset T_PS2_50
    jmp print_end
ps2_80_t:
    mov dx, offset T_PS2_80
    jmp print_end
pcjr_t:
    mov dx, offset T_PCJR
    jmp print_end
pc_c_t:
    mov dx, offset T_PC_C


print_end:
    call PRINT_STRING
p_out:
    pop DX
    pop ES
    pop AX

    ret
PRINT_PC_TYPE ENDP

PRINT_OC_VERSION Proc near
    push ax
    push dx
    mov dx, offset OC_VERSION
    call PRINT_STRING
    mov ah, 30h
    int 21h
    call PRINT_SYMBOL
    mov dx, offset DOT
    call PRINT_STRING
    mov al, ah
    call PRINT_SYMBOL
    mov dx, offset ENTER_SYMB
    call PRINT_STRING
    mov dx, offset OEM_NUM
    call PRINT_STRING
    mov si, offset OEM
	add si, 2
	mov al, bh                    
	call BYTE_TO_DEC
	mov dx, offset OEM 
    call PRINT_STRING
    mov dx, offset ENTER_SYMB
    call PRINT_STRING
    mov dx, offset S_NUM
    call PRINT_STRING
    mov al, bl
    call PRINT_SYMBOL
    mov al, ch
    call PRINT_SYMBOL
    mov al, cl
    call PRINT_SYMBOL

    pop dx
    pop ax

    ret
PRINT_OC_VERSION ENDP

MAIN PROC FAR
    push ax
    sub ax,ax
    mov ax,DATA
    mov ds,ax
    pop ax
    call PRINT_PC_TYPE
    call PRINT_OC_VERSION
	xor al, al
	mov ah, 4Ch
	int 21h
    ret
MAIN ENDP
CODE ENDS
END MAIN