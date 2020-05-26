ASTACK	SEGMENT	STACK
		DB	100h	DUP(0)
ASTACK	ENDS

DATA SEGMENT
MemN db 'Memory successfully freed', 13, 10, '$'
MemErr7 db 'Memory error - memory block was destroyed', 13, 10, '$'
MemErr8 db 'Memory error - not enough memory for function', 13, 10, '$'
MemErr9 db 'Memory error - incorrect memory block address', 13, 10, '$'
MemErrA	 db	'Memory allocation error', 13, 10, '$'
MemA db 'Memory successfully allocated', 13, 10, '$'
FileErr2 db	'File error - file is not found', 13, 10, '$'
FileErr3 db	'File error - path is not found', 13, 10, '$'
LoadOk db 'File successfully load', 13, 10, '$'
OvrlErr1 db	'Load error - incorrect function number', 13, 10, '$'
OvrlErr2 db	'Load error - file is not found', 13, 10, '$'
OvrlErr3 db	'Load error - path is not found', 13, 10, '$'
OvrlErr4 db	'Load error - too many file already open', 13, 10, '$'
OvrlErr5 db	'Load error - acces denied', 13, 10, '$'
OvrlErr8 db	'Load error - not enough memory', 13, 10, '$'
OvrlErr10 db 'Load error - incorrect enviroment', 13, 10, '$'
EndL db 13,10,'$'
Path db	128 DUP(0)
Ovrl1 db 'O1.OVL', 0
Ovrl2 db 'O2.OVL', 0
Ovrl3 db 'O3.OVL', 0
DTA	db 43 DUP(0)
OvrlSeg	dw	0
OvrlAddr dd	0
KeepSS dw 0
KeepSP dw 0
KeepDS dw 0
DataEnd dw 0
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK



Fmem PROC
	push ax
	push bx
	;определяем сколько памяти нужно оставить нашей программе
	push dx
	mov dx, offset DataEnd
	mov bx, offset ProgEnd
	add bx, dx
	push cx
	mov cl, 4
	shr bx, cl ;переводим в параграфы
	add bx, 28h 
	pop cx
	mov ah, 4Ah ;всю остальную освобождаем
	int 21h 
		jnc MRET
	cmp ax, 7
		je MERR7
	cmp ax, 8
		je MERR8
	cmp ax, 9
		je MERR9
	
MERR7:
	mov dx, offset MemErr7
	jmp MEnd
MERR8:
	mov dx, offset MemErr8
	jmp MEnd
MERR9:
	mov dx, offset MemErr9
MEnd:	
	mov ah, 09h
	int 21h
	mov ah, 4Ch 
	int 21h	
MRET:
	mov dx, offset MEMN
	mov ah, 09h
	int 21h
	pop dx
	pop bx
	pop ax
ret
FMem ENDP


FPath PROC
;dx = имя нужного файла
	push ax
	push si
	push di
	push es
	
	mov es, es:[2Ch]
	mov si, 0

EnvLoop:
	mov ah, es:[si]
	cmp ah, 0
		je EnvEnd	
	inc si
		jmp	EnvLoop
		
EnvEnd:
	inc si
	mov ah, es:[si]
	cmp ah, 0	
		jne	EnvLoop
	add si, 3	
	mov di, offset Path
Ploop:
	mov ah, es:[si]
	mov [di], ah
	cmp ah, 0		
		je PEnd
	inc si
	inc di			
		jmp Ploop
		
PEnd:
	sub	di, 6
	mov	si, dx
		
Floop:
	mov	ah, [si]
	mov	[di], ah
	cmp	ah, 0
		je FEnd
	inc	si
	inc	di
		jmp	Floop
		
FEnd:
	pop	es
	pop	di
	pop	si
	pop	ax
	ret
;берем путь нашей программы, заменяем ее имя на имя нужного файла
FPath ENDP



AllMem PROC
	push ax
	push bx
	push cx
	push dx
	
	mov	dx, offset DTA ;устанавлваем DTA адрес 
	mov	ah,1Ah 
	int	21h
	
	mov dx, offset Path
	mov cx, 0
	mov ax, 4E00h
	int 21h
		jnc	AllMemOK	
	cmp	ax, 2
		je AllMemERR2
	cmp	ax, 3
		je AllMemERR3
		
AllMemERR2:
	mov	dx, offset FileErr2
	mov ah, 09h
	int 21h
	mov dx, offset EndL
	mov ah, 09h
	int 21h
	mov	ah, 4Ch
	int	21h
		
AllMemERR3:
	mov	dx, offset FileErr3
	mov ah, 09h
	int 21h
	mov dx, offset EndL
	mov ah, 09h
	int 21h
	mov	ah, 4Ch
	int	21h
		
AllMemOK:	
	mov bx, offset DTA ; получаем размер модуля
	mov ax, [bx+1Ch]	
	mov bx, [bx+1Ah]
		
	mov cl, 12
	shl	ax, cl
	mov	cl, 4
	shr	bx, cl
	add bx, ax
	inc bx
	
	mov ah, 48h ;выделяем память
	int 21h
		jnc	AllMemEnd
			
AllMemErr:	
	mov	dx, offset MemErrA
	mov ah, 09h
	int 21h
	mov dx, offset EndL
	mov ah, 09h
	int 21h
	
	mov	ah, 4Ch
	int	21h
		
AllMemEnd:
	mov OvrlSeg, ax

	mov dx, offset MemA
	mov ah, 09h
	int 21h
	
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
AllMem ENDP



RunOvrl PROC 
	push ax
	push bx
	push dx
	push es
	
	push es
	mov	KeepDS, ds
	mov	KeepSS, ss
	mov	KeepSP, sp
	
	mov	bx, seg OvrlSeg
	mov	es, bx
	mov	bx, offset OvrlSeg
	
	mov	dx, offset Path
	mov ax, 4B03h 
	int 21h
		
	mov	ds, KeepDS
	mov	ss, KeepSS
	mov	sp, KeepSP
	pop	es
		
	jnc	RunOvrlOK
		
	cmp	ax, 1
		je	ROvrlErr1
	cmp	ax, 2
		je	ROvrlErr2
	cmp	ax, 3
		je	ROvrlErr3
	cmp	ax, 4
		je	ROvrlErr4
	cmp	ax, 5
		je	ROvrlErr5
	cmp	ax, 8
		je	ROvrlErr8
	cmp	ax, 10
		je	ROvrlErr10	
		
ROvrlErr1:
	mov	dx, offset OvrlErr1
	jmp ROvrlErr
		
ROvrlErr2:
	mov	dx, offset OvrlErr2
	jmp ROvrlErr
		
ROvrlErr3:
	mov	dx, offset OvrlErr3
	jmp ROvrlErr
	
ROvrlErr4:
	mov	dx, offset OvrlErr4
	jmp ROvrlErr
		
ROvrlErr5:
	mov	dx, offset OvrlErr5
	jmp ROvrlErr
		
ROvrlErr8:
	mov	dx, offset OvrlErr8
	jmp ROvrlErr
	
ROvrlErr10:
	mov	dx, offset OvrlErr10
	jmp ROvrlErr
ROvrlErr:
	mov ah, 09h
	int 21h
	
	mov	ax, 4C00h
	int	21h	
	
	
RunOvrlOK:
	
	mov dx, offset LoadOK
	mov ah, 09h
	int 21h
	
	mov	ax, OvrlSeg
	mov	word ptr OvrlAddr+2, ax
	call OvrlAddr ; вызываем оверлей
	
	mov	ax, OvrlSeg ;освобождаем память
	mov	es, ax
	mov	ah, 49h
	int	21h
	pop	es
	pop	dx
	pop	bx
	pop	ax
	ret
	
RunOvrl ENDP



MAIN PROC
	mov ax, DATA
	mov ds, ax	
	call FMem
	mov dx, offset Ovrl1
	call FPath
	call AllMem 
	call RunOvrl
	mov bx, 0
	mov dx, offset Ovrl2
	call FPath
	call AllMem 
	call RunOvrl
	mov bx, 0
	mov dx, offset Ovrl3
	call FPath
	call AllMem 
	call RunOvrl
		
	mov ax,4C00h 
	int 21h
MAIN ENDP
	
	ProgEND:
CODE 	ENDS
END MAIN