ASTACK	SEGMENT  STACK
	DW 100 DUP(0)	
ASTACK	ENDS

DATA SEGMENT
	MEM_ALLOC_ERROR_07_MESSAGE		DB	"MEM ALLOC ERROR: MCB WAS DESTROYED$"
	MEM_ALLOC_ERROR_08_MESSAGE		DB	"MEM ALLOC ERROR: NOT ENOUGH MEMORY$"
	MEM_ALLOC_ERROR_09_MESSAGE		DB	"MEM ALLOC ERROR: WRONG MCB ADDRESS$"
	
	LOAD_ERROR_01_MESSAGE			DB	"PROGRAM LOAD ERROR: WRONG FUNCTION NUMBER$"
	LOAD_ERROR_02_MESSAGE			DB	"PROGRAM LOAD ERROR: FILE NOT FOUND$"
	LOAD_ERROR_05_MESSAGE			DB	"PROGRAM LOAD ERROR: DISC ERROR$"
	LOAD_ERROR_08_MESSAGE			DB	"PROGRAM LOAD ERROR: NOT ENOUGH MEMORY$"
	LOAD_ERROR_10_MESSAGE			DB	"PROGRAM LOAD ERROR: WRONG ENVIROMENT STRING$"
	LOAD_ERROR_11_MESSAGE			DB	"PROGRAM LOAD ERROR: WRONG FORMAT$"
	
	TERMINATION_REASON_00_MESSAGE	DB	"TERMINATION REASON: NORMAL$"
	TERMINATION_REASON_01_MESSAGE	DB	"TERMINATION REASON: BY CTRL-BREAK$"
	TERMINATION_REASON_02_MESSAGE	DB	"TERMINATION REASON: DEVICE ERROR$"
	TERMINATION_REASON_03_MESSAGE	DB	"TERMINATION REASON: RESIDENT HAS BEEN SET$"
	TERMINATION_CODE_MESSAGE		DB	"TERMINATION CODE:   $"
	
	PARAMETER_BLOCK					DB	0
									DD	0
									DD	0
									DD	0

	PATH							DB	128 DUP(0)
	
	KEEP_SS							DW	0
	KEEP_SP							DW	0

DATA ENDS


CODE SEGMENT
	ASSUME  CS:CODE, DS:DATA, ES:NOTHING, SS:ASTACK
	
	KEEP_DS							DW	0
	
	TETR_TO_HEX PROC near
	; младшая шестн. цифра AL в шестн. цифру ASCII в AL
			and 	AL,0Fh
			cmp		AL,09
			jbe 	NEXT
			add 	AL,07
	NEXT: 	add 	AL,30h
			ret
	TETR_TO_HEX ENDP 

	BYTE_TO_HEX PROC near
	; байт в AL переводится в два шестн. числа ASCII в AX
			push 	CX
			mov 	AH,AL
			call 	TETR_TO_HEX
			xchg 	AL,AH
			mov 	CL,4
			shr 	AL,CL
			call 	TETR_TO_HEX 	; в AL старшая цифра
			pop 	CX 				; в AH младшая
			ret
	BYTE_TO_HEX ENDP 
		
	; Вывод строки по DS:DX. Логично
	PRINT_STRING PROC
		push ax
		
		mov ah, 09h
		int 21h
		
		pop ax
		ret
	PRINT_STRING ENDP
	
	; Перевод строки
	PRINT_ENDL PROC
		push ax
		push dx
		
		mov dl, 13
		mov ah, 02h
		int 21h
		mov dl, 10
		int 21h
		
		pop dx
		pop ax
		ret
	PRINT_ENDL ENDP
	
	
	FREE_EXTRA_MEMORY PROC
		push 	ax
		push 	bx
	
		; В конце сегмента, вроде, стек должен валяться,
		; поэтому 65536/16 = 4096 параграфов
		mov 	bx, 4096
		mov 	ah, 4Ah
		int 	21h
		
		jnc		FREE_EXTRA_MEMORY_RET
		
		cmp 	ax, 7
		je		MEM_ALLOC_ERROR_07
		cmp 	ax, 8
		je		MEM_ALLOC_ERROR_08
		cmp 	ax, 9
		je		MEM_ALLOC_ERROR_09
		
		MEM_ALLOC_ERROR_07:
		mov 	dx, offset MEM_ALLOC_ERROR_07_MESSAGE
		call 	PRINT_STRING
		call 	PRINT_ENDL
		jmp		MEM_ALLOC_ERROR_EXIT
		
		MEM_ALLOC_ERROR_08:
		mov 	dx, offset MEM_ALLOC_ERROR_08_MESSAGE
		call 	PRINT_STRING
		call 	PRINT_ENDL
		jmp		MEM_ALLOC_ERROR_EXIT
		
		MEM_ALLOC_ERROR_09:
		mov 	dx, offset MEM_ALLOC_ERROR_09_MESSAGE
		call 	PRINT_STRING
		call 	PRINT_ENDL
		jmp		MEM_ALLOC_ERROR_EXIT
		
		MEM_ALLOC_ERROR_EXIT:
		mov		ax, 4C00h 
		int		21h	
		
		FREE_EXTRA_MEMORY_RET:
		pop 	bx
		pop 	ax
		ret
	FREE_EXTRA_MEMORY ENDP

	
	PREPARE_BLOCK PROC
		push 	ax
		push 	bx
		push 	dx
		
		mov 	bx, offset PARAMETER_BLOCK
		mov		dx, es
		
		; Сегментный адрес среды
		mov		ax, 0
		mov 	[bx], ax
		
		; Сегмент и смещение командной строки
		mov 	[bx+2], dx 
		mov		ax, 80h
		mov 	[bx+4], ax

		; Сегмент и смещение первого FCB
		mov 	[bx+6], dx
		mov		ax, 5Ch
		mov 	[bx+8], ax
		
		; Сегмент и смещение второго FCB
		mov 	[bx+10], dx
		mov		ax, 6Ch
		mov 	[bx+12], ax
		
		pop		dx
		pop 	bx
		pop 	ax
		ret
	PREPARE_BLOCK ENDP


	RUN_PROGRAM PROC
		; Взятие пути программы
		mov 	es, es:[2Ch]
		mov 	si, 0
	
		ENVIROMENT_STRING_LOOP:
		mov 	dl, es:[si]
		cmp 	dl, 00h		
		je 		ENVIROMENT_STRING_ENDL	
		inc 	si
		jmp 	ENVIROMENT_STRING_LOOP
		
		ENVIROMENT_STRING_ENDL:
		inc 	si
		mov 	dl, es:[si]
		cmp 	dl, 00h		
		jne 	ENVIROMENT_STRING_LOOP
		add 	si, 03h	
		
		lea 	di, PATH
	
		PATH_LOOP:
		mov 	dl, es:[si]
		cmp 	dl, 00h		
		je 		PATH_ENDL	
		mov 	[di], dl	
		inc 	di			
		inc 	si			
		jmp 	PATH_LOOP
		
		PATH_ENDL:
		sub		di, 7
		mov 	[di], byte ptr 'L'
		mov 	[di+1], byte ptr 'A'	
		mov 	[di+2], byte ptr 'B'
		mov 	[di+3], byte ptr '2'
		mov 	[di+4], byte ptr '.'
		mov 	[di+5], byte ptr 'C'
		mov 	[di+6], byte ptr 'O'
		mov 	[di+7], byte ptr 'M'
		mov 	[di+8], byte ptr 00h
	
	
		; Подготовка к вызову
		mov		KEEP_DS, ds
		mov 	KEEP_SS, ss
		mov 	KEEP_SP, sp
		
		; Адрес блока параметров
		mov		ax, ds
		mov 	es, ax
		mov 	bx, offset PARAMETER_BLOCK
		
		; Адрес пути до программы
		mov		dx, offset PATH
		
		; Вызов
		mov 	ax, 4B00h
		int 	21h
		
		mov		ds, KEEP_DS
		mov		ss, KEEP_SS
		mov		sp, KEEP_SP
		call	PRINT_ENDL
		
		jnc		LOAD_OK
		
		
		
		LOAD_ERROR:
		cmp		ax, 1
		je		LOAD_ERROR_01
		cmp		ax, 2
		je		LOAD_ERROR_02
		cmp		ax, 5
		je		LOAD_ERROR_05
		cmp		ax, 8
		je		LOAD_ERROR_08
		cmp		ax, 10
		je		LOAD_ERROR_10
		cmp		ax, 11
		je		LOAD_ERROR_11

		LOAD_ERROR_01:
		lea		dx, LOAD_ERROR_01_MESSAGE
		jmp		LOAD_ERROR_PRINT
		
		LOAD_ERROR_02:
		lea		dx, LOAD_ERROR_02_MESSAGE
		jmp		LOAD_ERROR_PRINT
		
		LOAD_ERROR_05:
		lea		dx, LOAD_ERROR_05_MESSAGE
		jmp		LOAD_ERROR_PRINT
		
		LOAD_ERROR_08:
		lea		dx, LOAD_ERROR_08_MESSAGE
		jmp		LOAD_ERROR_PRINT
		
		LOAD_ERROR_10:
		lea		dx, LOAD_ERROR_10_MESSAGE
		jmp		LOAD_ERROR_PRINT
		
		LOAD_ERROR_11:
		lea		dx, LOAD_ERROR_11_MESSAGE
		
		LOAD_ERROR_PRINT:
		call	PRINT_STRING
		call	PRINT_ENDL
		
		mov 	ax,	4C00h
		int 	21h
		
		
		
		LOAD_OK:
		mov		ax, 4D00h
		int		21h
		
		cmp		ah, 0
		je		TERMINATION_REASON_00
		cmp		ah, 1
		je		TERMINATION_REASON_01
		cmp		ah, 2
		je		TERMINATION_REASON_02
		cmp		ah, 3
		je		TERMINATION_REASON_03

		TERMINATION_REASON_00:
		lea		dx, TERMINATION_REASON_00_MESSAGE
		call	PRINT_STRING
		call	PRINT_ENDL
		
		call	BYTE_TO_HEX
		mov		di, offset TERMINATION_CODE_MESSAGE
		add		di, 18
		mov		[di], al
		mov		[di+1], ah
		mov		dx, offset TERMINATION_CODE_MESSAGE
		call	PRINT_STRING
		call	PRINT_ENDL
		
		ret
		
		TERMINATION_REASON_01:
		lea		dx, TERMINATION_REASON_01_MESSAGE
		jmp		TERMINATION_REASON_PRINT
		
		TERMINATION_REASON_02:
		lea		dx, TERMINATION_REASON_02_MESSAGE
		jmp		TERMINATION_REASON_PRINT
		
		TERMINATION_REASON_03:
		lea		dx, TERMINATION_REASON_03_MESSAGE
		
		TERMINATION_REASON_PRINT:
		call	PRINT_STRING
		call	PRINT_ENDL
		
		ret
	RUN_PROGRAM ENDP


	MAIN PROC
		mov		ax, DATA
		mov		ds, ax
		
		call FREE_EXTRA_MEMORY
		call PREPARE_BLOCK
		call RUN_PROGRAM
		
		mov		ax, 4C00h 
		int		21h	
	MAIN ENDP
CODE ENDS

END MAIN
