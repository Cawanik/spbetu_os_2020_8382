AStack SEGMENT STACK 'STACK'
	DW 100h DUP(?)
AStack ENDS

DATA SEGMENT
	ERR_4Ah_7 db 'The control block of memory is destroyed',10,13,'$'
	ERR_4Ah_8 db 'Not enough memory to complete the function',10,13,'$'
	ERR_4Ah_9 db 'Invalid memory block address',10,13,'$'
    ERR_FILE_1 db 'Function number is invalid',10,13,'$'
	ERR_FILE_2 db 'File not found',10,13,'$'
	ERR_FILE_5 db 'Disc error',10,13,'$'
	ERR_FILE_8 db 'Out of memory',10,13,'$'
	ERR_FILE_10 db 'Wrong line on environment',10,13,'$'
	ERR_FILE_11 db 'Wrong format',10,13,'$'
    STD_0 db 10,13,'Program run normally',10,13,'$'
	STD_1 db 10,13,'Program run with ctrl-break',10,13,'$'
	STD_2 db 10,13,'Program run with device error',10,13,'$'
	STD_3 db 10,13,'Program run with int 31h',10,13,'$'

    NAME_FILE db 'LAB2.COM', 0

	BLOCK_ARG dw 0
			dd 0
			dd 0
			dd 0
	PATH db 50 dup (0),'$'
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_DS dw 0
	
	
	PROG_END db '    ',10,13,'$'
	EXIT db 'exit code - $'
DATA ENDS
 
CODE SEGMENT
		ASSUME SS:AStack,DS:DATA,CS:CODE
	
FREEMEM PROC near
	mov bx, offset FLAG
	mov ax, ds
	sub bx, ax
	mov cl, 4
	shr bx, cl
	mov ah, 4ah
	int 21h
	jc errfree
	jmp endfree
errfree:
	cmp ax, 7
	je exc1
	cmp ax, 8
	je exc2
	cmp ax, 9
	je exc3
exc1:
	mov dx, offset ERR_4Ah_7
	jmp endexc
exc2:
	mov dx, offset ERR_4Ah_8
	jmp endexc
exc3:
	mov dx, offset ERR_4Ah_9
endexc:
	mov ah, 9
	int 21h
	xor ax, ax
	mov ah, 4ch
	int 21h
endfree:
	ret
FREEMEM ENDP

PATHSTR PROC near 
push ax
    push es
    push si
    push di
    push dx

    mov es, es:[2Ch]
    mov si,0
    lea di, PATH
env_skip:
    mov dl, es:[si]
    cmp dl, 00
    je env_end
    inc si
    jmp env_skip
env_end:
    inc si
    mov dl, es:[si]
    cmp dl, 00
    jne env_skip
    add si, 3
write_path:
    mov dl, es:[si]
    cmp dl, 00
    je write_name
    mov [di], dl
    inc si
    inc di
    jmp write_path
write_name:
    mov si,0
file_name:
    mov dl, byte ptr [NAME_FILE+si]
    mov byte ptr [di-8], dl
    inc di
    inc si
    test dl, dl
    jne file_name

    mov KEEP_SS, ss
    mov KEEP_SP, sp

    pop dx
    pop di
    pop si
    pop es
    pop ax
    ret
PATHSTR ENDP

TETR_TO_HEX PROC near 
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
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

BEGIN PROC  far
	mov bx, es
	mov ax, DATA
	mov ds, ax
	mov KEEP_DS, ds
	mov KEEP_SP, sp
	mov KEEP_SS, ss
	
	call FREEMEM
	call PATHSTR
	
	push ds
	mov KEEP_SP, sp
	mov KEEP_SS, ss
	pop es
	mov bx, offset BLOCK_ARG
	mov dx, offset PATH
	mov ax, 4B00h
	int 21h
	mov bx, ax
	mov ax, DATA
	mov ds, ax
	mov ax, bx
	mov ds, KEEP_DS
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	jc errorint
	mov ah, 4dh
	int 21h
	cmp ax, 0
	je ok0
	cmp ax, 1
	je ok1
	cmp ax, 2
	je ok2
	cmp ax, 3
	je ok3
ok0:
	mov dx, offset STD_0
	mov ah, 9
	int 21h
	mov di, offset PROG_END
	call BYTE_TO_HEX
	mov [di], al
	inc di
	mov [di], ah
	mov dx, offset EXIT
	mov ah, 9
	int 21h
	mov dx, offset PROG_END
	jmp endbegin
ok1:
	mov dx, offset STD_1
	jmp endbegin
ok2:
	mov dx, offset STD_2
	jmp endbegin
ok3:
	mov dx, offset STD_3
	jmp endbegin
errorint:
	cmp ax, 1
	je except1
	cmp ax, 2
	je except2
	cmp ax, 5
	je except5
	cmp ax, 8
	je except8
	cmp ax, 10
	je except10
	cmp ax, 11
	je except11
except1:
	mov dx, offset ERR_FILE_1
	jmp endbegin
except2:
	mov dx, offset ERR_FILE_2
	jmp endbegin
except5:
	mov dx, offset ERR_FILE_5
	jmp endbegin
except8:
	mov dx, offset ERR_FILE_8
	jmp endbegin
except10:
	mov dx, offset ERR_FILE_10
	jmp endbegin
except11:
	mov dx, offset ERR_FILE_11
endbegin:
	mov ah, 9
	int 21h
	xor AL,AL
	mov AH,4Ch
	int 21H
BEGIN  	ENDP

CODE    ENDS
FLAG SEGMENT
FLAG ENDS
END     BEGIN 