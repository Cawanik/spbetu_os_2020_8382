DATA SEGMENT
	PARAMETER_BLOCK dw 0
					dd 0
					dd 0
					dd 0
	PROGRAM db 'LAB2.COM', 0	
	MEM_FLAG db 0
	CMD_L db 1h, 0dh
	CL_POS db 128 dup(0)
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_PSP dw 0

	MCB_CRASH_ERR db 'ERR: MCB crashed', 0DH, 0AH, '$' 
	NO_MEM_ERR db 'ERR: there is not enough memory to execute this function', 0DH, 0AH, '$' 
	ADDR_ERR db 'ERR: invalid memory address', 0DH, 0AH, '$'
	FREE db 'memory has been freed' , 0DH, 0AH, '$'

	FN_ERR db 'ERR: invalid function number', 0DH, 0AH, '$' 
	FILE_ERR db 'ERR: file not found', 0DH, 0AH, '$' 
	DISK_ERR db 'ERR: disk error', 0DH, 0AH, '$' 
	MEM_ERR db 'ERR: insufficient memory', 0DH, 0AH, '$' 
	ENVS_ERR db 'ERR: wrong string of environment ', 0DH, 0AH, '$' 
	FORMAT_ERR db 'ERR: wrong format', 0DH, 0AH, '$' 
	
	NORMAL_END db 0DH, 0AH, 'Program ended with code    ' , 0DH, 0AH, '$'
	CTRL_END db 0DH, 0AH, 'Program ended by Ctrl-Break' , 0DH, 0AH, '$'
	DEVICE_ERR db 0DH, 0AH, 'Program ended by device error' , 0DH, 0AH, '$'
	INT_END db 0DH, 0AH, 'Program ended by int 31h' , 0DH, 0AH, '$'

	END_DATA db 0
DATA ENDS

AStack SEGMENT STACK
	DW 128 DUP(?)
AStack ENDS

CODE SEGMENT

ASSUME CS:CODE, DS:DATA, SS:AStack

PRINT PROC 
 	push AX
 	mov AH, 09h
 	int 21h 
 	pop AX
 	ret
PRINT ENDP 

MEM_FREE PROC 
	push AX
	push BX
	push CX
	push DX
	
	mov AX, offset END_DATA
	mov BX, offset _endC
	add BX, AX
	
	mov CL, 4
	shr BX, CL
	add BX, 2bh
	mov AH, 4Ah
	int 21h 

	jnc _endF
	mov MEM_FLAG, 1
	
_mcb_crash:
	cmp AX, 7
	jne _no_mem
	mov DX, offset MCB_CRASH_ERR
	call PRINT
	jmp _freeE	
_no_mem:
	cmp AX, 8
	jne _addr
	mov DX, offset NO_MEM_ERR
	call PRINT
	jmp _freeE	
_addr:
	cmp AX, 9
	mov DX, offset ADDR_ERR
	call PRINT
	jmp _freeE
_endF:
	mov MEM_FLAG, 1
	mov DX, offset FREE
	call PRINT
	
_freeE:
	pop DX
	pop CX
	pop BX
	pop AX
	ret
MEM_FREE ENDP

LOAD PROC 
	push AX
	push BX
	push CX
	push DX
	push DS
	push ES
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	
	mov AX, DATA
	mov ES, AX
	mov BX, offset PARAMETER_BLOCK
	mov DX, offset CMD_L
	mov [BX+2], DX
	mov [BX+4], DS 
	mov DX, offset CL_POS
	
	mov AX, 4b00h 
	int 21h 
	
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	pop ES
	pop DS
	
	jnc _loadS
	
_fn_err:
	cmp AX, 1
	jne _file_err
	mov DX, offset FN_ERR
	call PRINT
	jmp _loadE
_file_err:
	cmp AX, 2
	jne _disk_err
	mov DX, offset FILE_ERR
	call PRINT
	jmp _loadE
_disk_err:
	cmp AX, 5
	jne _mem_err
	mov DX, offset DISK_ERR
	call PRINT
	jmp _loadE
_mem_err:
	cmp AX, 8
	jne _envs_err
	mov DX, offset MEM_ERR
	call PRINT
	jmp _loadE
_envs_err:
	cmp AX, 10
	jne _format_err
	mov DX, offset ENVS_ERR
	call PRINT
	jmp _loadE
_format_err:
	cmp AX, 11
	mov DX, offset FORMAT_ERR
	call PRINT
	jmp _loadE

_loadS:
	mov AH, 4dh
	mov AL, 00h
	int 21h 
	
_Nend:
	cmp AH, 0
	jne _ctrlc
	push DI 
	mov DI, offset NORMAL_END
	mov [DI+26], AL 
	pop SI
	mov DX, offset NORMAL_END
	call PRINT 
	jmp _loadE
_ctrlc:
	cmp AH, 1
	jne _device
	mov DX, offset CTRL_END 
	call PRINT 
	jmp _loadE
_device:
	cmp AH, 2 
	jne _31h
	mov DX, offset DEVICE_ERR
	call PRINT 
	jmp _loadE
_31h:
	cmp AH, 3
	mov DX, offset INT_END
	call PRINT 

_loadE:
	pop DX
	pop CX
	pop BX
	pop AX
	ret
LOAD ENDP

PATH PROC 
	push AX
	push BX
	push CX 
	push DX
	push DI
	push SI
	push ES
	
	mov AX, KEEP_PSP
	mov ES, AX
	mov ES, ES:[2ch]
	mov BX, 0
	
FINDZ:
	inc BX
	cmp byte ptr ES:[BX-1], 0
	jne FINDZ

	cmp byte ptr ES:[BX+1], 0 
	jne FINDZ
	
	add BX, 2
	mov DI, 0
	
_loop:
	mov DL, ES:[BX]
	mov byte ptr [CL_POS+DI], DL
	inc DI
	inc BX
	cmp DL, 0
	je _end_loop
	cmp DL, '\'
	jne _loop
	mov CX, DI
	jmp _loop
_end_loop:
	mov DI, CX
	mov SI, 0
	
_fn:
	mov DL, byte ptr [PROGRAM+SI]
	mov byte ptr [CL_POS+DI], DL
	inc DI 
	inc SI
	cmp DL, 0 
	jne _fn
		
	
	pop ES
	pop SI
	pop DI
	pop DX
	pop CX
	pop BX
	pop AX
	ret
PATH ENDP

MAIN PROC FAR
	push DS
	xor AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	mov KEEP_PSP, ES
	call MEM_FREE 
	cmp MEM_FLAG, 0
	je _end
	call PATH
	call LOAD
_end:
	xor AL, AL
	mov AH, 4ch
	int 21h
	
MAIN      ENDP

_endC:
CODE ENDS
END MAIN
