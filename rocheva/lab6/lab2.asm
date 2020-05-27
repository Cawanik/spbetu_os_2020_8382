LAB2	SEGMENT
		ASSUME CS:LAB2, DS:LAB2, ES:NOTHING, SS:NOTHING
		ORG 100H ; резервирование места для PSP
START:	JMP BEGIN

inaccessibleMemory db 'Inaccessible memory address:     .', 0DH,0AH, '$'
environmentAddress db 'Environment address:     .', 0DH,0AH, '$'
tail db 'Command Line tail:$'
endLine db 0DH,0AH, '$'
environmentContent db 'Environment content: ', 0DH,0AH, '$'
modulePath db 'Module path: $'


BEGIN:
		; сегментный адрес недоступной памяти
		mov ax, cs:[02h]
		mov di, offset inaccessibleMemory
		add di, 32
		call WRD_TO_HEX
		mov [di], ax
		mov dx, offset inaccessibleMemory
		call WRITE
		
		; сегментный адрес среды
		mov ax, cs:[2Ch]
		mov di, offset environmentAddress
		add di, 24
		call WRD_TO_HEX
		mov [di], ax
		mov dx, offset environmentAddress
		call WRITE
		
		; хвост командной строки
		mov dx, offset tail
		call WRITE
		mov cl, cs:[80h]
		mov bx, 0
writeTail:
		cmp cl, 0
		je endWrite
		mov al, cs:[81h+bx]
		push dx
		push ax
		mov dx, ax
		mov ah, 02h
		int 21h
		pop ax
		pop dx
		inc bx
		dec cl
		jmp writeTail	
endWrite:
		mov dx, offset endLine
		call WRITE
		
		; содержимое области среды
		mov dx, offset environmentContent
		call WRITE
		mov es, cs:[2Ch]
		mov bx, 0
writeEnv:
		mov al, es:[bx]
		cmp al, 0h
		je checkEnd
		push dx
		push ax
		mov dx, ax
		mov ah, 02h
		int 21h
		pop ax
		pop dx
		inc bx
		jmp writeEnv
checkEnd:
		mov al, es:[bx+2]
		cmp al, 0h
		je endWriteEnv
		inc bx
		mov dx, offset endLine
		call WRITE
		jmp writeEnv	
endWriteEnv:
		; путь загружаемого файла
		
		mov dx, offset modulePath
		call WRITE
		add bx, 3
writePath:
		mov al, es:[bx]
		cmp al, 0h
		je endWritePath
		push dx
		push ax
		mov dx, ax
		mov ah, 02h
		int 21h
		pop ax
		pop dx
		inc bx
		jmp writePath
endWritePath:
		mov dx, offset endLine
		call WRITE
		
		xor ax, ax
		mov ah, 01h
		int 21h

		mov ah, 4Ch
		int 21h
		
	
WRITE PROC near
		mov ah, 09
		int 21h
WRITE ENDP
	
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
;-------------------------------
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
	
LAB2	ENDS
		END START