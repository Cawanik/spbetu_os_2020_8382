;------------Стек программы------------------------
AStack  SEGMENT STACK
    DW  100 DUP(0)  	
AStack  ENDS
;------------Сегмент данных------------------------
DATA    SEGMENT
	INT_SET_FL	db	0
	INT_SET		db  'Interrupt handler has already been set',0DH,0AH,'$'
	INT_REM		db  'Interrupt handler has been removed',0DH,0AH,'$'
DATA    ENDS
;------------Сегмент кода------------------------
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack
	
ROUT PROC FAR
		  jmp int_init
			INT_SGN 	dw 3940h
			KEEP_IP 	dw 0		;для хранения смещения
			KEEP_CS 	dw 0		;и сегмента старого прерывания
			KEEP_PSP 	dw 0
			KEEP_AX 	dw 0
			KEEP_SS 	dw 0
			KEEP_SP 	dw 0
			INT_STACK dw 100h DUP(0)
			REQ_KEY 	db 1Fh

int_init:
		;установка нового стека
		  mov KEEP_SS, SS
 		  mov KEEP_SP, SP
  		  mov KEEP_AX, AX
		  mov AX, seg INT_STACK
		  mov SS, AX
		  mov AX, offset INT_STACK
		  add AX, 100h
		  mov SP, AX
	
		;сохранение регистров
		  push BX
		  push CX
		  push DX
		  push SI
		  push DS
		  push BP
		  push ES
	
		;обработка скан-кода
		  in AL, 60h		;чтение ключа
		  cmp AL, REQ_KEY	;это требуемый код?
		  je do_req			;да, обработать его
		  pushf				;нет, уйти на стандартный обработчик
		  call dword ptr cs:KEEP_IP
		  jmp skip
	
do_req:
		;обработка прерывания
		  push AX
		  in AL, 61h	;берем значение порта управления клавиатурой
		  mov AH, AL	;сохраняем его
		  or AL, 80h	;устанавливаем бит разрешения для клавиатуры
		  out 61h, AL	;выводим его в управляющий порт
		  xchg AH, AL	;извлекаем исходное значение порта
		  out 61h, AL	;записываем его обратно
		  mov AL, 20h	;посылаем сигнал "конец прерывания"
		  out 20h, AL	;контроллеру прерываний
		  pop AX
	
wrt_to_buff:
		;заставляем клавиатуру "шепелявить"
		  mov AH, 05h	;код функции
		  mov CL, 'S'	;пишем символ в буфер клавиатуры
		  mov CH, 00h
		  int 16h
		  mov CL, 'H'	;и еше один символ
		  int 16h
		  

skip:
		;восстанавливаем регистры и стек
		  pop ES
		  pop BP
		  pop DS
		  pop SI
		  pop DX
		  pop CX
		  pop BX
		  mov SP, KEEP_SP
		  mov AX, KEEP_SS
		  mov SS, AX
		  mov AX, KEEP_AX
		  mov AL, 20h
		  out 20h, AL
		  iret
ROUT ENDP
INT_END:

;--------------------------------
INT_LOAD PROC near
;установка пользовательского прерывания
		  push AX
		  push BX
		  push CX
		  push DX
		  push DS
		  push ES


		  mov AH, 35h 		; функция получения вектора
		  mov AL, 09h 		; номер вектора
		  int 21h
		  mov KEEP_IP, BX 	;запоминание смещения
		  mov KEEP_CS, ES 	;и сегмента старого прерывания

	
		  push DS
		  mov DX, offset ROUT	;смещение для процедуры в DX
		  mov AX, seg ROUT		;сегмент процедуры
		  mov DS, AX			;помещаем в DS
		  mov AH, 25h	;функция установки вектора
		  mov AL, 09h	;номер вектора
		  int 21h 		;меняем прерывание
		  pop DS

		;установка резидентности
		  mov DX, offset INT_END
		  mov CL, 4h 	;перевод в параграфы
		  shr DX, CL
		  add DX, CODE
		  inc DX 
		  xor AX, AX
		  mov AH, 31h
		  int 21h

		  pop ES
		  pop DS
		  pop DX
		  pop CX
		  pop BX
		  pop AX
		  ret
INT_LOAD ENDP
;--------------------------------
INT_REMOVE PROC near
;выгрузка обработчика прерывания
		  push AX
		  push BX
		  push DX
		  push DS
		  push ES
		  push SI
		
		  cli
		;взятие текущего обработчика
		  mov AH, 35h
		  mov AL, 09h
		  int 21h
		;загрузка сохраненного обработчика
		  mov SI, offset KEEP_IP
		  sub SI, offset ROUT
		  mov DX, ES:[BX+SI]
		  mov AX, ES:[BX+SI+2]
		  push DS
		  mov DS, AX
		  mov AH, 25h
		  mov AL, 09h
		  int 21h
		  pop DS
		  sti
		;освобождение памяти, занимаемой резидентным обработчиком прерывания
		  mov AX, ES:[BX+SI+4]
		  mov ES, AX
		  push ES
		  mov AX, ES:[2Ch]
		  mov ES, AX
		  mov AH, 49h
		  int 21h
		  pop ES
		  mov AH, 49h
		  int 21h
	
		;вывод сообщения
		  mov DX,offset INT_REM
		  mov AH, 09h
    	  int 21h
		
		  pop SI
		  pop ES
		  pop DS
		  pop DX
		  pop BX
		  pop AX
		  ret
INT_REMOVE ENDP
;--------------------------------
INT_CHECK PROC near
;проверка, установлено ли пользовательское прерывание
		  push AX
		  push BX
		  push SI
		  push ES

		  mov AH, 35h   	; функция получения вектора
		  mov AL, 09h	  	; номер вектора
		  int 21h
		  mov SI, offset INT_SGN
		  sub SI, offset ROUT
		  mov AX, ES:[BX+SI]
		  cmp AX, 3940h
		  jne end_int_check
		  mov INT_SET_FL, 1

end_int_check:
		  pop ES
		  pop SI
		  pop BX
		  pop AX
		  ret
INT_CHECK ENDP
;--------------------------------
MAIN PROC FAR
		  mov AX, DATA
		  mov DS, AX
		  mov KEEP_PSP, ES	
	
		  call INT_CHECK
	
		  mov AX, KEEP_PSP
		  mov ES, AX
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
		  mov AH,INT_SET_FL
		  cmp AH,1
		  jne EX
		  call INT_REMOVE
		  jmp EX
	
check_int:
		  mov AH,INT_SET_FL
		  cmp AH, 1
		  jne set_int
		  mov DX, offset INT_SET
		  mov AH, 09h
    	  int 21h
		  jmp EX

set_int:
		  call INT_LOAD
;. . . . . . . . . . . .
; Выход в DOS
EX:
		  xor AL, AL
		  mov AH, 4Ch
		  int 21h
MAIN ENDP
CODE ENDS
	END MAIN