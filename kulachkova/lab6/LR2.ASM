TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
; ДАННЫЕ

MEMO		db	'Inaccessible memory address:     ',0DH,0AH,'$'
ENVadd		db	'Environment address:     ',0DH,0AH,'$'
CMLT		db  'Command line tail: ',0DH,0AH,'$'
CMLTemp		db  'The command line tail is empty',0DH,0AH,'$'
ENVcont		db	'Environment contents:',0DH,0AH,'$'
PATH		db	'Program path:',0DH,0AH,'$'
ENDL		db	' ',0DH,0AH,'$'
; ПРОЦЕДУРЫ
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
;вывод сегментного адреса недоступной памяти
		  mov DI,offset MEMO
		  add DI,32	;смещаемся в конец строки
		  mov AX,DS:[02h]
		  ;преобразуем адрес в строку с числом в 16 с/с
		  call WRD_TO_HEX
		  mov DX,offset MEMO
		  mov AH,09h	;выводим адрес
		  int 21h
		  
;вывод сегментного адреса среды, передаваемой программе
		  mov DI,offset ENVadd
		  add DI,24 ;смещаемся в конец строки
		  mov AX,DS:[2Ch]
		  ;преобразуем адрес в строку с числом в 16 с/с
		  call WRD_TO_HEX
		  mov DX,offset ENVadd
		  mov AH,09h	;выводим адрес
		  int 21h
		  
;вывод хвоста командной строки
		  sub CX,CX
		  mov CL,DS:[80h]	;записываем количество символов в хвосте в счетчик для цикла
		  cmp CX,0	;если хвост пустой, пишем, что хвост пустой
		  je empty
		  mov DX,offset CMLT
		  mov AH,09h
		  int 21h
		  mov BX,0			;инициализация второго счетчика
		  mov ES,DS:[81h]	;записываем в DS адрес хвоста командной строки
		  mov AH,02h
wrt_t:	  mov DL,ES:[BX]	;посимвольно выводим хвост
		  int 21h
		  inc BX
		  loop wrt_t
		  mov DX,offset ENDL
		  mov AH,09h
		  int 21h
		  jmp en
		  
empty:	  mov DX,offset CMLTemp
		  mov AH,09h
		  int 21h
		  
;вывод содержимого среды
en:		  mov DX,offset ENVcont
		  mov AH,09h
		  int 21h
		  mov ES,DS:[2Ch]	;запись адреса среды в ES
		  mov BX,0			;инициализация счетчика
wrt_env:  mov DL,ES:[BX]	;посимвольно выводим содержимое среды
		  cmp DL,00h
		  jne prt_env
		  mov DX,offset ENDL
		  mov AH,09h
		  int 21h
		  inc BX
		  mov DL,ES:[BX]
		  cmp DL,00h		;если считан второй 0 подряд, дальше идет маршрут программы
		  je prt_path
prt_env:  mov AH,02h		;вывод символа
		  int 21h
		  inc BX
		  jmp wrt_env
		  
;вывод пути загружаемого модуля		  
prt_path: mov DX,offset PATH
		  mov AH,09h
		  int 21h
		  mov AH,02h
		  add BX,3
wrt_p:	  mov DL,ES:[BX]	;посимвольно выводим путь модуля
		  cmp DL,00h		;0 - признак конца пути
		  je prt_endl
		  int 21h
		  inc BX
		  jmp wrt_p

prt_endl: mov DX,offset ENDL
		  mov AH,09h
		  int 21h
;. . . . . . . . . . . .
; Выход в DOS
EX:		  mov AH,01h
		  int 21h
		  mov AH,4Ch
		  int 21h
TESTPC ENDS
		END START ;конец модуля START - точка входа