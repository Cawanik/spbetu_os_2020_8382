TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
; ДАННЫЕ
	;типы РС
PC_TYPE	db	'PC type:',0DH,0AH,'$'
PC		db	'PC',0DH,0AH,'$'
PCXT	db	'PC/XT',0DH,0AH,'$'
AT_		db	'AT',0DH,0AH,'$'
PS2_30	db	'PS2 model 30',0DH,0AH,'$'
PS2_80	db	'PS2 model 80',0DH,0AH,'$'
PCJR	db	'PCjr',0DH,0AH,'$'
PCCON	db	'PC Convertible',0DH,0AH,'$'
OTHER	db	'Other type: ',0DH,0AH,'$'

VERSION	db	'DOS version: ',0DH,0AH,'$'
VER_L2	db	'DOS version is < 2.0',0DH,0AH,'$'
VER		db	' $'
MODIF	db	'.$'
NUM_OEM	db	'OEM number: ',0DH,0AH,'$'
NUM_USR db	'User serial number:', 0AH, '      ', 0DH,0AH,'$'
OEM		db	' ',0DH,0AH,'$'
; ПРОЦЕДУРЫ
;----------------------
PRINT_NUM PROC near
;вывод числа из AL
		  push AX
		  mov DL,AL
		  mov AH,02h
		  int 21h
		  pop AX
PRINT_NUM	ENDP
;----------------------
TETR_TO_HEX	PROC near
		  and	AL,0Fh
		  cmp	AL,09
		  jbe	NEXT
		  add	AL,07
NEXT:	  add	AL,30h
		  ret
TETR_TO_HEX ENDP
;----------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два числа в 16 с/с
		  push	CX
		  mov	AH,AL
		  call	TETR_TO_HEX
		  xchg	AL,AH
		  mov	CL,4
		  shr	AL,CL
		  call	TETR_TO_HEX ;в AL старшая цифра, в AH - младшая
		  pop	CX
		  ret
BYTE_TO_HEX ENDP
;----------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-разрядного числа
;в АХ - число, в DI - адрес последнего символа
		  push	BX
		  mov	BH,AH
		  call	BYTE_TO_HEX
		  mov	[DI],AH
		  dec	DI
		  mov	[DI],AL
		  dec	DI
		  mov	AL,BH
		  call	BYTE_TO_HEX
		  mov	[DI],AH
		  dec	DI
		  mov	[DI],AL
		  pop	BX
		  ret
WRD_TO_HEX	ENDP
;----------------------
BYTE_TO_DEC PROC near
;перевод в 10 с/с
;в SI - адрес поля младшей цифры
		  push 	CX
		  push DX
		  xor AH,AH
		  xor DX,DX
		  mov CX,10
loop_bd:  div CX
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
end_l: 	  pop DX
		  pop CX
		  ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД
BEGIN:
;-------вывод типа ПК-----------
			mov DX,offset PC_TYPE
			mov AH,09h
			int 21h

			;чтение типа ПК
			mov AX,0F000h
			mov ES,AX
			mov AL,ES:[0FFFEh]
			
			;определение типа ПК
			cmp AL,0FFh
			je  type_PC
			cmp AL,0FEh
			je  type_PCXT
			cmp AL,0FBh
			je  type_PCXT
			cmp AL,0FCh
			je  type_AT
			cmp AL,0FAh
			je  type_PS230
			cmp AL,0F8h
			je  type_PS280
			cmp AL,0FDh
			je  type_PCJR
			cmp AL,0F9h
			je  type_PCCON
		  
			;вывод кода, если типа ПК нет в таблице
			mov DX,offset OTHER
			mov AH,09h
			int 21h
			;двоичный код переводится в 16-ричный
			call BYTE_TO_HEX
			;вывод старшей цифры
			call PRINT_NUM
			mov AL,AH
			;вывод младшей цифры
			call PRINT_NUM
			jmp sys_vers		  
		  
type_PC:  	mov DX,offset PC
			jmp print_type
type_PCXT:	mov DX,offset PCXT
			jmp print_type
type_AT:  	mov DX,offset AT_
			jmp print_type
type_PS230:	mov DX,offset PS2_30
			jmp print_type
type_PS280:	mov DX,offset PS2_80
			jmp print_type
type_PCJR:	mov DX,offset PCJR
			jmp print_type
type_PCCON:	mov DX,offset PCCON
			jmp print_type
			
		;вывод типа ПК
print_type:	mov AH,09h
			int 21h
			
;-------определение версии системы-----------			
sys_vers:	mov AH,30h	;чтение версии DOS
			int 21h
			push CX		;сохраняем серийный номер пользователя
			push BX		;сохраняем кусок номера пользователя и серийный номер OEM
			
			push AX		;сохраняем номер версии
			cmp AL,0
			je lth2
			
			mov DX, offset VERSION
			push AX		
			mov AH,09h
			int 21h
			pop AX		;в АХ номер версии
			
			;преобразуем номер версии в строку с числом в 10 с/с
			mov SI, offset VER
			call BYTE_TO_DEC
			inc SI
			;выводим номер версии
			mov DX, offset VER
			mov AH,09h
			int 21h
			pop AX		;возвращаем в АХ номер версии, чтобы вывести модификацию
			jmp modNum
			
			;версия < 2.0
lth2:		mov DX,offset VER_L2	
			mov AH,09h
			int 21h
			pop AX		;в АХ номер версии
			jmp OEMnum
			
			;вывод модификации версии
modNum:		mov DX, offset MODIF
			push AX	
			mov AH,09h
			int 21h
			pop AX		;возвращаем версию в АХ
			mov SI, offset OEM ;ОЕМ - пустая строка
			mov AL, AH	;перемещаем номер модификации в AL
			;преобразуем модификацию версии в строку с числом в 10 с/с
			call BYTE_TO_DEC
			inc SI
			mov DX, offset OEM	;выводим модификацию
			mov AH,09h
			int 21h
			
			;вывод серийного номера ОЕМ
OEMnum:		mov DX,offset NUM_OEM
			mov AH,09h 
			int 21h
			mov SI,offset OEM ;ОЕМ - строка с модификацией, которую можно переписать
			mov AL,BH	;перемещаем серийный номер в AL
			;преобразуем серийный номер в строку с числом в 10 с/с
			call BYTE_TO_DEC
			inc SI
			mov DX,offset OEM
			mov AH,09h	;выводим серийный номер
			int 21h
			
			;вывод серийного номера пользователя
			mov DI,offset NUM_USR
			add DI,25	;перемещаемся в конец строки с серийным номером
			mov AX,CX	;перемещаем кусок серийного номера в АХ
			;преобразуем серийный номер в строку с числом в 16 с/с
			call WRD_TO_HEX
			mov AL,BL	;перемещаем второй кусок серийного номера в AL
			;переводим серийный номер в 16 с/с
			;в AL будет старшая цифра, в AH - младшая
			call BYTE_TO_HEX
			;добавляем первые цифры серийного номера в строку
			sub DI,2
			mov [DI],AX
			mov DX,offset NUM_USR
			mov AH,09h	;выводим серийный номер
			int 21h
;. . . . . . . . . . . .
; Выход в DOS
EX:		  xor AL,AL
		  mov AH,4Ch
		  int 21H
TESTPC ENDS
		END START ;конец модуля START - точка входа