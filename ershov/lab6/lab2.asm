TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: 	JMP	BEGIN

SegAddInMem		db		'Segment address of inaccessible memory:     h', 0dh, 0ah, '$'
SegAddEnv		db		'Segment address of environment:     h', 0dh, 0ah, '$'
CommTail		db		'Command line tail in symbolic form: ', '$'
NoSymb			db		'There are no characters in the tail of the command line!', 0dh, 0ah, '$'
ContEnv			db		'The contents of the environment in symbolic form:', 0dh, 0ah, '$'
DirectLine		db		'Path of program:', 0dh, 0ah, '$'



Endline			db		0dh, 0ah, '$'



TETR_TO_HEX	PROC near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC near

		push	cx
		mov		ah,al
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX 
		pop		cx 			
		ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX	PROC near

		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		xor		ah,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX	ENDP

BYTE_TO_DEC	PROC near

		push	cx
		push	dx
		push	ax
		xor		ah,ah
		xor		dx,dx
		mov		cx,10
loop_bd:div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		loop_bd
		cmp		ax,00h
		jbe		end_l
		or		al,30h
		mov		[si],al
end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC	ENDP

PRINT	PROC 	near
		push 	ax
		mov 	ah,09h
		int		21h
		pop 	ax
		ret
PRINT	ENDP	

BEGIN:	
		;Segment address of inaccessible memory
		mov 	ax, es:[02h]
		mov		di, offset SegAddInMem + 43
		call 	WRD_TO_HEX
		mov		dx, offset SegAddInMem
		call 	PRINT
		
		;Segment address of environment
		mov 	ax, es:[2Ch]
		mov		di, offset SegAddEnv + 35
		call 	WRD_TO_HEX
		mov		dx, offset SegAddEnv
		call 	PRINT
		
		;Сommand line tail in symbolic form
		sub 	cx, cx
		mov		cl, es:[80h]
		cmp		cl, 0
		je		fin
		lea		dx, CommTail
		call	PRINT
		mov		ah, 02h
		mov		bx, 0
	cycle:
			mov 	dl ,es:[bx+81h]
			int 	21h
			inc 	bx
		loop	cycle
		lea		dx, Endline
		call 	PRINT
		jmp 	Envir
	fin:	
		lea		dx, NoSymb
		call 	PRINT
		
		;The contents of the environment
	Envir:
		lea		dx, ContEnv
		call 	PRINT
		mov 	ax, es:[2Ch]
		mov 	es, ax
		mov		bx, 0
		mov 	ah, 02h
	copy:
		cmp		word ptr es:[bx], 0000h
		je		end_ce
		cmp		byte ptr es:[bx], 00h
		jne		print_symb
		lea		dx, Endline
		call	PRINT
		inc		bx
	print_symb:
		mov		dl, es:[bx]
		int		21h
		inc		bx
		jmp		copy
	end_ce:
		lea		dx, Endline
		call	PRINT
		
		;Path of program
		add 	bx, 4;
		lea		dx, DirectLine
		call 	PRINT
		mov 	ah, 02h		
	out_path:
		cmp 	byte ptr es:[bx], 00h
		je 		end_path
		mov 	dl, es:[bx]
		int 	21h
		inc 	bx
		jmp 	out_path
	end_path:
		lea		dx, Endline
		call 	PRINT
		
		;Exit in DOS
		mov 	ah,01h
		int 	21h
		mov 	ah, 4Ch
		int 	21h
		
TESTPC 	ENDS
		END  	START