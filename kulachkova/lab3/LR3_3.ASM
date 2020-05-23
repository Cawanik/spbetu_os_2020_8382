TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
; ДАННЫЕ

QAcc		db	'Size of accessable memory:        B',0DH,0AH,'$'
SExp		db	'Size of expanded memory:       KB',0DH,0AH,'$'
MCBlock		db	'MCB:',0DH,0AH,'$'
MCBtype		db	09H,'Block type:   , $'
PSPadd		db	'PSP address or special flag:     ',0DH,0AH,'$'
MBsize		db	09H,'Size of memory block:        B, $'
LastSym		db	'Last symbols: $'
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
;----------------------
WRD_TO_DEC PROC near
;перевод в 10 с/с 16-разрядного числа
;в DX:АХ - число, в SI - адрес последнего символа
		  push CX
		  mov CX,10
loop_wd:  div CX
		  or DL,30h
		  mov [SI],DL
		  dec SI
		  xor DX,DX
		  cmp AX,10
		  jae loop_wd
		  cmp AL,00h
		  je end_lwd
		  or AL,30h
		  mov [SI],AL
end_lwd:  pop CX
		  ret
WRD_TO_DEC	ENDP
;-------------------------------
; КОД
BEGIN: 
;определение объема доступной памяти
		  mov AH,4Ah
		  mov BX,0FFFFh		;заведомо большая память
		  int 21h			;в BX будет доступный блок памяти
		  mov AX,BX			;в 16-байтовых параграфах
		  mov BX,16
		  mul BX
		  mov SI,offset QAcc
		  add SI,32
		  call WRD_TO_DEC
		  mov DX,offset QAcc
		  mov AH,09h
		  int 21h
		  
;освобождение неиспользованной памяти
		  mov AH,4Ah
		  mov BX,offset ProgEnd ;размер памяти программы в параграфах
		  int 21h
		 
;запрос памяти
		  mov AH,48h
		  mov BX,1000h
		  int 21h

;определение размера расширенной памяти
		  mov AL,30h	;запись адреса ячейки CMOS
		  out 70h,AL
		  in AL,71h		;чтение младшего байта
		  mov BL,AL		;размера расширенной памяти
		  mov AL,31h	;запись адреса ячейки CMOS
		  out 70h,AL
		  in AL,71h		;чтение старшего байта 
		  mov BH,AL		;размера расширенной памяти
		  mov AX,BX
		  xor DX,DX
		  mov SI,offset SExp
		  add SI,29
		  call WRD_TO_DEC
		  mov DX,offset SExp
		  mov AH,09h
		  int 21h
		  
;вывод блоков управления памятью
		  mov AH,52h		;получаем указатель на
		  int 21h			;"List of Lists"
		  mov AX,ES:[BX-2]	;записываем в BХ адрес первого МСВ
		  mov ES,AX
		  
MCB:	  mov DX,offset MCBlock
		  mov AH,09h
		  int 21h
		  ;тип
		  mov AL,ES:[00h]
		  call BYTE_TO_HEX
		  mov DI,offset MCBtype
		  mov [DI+13],AX
		  mov DX,offset MCBtype
		  mov AH,09h
		  int 21h
		  ;адрес PSP/флаг
		  mov AX,ES:[01h]
		  mov DI,offset PSPadd
		  add DI,32
		  call WRD_TO_HEX
		  mov DX,offset PSPadd
		  mov AH,09h
		  int 21h
		  ;размер участка
		  mov AX,ES:[03h]
		  mov BX,16
		  mul BX
		  mov SI,offset MBsize
		  add SI,28
		  call WRD_TO_DEC
		  mov DX,offset MBsize
		  mov AH,09h
		  int 21h
		  ;последние символы
		  mov DX,offset LastSym
		  mov AH,09h
		  int 21h
		  mov CX,8
		  mov BX,08h
lp:		  mov DL,ES:[BX]
		  mov AH,02h
		  int 21h
		  inc BX
		  loop lp
		  mov DX,offset ENDL
		  mov AH,09h
		  int 21h
		  ;последний блок
		  mov AL,ES:[00h]
		  cmp AL,5Ah
		  je EX
		  ;переход к следующему блоку
		  mov BX,ES:[03h] ;размер участка
		  mov AX,ES		  ;указатель на текущий блок
		  add AX,BX
		  inc AX
		  mov ES,AX
		  jmp MCB
		  
;. . . . . . . . . . . .
; Выход в DOS
EX:		  xor AL,AL
		  mov AH,4Ch
		  int 21H
ProgEnd:
TESTPC ENDS
		END START ;конец модуля START - точка входа