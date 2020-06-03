;-------------Сегмент кода-------------------------
CODE    SEGMENT
    ASSUME  SS:AStack,DS:DATA,CS:CODE 
	
;обработчик прерывания
ROUT	PROC	FAR
		  jmp int_init
		  
		  INT_DATA:
			INT_SGN		dw  3940h
			KEEP_CS 	dw	0        ;для хранения сегмента
			KEEP_IP 	dw	0        ;и смещения старого прерывания
			KEEP_PSP	dw  0
			KEEP_SS		dw  0
			KEEP_SP		dw	0
			KEEP_AX		dw	0
			COUNTER		dw	0	 	 ;счетчик количества прерываний
			COUNTER_STR	db	'00000',0DH,0AH,'$'
			INT_STACK	dw	100 DUP(?)
			
		  int_init:
		;установка нового стека
		  mov KEEP_SS,SS
		  mov KEEP_SP,SP
		  mov KEEP_AX,AX
		  mov AX,seg INT_STACK
		  mov SS,AX
		  mov SP, offset int_init
		  
		  push DS
		  push DX
		  push SI
		  push BX
		  push CX
		  push ES
		  push BP
		  
		  mov AX,seg INT_DATA
		  mov DS,AX
		  
		;приращение счетчика
		  inc COUNTER
		  mov AX,COUNTER
		  xor DX,DX
		  mov SI,offset COUNTER_STR
		  add SI,4
		  call WRD_TO_DEC
		  		  
		;чтение позиции курсора
		  mov AH,03h
		  mov BH,00h
		  int 10h
		  ;DH,DL - текущие строка, колонка курсора
		  push DX
		  
		;установка позиции курсора
		  mov AH,02h
		  mov BH,0
		  mov DH,22
		  mov DL,60
		  int 10h
		  
		;вывод строки
		  mov AX,seg COUNTER_STR
		  mov ES,AX
		  mov BP,offset COUNTER_STR
		  mov AH,13h
		  mov AL,1
		  mov BH,0
		  mov CX,5
		  int 10h
		  		  
		;восстановление курсора
		  pop DX
		  mov AH,02h
		  mov BH,0
		  int 10h
		  
		  pop BP
		  pop ES
		  pop CX
		  pop BX
		  pop SI
		  pop DX
		  pop DS
		  
		;восстановление стека
		  mov SP,KEEP_SP
		  mov AX,KEEP_SS
		  mov SS,AX
		  mov AX,KEEP_AX
		  
		  mov AL,20h
		  out 20h,AL
		  iret
ROUT	ENDP
;-------------------
WRD_TO_DEC PROC near
;перевод в 10 с/с 16-разрядного числа
;в DX:АХ - число, в SI - адрес последнего символа
		  push AX
		  push CX
		  mov CX,10
loop_wd:  div CX
		  or DL,30h
		  mov [SI],DL
		  dec SI
		  xor DX,DX
		  cmp AL,00h
		  jne loop_wd
		  
end_lwd:  pop CX
		  pop AX
		  ret
WRD_TO_DEC	ENDP

INT_END:
;--------------------------------
INT_HAND_REM PROC NEAR
;выгрузка обработчика прерывания
		  push AX
		  push DX
		  push SI
		  push ES
		  push BX
		  ;взятие текущего обработчика
		  mov AH,35h
		  mov AL,1Ch
		  int 21h
		  ;проверка, является ли текущий обработчик пользовательским
		  mov SI,offset INT_SGN
		  sub SI,offset ROUT
		  mov AX,ES:[BX+SI]
		  cmp AX,3940h
		  jne prt_rem
		  ;загрузка сохраненного обработчика
		  mov SI, offset KEEP_CS
		  sub SI, offset ROUT
		  cli
		  push DS
		  mov DX, ES:[BX+SI+2]
		  mov AX, ES:[BX+SI]
		  mov DS, AX
		  mov AH, 25h
		  mov AL, 1Ch
		  int 21h
		  pop DS
		  sti
		  ;освобождение памяти, занимаемой резидентным обработчиком прерывания
		  mov AX,ES:[BX+SI+4]
		  mov ES,AX
		  push ES
		  mov AX,ES:[2Ch]
		  mov ES,AX
		  mov AH,49h
		  int 21h
		  pop ES
		  mov AH,49h
		  int 21h
		  ;вывод сообщения
prt_rem:
		  mov DX,offset INT_REM
		  mov AH,09h
		  int 21h
		  
		  pop BX
		  pop ES
		  pop SI
		  pop DX
		  pop AX
		  ret
INT_HAND_REM ENDP
;--------------------------------
INT_CHECK PROC NEAR
;проверка, установлено ли пользовательское прерывание
		  push AX
		  push SI
		  push ES
		  push BX
		  push DX
		  
		  mov SI,offset INT_SGN
		  sub SI,offset ROUT
		  mov AH, 35h   	; функция получения вектора
		  mov AL, 1Ch	  	; номер вектора
		  int 21h
		  mov AX,ES:[BX+SI]
		  cmp AX,3940h
		  je prt_set
		  mov AX,0
		  mov INT_SET_FL,AX
		  jmp end_int_check
		  
prt_set:		  
		  mov DX, offset INT_SET
		  mov AH,09h
		  int 21h
		  mov AX,1
		  mov INT_SET_FL,AX
		  
end_int_check:
		  pop DX
		  pop BX
		  pop ES
		  pop SI
		  pop AX
		  ret
INT_CHECK ENDP
;--------------------------------
INT_LOAD PROC NEAR
;установка написанного прерывания
		  push AX
		  push ES
		  push BX
		  push DX
		  push CX
		  
		  mov AH, 35h   	; функция получения вектора
		  mov AL, 1Ch	  	; номер вектора
		  int 21h
		  mov KEEP_IP, BX  ;запоминание смещения
		  mov KEEP_CS, ES  ;и сегмента старого прерывания
		  push DS
		  mov DX, offset ROUT ;смещение для процедуры в DX
		  mov AX, seg ROUT	  ;сегмент процедуры
		  mov DS, AX		  ;помещаем в DS
		  mov AH, 25h		  ;функция установки вектора
		  mov AL, 1Ch		  ;номер вектора
		  int 21h			  ;меняем прерывание
		  pop DS
		  ;установка резидентности
		  mov DX, offset INT_END
		  mov CL,4		;перевод в параграфы
		  shr DX,CL
		  add DX,16h
		  inc DX
		  mov AH,31h
		  int 21h
		  
		  pop CX
		  pop DX
		  pop BX
		  pop ES
		  pop AX
		  ret
INT_LOAD ENDP
;--------------------------------

MAIN	PROC	FAR
		  mov AX,DATA
		  mov DS,AX
		  
		  mov KEEP_PSP,ES
;-------проверка командной строки на наличие ключа выгрузки
		  mov AL,ES:[81h+1]
		  cmp AL,'/'
		  jne check_int
		  mov AL,ES:[81h+2]
		  cmp AL,'u'
		  jne check_int
		  mov AL,ES:[81h+3]
		  cmp AL,'n'
		  jne check_int
		  
		  call INT_HAND_REM
		  jmp EX
		  		  
check_int:
		  call INT_CHECK
		  mov AX,INT_SET_FL
		  cmp AX,1
		  je EX
		  
		  call INT_LOAD
;. . . . . . . . . . . .
; Выход в DOS
EX:		  xor AL,AL
		  mov AH,4Ch
		  int 21h
	  MAIN	ENDP
CODE    ENDS
;------------Стек программы------------------------
AStack  SEGMENT STACK
    DW  100 DUP(0)  	
AStack  ENDS
;------------Сегмент данных------------------------
DATA    SEGMENT
	INT_SET_FL	dw	0
	INT_SET		db  'Interrupt handler has already been set',0DH,0AH,'$'
	INT_REM		db  'Interrupt handler has been removed',0DH,0AH,'$'
DATA    ENDS
	END MAIN