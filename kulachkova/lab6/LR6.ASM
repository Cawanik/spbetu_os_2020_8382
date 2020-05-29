;------------Стек программы------------------------
AStack  SEGMENT STACK
    DW  100 DUP(0)  	
AStack  ENDS
;------------Сегмент данных------------------------
DATA    SEGMENT
	MemErr7		db	'Memory error: memory control block has been destroyed',0Dh,0Ah,'$'
	MemErr8		db	'Memory error: lack of memory',0Dh,0Ah,'$'
	MemErr9		db	'Memory error: incorrect block address',0Dh,0Ah,'$'
	ProgErr1	db	'Loading error: incorrect function number',0Dh,0Ah,'$'
	ProgErr2	db	'Loading error: file not found',0Dh,0Ah,'$'
	ProgErr5	db	'Loading error: disc error',0Dh,0Ah,'$'
	ProgErr8	db	'Loading error: lack of memory',0Dh,0Ah,'$'
	ProgErr10	db	'Loading error: incorrect environment string',0Dh,0Ah,'$'
	ProgErr11	db	'Loading error: incorrect format',0Dh,0Ah,'$'
	TermReas0	db	'Program terminated normally',0Dh,0Ah,'$'
	TermReas1	db	'Program terminated by Ctrl-Break',0Dh,0Ah,'$'
	TermReas2	db	'Device error termination',0Dh,0Ah,'$'
	TermReas3	db	'Function 31h termination',0Dh,0Ah,'$'
	TermCode	db	'Termination code:   ',0Dh,0Ah,'$'
	KEEP_SS		dw	0
	KEEP_SP		dw	0
	KEEP_DS		dw	0
	ParameterBlock	db	0
					dd	0	;командная строка
					dd	0	;1-й FCB
					dd	0	;2-й FCB
	Path		db	128 DUP(0)
	Endl		db	0Dh,0Ah,'$'
	DataEnd		dw	0
DATA    ENDS
;-------------Сегмент кода-------------------------
CODE    SEGMENT
    ASSUME  SS:AStack,DS:DATA,CS:CODE
	
;-----вывод строки---------------------	
WRITE	PROC	NEAR
		  push AX
		  mov AH,09h
		  int 21h
		  pop AX
		  ret
WRITE ENDP

;-----освобождение памяти--------------
MEMFREE	PROC	NEAR
		  push AX
		  push BX
		  push DX
		  push CX
		  mov AH,4Ah
		  mov BX,offset CodeEnd	;размер сегмента кода
		  inc BX
		  mov DX,offset DataEnd ;размер сегмента данных  
		  inc DX
		  add BX,DX
		  int 21h
		  jnc MemoryFreed ;проверяем, была ли освобождена память
		  cmp AX,7
		  je wrt_mem7
		  cmp AX,8
		  je wrt_mem8
		  cmp AX,9
		  je wrt_mem9
		  
wrt_mem7:
		  mov DX,offset MemErr7
		  jmp wrt_mem_not
wrt_mem8:
		  mov DX,offset MemErr8
		  jmp wrt_mem_not
wrt_mem9:
		  mov DX,offset MemErr9
		  jmp wrt_mem_not
wrt_mem_not:
		  call WRITE
		  mov AH,4Ch
		  int 21h
		  
MemoryFreed:
		  pop CX
		  pop DX
		  pop BX
		  pop AX
		  ret
MEMFREE	ENDP

;-----создание блока параметров-------
CREATE_PARAM_BLOCK	PROC	NEAR
		  push AX
		  push BX
		  push CX
		  
		  mov BX,offset ParameterBlock
		  mov AX,ES
						;загружаем сегментный адрес среды
		  mov CX,0		;если адрес 0, то вызываемая программа
		  mov [BX],CX	;наследует среду вызывающей
		  
		  mov CX,80h
		  mov [BX+2],AX		;сегмент
		  mov [BX+4],CX		;и смещение командной строки
		  
		  mov CX,5Ch
		  mov [BX+6],AX		;сегмент
		  mov [BX+8],CX		;и смещение первого FCB
		  
		  mov CX,6Ch
		  mov [BX+10],AX	;сегмент
		  mov [BX+12],CX	;и смещение второго FCB
		  
		  pop CX
		  pop BX
		  pop AX
		  ret
CREATE_PARAM_BLOCK	ENDP

;-----подготовка пути-----------------
PREPARE_PATH	PROC	NEAR
		  push ES
		  push SI
		  push DI
		  push DX
		  
		  mov ES,ES:[2Ch]	;извлекаем сегментный адрес среды
		  mov SI,0			;инициализируем счетчик
EnvLoop:		  
		  mov DL,ES:[SI]	;ищем два 00h подряд - признак
		  inc SI			;конца среды
		  cmp DL,00h
		  jne EnvLoop
		  
		  mov DL,ES:[SI]
		  cmp DL,00h
		  jne EnvLoop
		  add SI,3			;нашли - маршрут смещен на два байта
							;относительно конца среды
		  mov DI,offset Path
PathLoop:					;записываем маршрут загруженной программы
		  mov DL,ES:[SI]	
		  cmp DL,00h
		  je PathEnd
		  mov [DI],DL
		  inc DI
		  inc SI
		  jmp PathLoop

PathEnd:					;добавляем имя вызываемой программы
		  sub DI,7
		  mov [DI], byte ptr 'L'
		  mov [DI+1], byte ptr 'R'
		  mov [DI+2], byte ptr '2'
		  mov [DI+3], byte ptr '.'
		  mov [DI+4], byte ptr 'C'
		  mov [DI+5], byte ptr 'O'
		  mov [DI+6], byte ptr 'M'
		  mov [DI+7], byte ptr 0
		  
		  pop DX
		  pop DI
		  pop SI
		  pop ES
		  ret
PREPARE_PATH	ENDP

;конец подготовки и загрузка программы
LOAD_IT	PROC	NEAR
		  ;сохранение регистров
		  mov KEEP_SS,SS
		  mov KEEP_SP,SP
		  mov KEEP_DS,DS
		  ;адрес блока параметров
		  mov AX,DS
		  mov ES,AX
		  mov BX,offset ParameterBlock
		  ;адрес пути до программы
		  mov DX,offset Path
		  
		  ;вызов программы
		  mov AX,4B00h
		  int 21h
		  mov DS,KEEP_DS
		  mov SP,KEEP_SP
		  mov SS,KEEP_SS
		  jnc Loaded
		  
		  ;определение кода ошибки
		  cmp AX,1
		  je LoadErr1
		  cmp AX,2
		  je LoadErr2
		  cmp AX,5
		  je LoadErr5
		  cmp AX,8
		  je LoadErr8
		  cmp AX,10
		  je LoadErr10
		  cmp AX,11
		  je LoadErr11
		  
		  ;вывод сообщения об ошибке
LoadErr1:
		  mov DX,offset ProgErr1
		  jmp wrt_msg
LoadErr2:
		 mov DX,offset ProgErr2
		  jmp wrt_msg
LoadErr5:
		  mov DX,offset ProgErr5
		  jmp wrt_msg
LoadErr8:
		  mov DX,offset ProgErr8
		  jmp wrt_msg
LoadErr10:
		  mov DX,offset ProgErr10
		  jmp wrt_msg
LoadErr11:
		  mov DX,offset ProgErr11
		  jmp wrt_msg
wrt_msg:
		  call WRITE
		  mov AH,4Ch
		  int 21h
		 
		  ;обработка завершения программы
Loaded:
		  mov DX,offset Endl	;вывод пустой строки,
		  call WRITE			;чтобы было красивенько
		  
		  mov AH,4Dh
		  int 21h
		  cmp AH,0
		  je Term0
		  cmp AH,1
		  je Term1
		  cmp AH,2
		  je Term2
		  cmp AH,3
		  je Term3
		  
		  ;вывод причины завершения
Term0:
		  mov DX,offset TermReas0
		  call WRITE
		  mov DI,offset TermCode
		  add DI,17		;вывод кода завершения
		  mov [DI],AL
		  mov [DI+1],AH
		  mov DX,offset TermCode
		  call WRITE
		  jmp end_load

Term1:
		  mov DX,offset TermReas1
		  jmp wrt_term_msg
Term2:
		  mov DX,offset TermReas2
		  jmp wrt_term_msg
Term3:
		  mov DX,offset TermReas3
		  jmp wrt_term_msg
wrt_term_msg:
		  call WRITE
end_load:		
		  ret
LOAD_IT	ENDP

;-------------------------------------	
MAIN	PROC	FAR
		  mov AX,DATA
		  mov DS,AX
		  
		  call MEMFREE
		  call CREATE_PARAM_BLOCK
		  call PREPARE_PATH
		  call LOAD_IT  
		  
EX:		  mov AH,4Ch
		  int 21h

CodeEnd:		  
	  MAIN	ENDP
CODE    ENDS
END MAIN