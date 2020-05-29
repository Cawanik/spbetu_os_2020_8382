DATA SEGMENT
	parameters dw 0	;сегментный адрес среды
			   dd 0	;сегмент и смещение командной строки
			   dd 0	;сегмент и смещение первого FCB
			   dd 0	;сегмент и смещение второго FCB

	prog_name db "LAB2.COM", 0
	cmd db 1h, 0Dh
	path db 50h DUP(?)
	
	memory_free db "Memory was freed successfuly", 13, 10, "$"
	mem_err_code_7 db 13, 10, "Memory control block destroyed$"
	mem_err_code_8 db 13, 10, "Not enough memory to execute function$"
	mem_err_code_9 db 13, 10, "Invalid memory block address$"
	
	load_prog_msg db 13, 10, "Program was load successfuly$"
	load_prog_err db 13, 10, "Program wasn't load$"
	
	function_err db 13, 10, "Function number is incorrect$"
	file_err db 13, 10, "File not found$"
	disk_err db 13, 10, "Disk error$"
	memory_err db 13, 10, "Out of memory$"
	string_error db	13, 10, "Invalid environment string$"
	format_err db	13, 10, "Wrong format$"
	
	end_code_0 db 13, 10, "Normal end$"
	end_code_1 db 13, 10, "CTRL + C termination$"
	end_code_2 db 13, 10, "Device error$"
	end_code_3 db 13, 10, "31h end$"
	
	what_button db 13, 10, "Button preesed:  $"
	pos dw 0
	end_data db 0
DATA ENDS

ASTACK SEGMENT STACK
	dw 100h dup(?)
ASTACK ENDS

CODE SEGMENT
	ASSUME cs:CODE, ds:DATA, ss:ASTACK 

	loc_ss dw 0
	loc_sp dw 0

Write PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax 
	ret
Write ENDP

Begin PROC FAR   
	
	mov 	ax, DATA
	mov 	ds, ax
	
	;Попытка освобождения памяти
	;mov 	bx, cs
	mov 	bx, offset end_code
	add		bx, offset end_data
	add		bx, 315h
	;mov	ax, es
	;SUB 	bx, ax
	
	mov		cl, 4
	shr		bx, cl
	
	mov 	ax, 4A00h
	int		21h
	
	jnc 	MEM_FREE_SUCCES
	
	cmp		ax, 7
	je 		MEM_ERR_7
	cmp 	ax, 8
	je		MEM_ERR_8
	cmp		ax, 9
	je		MEM_ERR_9

MEM_ERR_7:
	mov		dx, offset mem_err_code_7
	call 	Write
	jmp 	exit
MEM_ERR_8:
	mov		dx, offset mem_err_code_8
	call 	Write		
	jmp 	exit
MEM_ERR_9:
	mov		dx, offset mem_err_code_9
	call 	Write		
	jmp 	exit
MEM_FREE_SUCCES:		
	mov 	dx, offset memory_free
	call	Write
	;передаём из PSP по смещению в 2ch в регистр es сегментный адрес среды
	mov 	es, es:[2ch]
	mov		si, 0
	;записываем путь в path до LAB2.COM в тек. директории
loop_:
	mov 	ax, es:[si]
	inc		si
	cmp 	ax, 0
	jne 	loop_
	add 	si, 3
	mov 	di, 0
write_:
	mov 	al, es:[si]
	cmp		al, 0
	je		write_prog_name
	cmp		al, '\'
	jne		add_symb
	mov		pos, di
add_symb:
	mov		byte ptr[path + di], al
	inc		si
	inc		di
	jmp		write_
write_prog_name:
	cld
	mov		di, pos
	inc		di
	add		di, offset path
	mov 	si, offset prog_name
	mov		ax, DATA
	mov		es, ax
rewrite_symb:
	lodsb
	stosb
	cmp 	al, 0
	jne		rewrite_symb
	;загрузка программы
	mov 	loc_sp, sp
	mov 	loc_ss, ss

	;выполняем загрузку программы
	mov 	bx, offset parameters
	mov 	dx, offset cmd
	mov		[bx + 2], dx
	mov		[bx + 4], ds
	mov 	dx, offset path
	mov 	ax, 4B00h
	int 	21h
	
	mov 	ss, cs:loc_ss
	mov 	sp, cs:loc_sp
	
	jnc		LOAD_END
	
	mov		dx, offset load_prog_err
	call 	Write
	
	cmp 	ax, 1
	je		LOAD_ERR_1
	
	cmp 	ax, 2
	je 		LOAD_ERR_2
	
	cmp 	ax, 5
	je 		LOAD_ERR_5
	
	cmp 	ax, 8
	je 		LOAD_ERR_8
	
	cmp 	ax, 10
	je 		LOAD_ERR_10
	
	cmp 	ax, 11
	je 		LOAD_ERR_11
	
LOAD_ERR_1:
	mov 	dx, offset function_err
	call 	Write
	jmp		LOAD_END_0
	
LOAD_ERR_2:
	mov 	dx, offset file_err
	call 	Write
	jmp 	LOAD_END_0
	
LOAD_ERR_5:
	mov 	dx, offset disk_err
	call 	Write
	jmp 	LOAD_END_0
		
LOAD_ERR_8:
	mov 	dx, offset memory_err
	call 	Write
	jmp 	LOAD_END_0

LOAD_ERR_10:
	mov 	dx, offset string_error
	call 	Write
	jmp 	LOAD_END_0
	
LOAD_ERR_11:
	mov 	dx, offset format_err
	call 	Write
	jmp 	LOAD_END_0
			
	
LOAD_END:
	;получаем код выхода программы
	mov		ax, 4D00h
	int		21h
	
	mov 	di, offset what_button
	mov		[di + 18], al
	mov		dx, offset what_button
	call	Write
	
	cmp		ah, 0
	je 		LOAD_END_0
	
	cmp 	ah, 1
	je 		LOAD_END_1
	
	cmp 	ah, 2
	je 		LOAD_END_2
	
	cmp 	ah, 3
	je 		LOAD_END_3
	
LOAD_END_0:
	mov 	dx, offset end_code_0
	call	Write
	jmp 	exit
	
LOAD_END_1:
	mov 	dx, offset end_code_1
	call	Write
	jmp 	exit
	
LOAD_END_2:
	mov 	dx, offset end_code_2
	call	Write
	jmp 	exit
	
LOAD_END_3:
	mov 	dx, offset end_code_3
	call	Write

exit:
	mov 	ah, 4ch
	int 	21h
end_code:
Begin		ENDP

CODE      	ENDS 

END Begin
