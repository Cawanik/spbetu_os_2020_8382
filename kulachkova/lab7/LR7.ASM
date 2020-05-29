;------------Стек программы------------------------
AStack  SEGMENT STACK
    DW  100 DUP(0)  	
AStack  ENDS
;------------Сегмент данных------------------------
DATA    SEGMENT
	MemErr7		db	'Memory error: memory control block has been destroyed',0Dh,0Ah,'$'
	MemErr8		db	'Memory error: lack of memory',0Dh,0Ah,'$'
	MemErr9		db	'Memory error: incorrect block address',0Dh,0Ah,'$'
	FileLocErr2	db	'File location error: file not found',0Dh,0Ah,'$'
	FileLocErr3	db	'File location error: path not found',0Dh,0Ah,'$'
	MemAlErr	db	'Memory allocation error',0Dh,0Ah,'$'
	ProgErr1	db	'Loading error: non-existent function',0Dh,0Ah,'$'
	ProgErr2	db	'Loading error: file not found',0Dh,0Ah,'$'
	ProgErr3	db	'Loading error: path not found',0Dh,0Ah,'$'
	ProgErr4	db	'Loading error: too many opened files',0Dh,0Ah,'$'
	ProgErr5	db	'Loading error: access denied',0Dh,0Ah,'$'
	ProgErr8	db	'Loading error: lack of memory',0Dh,0Ah,'$'
	ProgErr10	db	'Loading error: incorrect environment',0Dh,0Ah,'$'
	Ovl1		db	'OVL1.OVL',0
	Ovl2		db	'OVL2.OVL',0
	OvlSeg		dw	0
	OvlAdd		dd	0
	KEEP_SS		dw	0
	KEEP_SP		dw	0
	KEEP_DS		dw	0
	DTA			db	 43	DUP(0)
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

;-----подготовка пути-----------------
PREPARE_PATH	PROC	NEAR
;записывает в "Path" путь до искомого файла
;в DX - название файла
		  push ES
		  push SI
		  push DI
		  push AX
		  
		  mov ES,ES:[2Ch]	;извлекаем сегментный адрес среды
		  mov SI,0			;инициализируем счетчик
EnvLoop:		  
		  mov AH,ES:[SI]	;ищем два 00h подряд - признак
		  inc SI			;конца среды
		  cmp AH,00h
		  jne EnvLoop
		  
		  mov AH,ES:[SI]
		  cmp AH,00h
		  jne EnvLoop
		  add SI,3			;нашли - маршрут смещен на два байта
							;относительно конца среды
		  mov DI,offset Path
PathLoop:					;записываем маршрут загруженной программы
		  mov AH,ES:[SI]	
		  cmp AH,00h
		  je PathEnd
		  mov [DI],AH
		  inc DI
		  inc SI
		  jmp PathLoop

PathEnd:					;добавляем имя файла
		  sub DI,7
		  mov SI,DX
OvlPathLoop:
		  mov AH,[SI]
		  mov [DI],AH
		  inc SI
		  inc DI
		  cmp AH,0
		  jne OvlPathLoop
		  
		  pop AX
		  pop DI
		  pop SI
		  pop ES
		  ret
PREPARE_PATH	ENDP

;-----выделение памяти----------------
MEM_ALLOC	PROC	NEAR
		  push AX
		  push BX
		  push CX
		  push DX
		  
		  ;установка адреса DTA
		  mov AH,1Ah
		  mov DX,offset DTA
		  int 21h
		  
		  ;поиск файла
		  mov CX,0
		  mov DX,offset Path
		  mov AH,4Eh
		  int 21h
		  jnc FileFound
		  
		  ;обработка кода ошибки
		  cmp AX,2
		  je FileErr2
		  cmp AX,3
		  je FIleErr3
FileErr2:
		  mov DX,offset FileLocErr2
		  jmp wrt_file_err
FileErr3:
		  mov DX,offset FileLocErr2
		  jmp wrt_file_err
wrt_file_err:		  
		  call WRITE
		  mov AH,4Ch
		  int 21h
		  
FileFound:					;файл был найден
		  mov BX,offset DTA
		  mov AX,[BX+1Ch]	;старшее слово размера памяти
		  mov BX,[BX+1Ah]	;младшее слово размера памяти
		  
		  mov CL,12		;перевод в параграфы с учетом,
		  shl AX,CL		;что это старшее слово
		  mov CL,4
		  shr BX,CL		;перевод в параграфы
		  add BX,AX		
		  inc BX	;"округление" до большего целого числа
		  
		  mov AH,48h	;выделение блока памяти
		  int 21h
		  jnc	MemAllocated
		  mov DX,offset MemAlErr	;обработка ошибок
		  call WRITE
		  mov AH,4Ch
		  int 21h
		  
MemAllocated:
		  mov OvlSeg,AX		;сохранение сегментного адреса
		  pop DX
		  pop CX
		  pop BX
		  pop AX
		  ret
MEM_ALLOC	ENDP

;конец подготовки и загрузка программы
LOAD_IT	PROC	NEAR
		  push AX
		  push BX
		  push DX
		  push ES
		  ;сохранение регистров
		  mov KEEP_SS,SS
		  mov KEEP_SP,SP
		  mov KEEP_DS,DS
		  ;адреса параметров
		  mov BX,seg OvlSeg
		  mov ES,BX
		  mov BX,offset OvlSeg
		  ;адрес пути до оверлея
		  mov DX,offset Path
		  
		  ;загрузка оверлея
		  mov AX,4B03h
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
		  cmp AX,3
		  je LoadErr3
		  cmp AX,4
		  je LoadErr4
		  cmp AX,5
		  je LoadErr5
		  cmp AX,8
		  je LoadErr8
		  cmp AX,10
		  je LoadErr10
		  
		  ;вывод сообщения об ошибке
LoadErr1:
		  mov DX,offset ProgErr1
		  jmp wrt_msg
LoadErr2:
		 mov DX,offset ProgErr2
		  jmp wrt_msg
LoadErr3:
		  mov DX,offset ProgErr3
		  jmp wrt_msg
LoadErr4:
		  mov DX,offset ProgErr4
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
wrt_msg:
		  call WRITE
		  mov AH,4Ch
		  int 21h
		 

Loaded:
		  mov AX,OvlSeg
		  mov word ptr OvlAdd+2,AX
		  call OvlAdd	;вызов оверлея
		  
		  ;освобождение памяти
		  mov AX,OvlSeg
		  mov ES,AX
		  mov AH,49h
		  int 21h
		  
		  pop ES
		  pop DX
		  pop BX
		  pop AX
		  ret
LOAD_IT	ENDP

;-------------------------------------	
MAIN	PROC	FAR
		  mov AX,DATA
		  mov DS,AX
		  
		  call MEMFREE
		  
		  mov DX,offset Ovl1
		  call PREPARE_PATH
		  call MEM_ALLOC
		  call LOAD_IT
		  
		  xor BX,BX
		  
		  mov DX,offset Ovl2
		  call PREPARE_PATH
		  call MEM_ALLOC
		  call LOAD_IT		  
		  
EX:		  mov AH,4Ch
		  int 21h

CodeEnd:		  
	  MAIN	ENDP
CODE    ENDS
END MAIN