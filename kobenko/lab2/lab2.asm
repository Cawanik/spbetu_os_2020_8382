TESTPC	   SEGMENT
ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
ORG	   100H
START: JMP BEGIN

EOF EQU '$'

_seg_inaccess 		db 'Inaccessible memory:     ', 0DH,0AH,EOF
_seg_env		db 'Enviroment adress:     ', 0DH,0AH,EOF
_tail			db 'Command line tail:', 0DH,0AH,EOF
_endl			db  0DH,0AH,EOF
_env			db 'Enviroment: ', 0DH,0AH,EOF
_path			db 'Path: ', 0DH,0AH,EOF
_empty			db ' ', 0DH,0AH,EOF


TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT:	add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX  
	pop CX
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

SEGMENT_INACCESS PROC NEAR
	mov ax, ds:[02h]	
   	mov di, offset _seg_inaccess	 
   	add di, 24
   	call WRD_TO_HEX
   	mov dx, offset _seg_inaccess	
   	call PRINT
   	ret
SEGMENT_INACCESS ENDP

SEGMENT_ENVIROMENT PROC NEAR
	mov ax, ds:[2Ch]
   	mov di, offset _seg_env
   	add di, 22
   	call WRD_TO_HEX	
   	mov dx, offset _seg_env
   	call PRINT
   	ret
SEGMENT_ENVIROMENT ENDP

TAIL PROC NEAR
	xor cx, cx
	mov cl, ds:[80h]
	mov si, offset _tail
	add si, 18
   	cmp cl, 0h
   	je _is_empty
	xor di, di
	xor ax, ax
tail_loop: 
	mov al, ds:[81h+di]
   	inc di
   	mov [si], al
	inc si
	loop tail_loop
	mov dx, offset _tail
	jmp _end_tail
_is_empty:
	mov dx, offset _empty
_end_tail: 
   	call PRINT
   	ret
TAIL ENDP

CONTENT PROC NEAR
	mov dx, offset _env
   	call PRINT
   	xor di,di
   	mov ds, ds:[2Ch]
_str:
	cmp byte ptr [di], 00h
	jz _endline
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp _isEnd
_endline:
   	cmp byte ptr [di+1],00h
   	jz _isEnd
   	push ds
   	mov cx, cs
	mov ds, cx
	mov dx, offset _endl
	call PRINT
	pop ds
_isEnd:
	inc di
	cmp word ptr [di], 0001h
	jnz _str
	call PATH
	ret
CONTENT ENDP

PATH PROC NEAR
_Rpath:
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset _path 
	call PRINT
	pop ds
	add di, 2
path_loop:
	cmp byte ptr [di], 00h
	jz _Pend
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp path_loop
_Pend:
	ret
PATH ENDP

BEGIN:	
	call SEGMENT_INACCESS
	call SEGMENT_ENVIROMENT
	call TAIL
	call CONTENT
	xor al,al
	mov AH,4Ch
	int 21h
TESTPC ENDS
	END START;
