_STACK SEGMENT STACK
	DW 100h DUP(0)
_STACK ENDS

DATA SEGMENT
	PROGRAM_PATH db 80 dup(0)
	PARAMETER_BLOCK dw 0
	CMD_POINTER dd 0
	FIRST_FCB_STUB dd 0
	SECOND_FCB_STUB dd 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_DS dw 0

	EXEC_ERROR db 'Exec error: 0000', 13, 10, '$'
	RETURN_CODE db 'Return code: 00', 13, 10, '$'
	RETURN_MESSAGE db 'Return message: 00', 13, 10, '$'
	END_LINE db 13, 10, '$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:_STACK

EXIT PROC near
	xor AL, AL
	mov AH, 4ch
	int 21h
	ret
EXIT ENDP

PRINT PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

ADJUST_SIZE PROC near
	push ax
	push bx

	mov ah, 4ah
	mov bx, offset END_LABEL
	int 21h

	pop bx
	pop ax
	ret
ADJUST_SIZE ENDP

PREPARE_PARAMETER_BLOCK PROC near
	push si
	push ax

	mov si, offset CMD_POINTER
  	mov [si], es
  	mov al, 80h
  	mov [si + 2], al

  	mov si, offset FIRST_FCB_STUB
  	mov [si], es
  	mov al, 5ch
  	mov [si + 2], al
  
  	mov si, offset SECOND_FCB_STUB
  	mov [si], es
  	mov ah, 6ch
  	mov [si + 2], ah

	pop ax
	pop si
	ret
PREPARE_PARAMETER_BLOCK ENDP

FIND_START_PATH PROC near
; OUT: si - offset to end of path var
	push es
	push ax
	push dx

	mov es, es:[2ch]
	mov si, 0
	CMP_WITH_0000_AND_INC:
		mov al, es:[si]
		mov ah, es:[si+1]
		cmp ax, 0000h
		je FINISH_FIND_END_PATH
	inc si
	jmp CMP_WITH_0000_AND_INC

	FINISH_FIND_END_PATH:
	add si, 4
	pop dx
	pop ax
	pop es
	ret	
FIND_START_PATH ENDP

COPY_PATH PROC near
; IN si - start path IN PSP
; OUT di - end of path IN DATA
	push ax
	push es
	push si

	mov es, es:[2ch]
	mov di, offset PROGRAM_PATH
	CMP_WITH_COPY_AND_INC:
	mov al, es:[si]
	mov [di], al
	cmp al, 0
	je FINISH_COPY_PATH
	inc si
	inc di
	jmp CMP_WITH_COPY_AND_INC

	FINISH_COPY_PATH:
	pop si
	pop es
	pop ax
	ret
COPY_PATH ENDP

PREPARE_DATA PROC near
; OUT: ds:dx - path
	push bx
	push di

	call PREPARE_PARAMETER_BLOCK
	call FIND_START_PATH
	call COPY_PATH

	mov dx, offset PROGRAM_PATH
	sub di, 5
	mov [di], byte ptr '2'
	mov [di+1], byte ptr '.'
	mov [di+2], byte ptr 'C'
	mov [di+3], byte ptr 'O'
	mov [di+4], byte ptr 'M'

	pop di
	pop bx
	ret
PREPARE_DATA ENDP

SAVE_DATA PROC near
	mov KEEP_SS, ss
  	mov KEEP_SP, sp
  	mov KEEP_DS, ds
	ret
SAVE_DATA ENDP

RESTORE_DATA PROC near
	mov ss, KEEP_SS
  	mov sp, KEEP_SP
  	mov ds, KEEP_DS
	ret
RESTORE_DATA ENDP

TETR_TO_HEX PROC near
	and al, 0fh
	cmp al, 09
	jbe NEXT
	add al, 07
	NEXT:
		add al, 30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
; IN: al
; OUT: ax
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX
	pop cx
	ret
BYTE_TO_HEX ENDP

PROCEED_RESULT PROC near
	push ax
	push bx
	push si
	push dx

	mov ax, 4d00h
	int 21h

	mov bl, al

	mov al, ah
	call BYTE_TO_HEX
	mov si, offset RETURN_CODE
	add si, 13
	mov [si], ax

	mov dx, offset RETURN_CODE
	call PRINT

	mov al, bl
	call BYTE_TO_HEX
	mov si, offset RETURN_MESSAGE
	add si, 16
	mov [si], ax

	mov dx, offset RETURN_MESSAGE
	call PRINT

	pop dx
	pop si
	pop bx
	pop ax
	ret
PROCEED_RESULT ENDP

RUN_PROGRAM PROC near
	push ax
	push es
	push bx
	push dx
	push si

	call PREPARE_DATA
	call SAVE_DATA
	
	mov ax, seg PROGRAM_PATH
  	mov es, ax
  	mov bx, offset PARAMETER_BLOCK

  	mov ax, 4b00h
  	int 21h
	call RESTORE_DATA

	mov dx, offset END_LINE
	call PRINT

	jnc EXEC_OK

	mov bh, ah
	call BYTE_TO_HEX
	mov si, offset EXEC_ERROR
	add si, 12
	mov [si], ax
	mov al, bh
	call BYTE_TO_HEX
	add si, 2
	mov [si], ax
	mov dx, offset EXEC_ERROR
	call PRINT
	jmp FINISH_RUN_PROGRAM

	EXEC_OK:
		call PROCEED_RESULT

	FINISH_RUN_PROGRAM:
	pop si
	pop dx
	pop ax
	pop es
	pop bx
	ret
RUN_PROGRAM ENDP

MAIN:
	mov ax, DATA
	mov ds, ax

	call ADJUST_SIZE
	call RUN_PROGRAM
	
	call EXIT
	END_LABEL:
CODE ENDS
END MAIN

