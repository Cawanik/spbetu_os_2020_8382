DATA SEGMENT
	FILE1 db "FILE1.OVL", 0
	FILE2 db "FILE2.OVL", 0
	PROGRAM dw 0	
	DTA_MEM db 43 dup(0)
	MEM_FLAG db 0
	CL_POS db 128 dup(0)
	OVLS_ADDR dd 0
	KEEP_PSP dw 0

	EOF db 0DH, 0AH, '$'
	MCB_CRASH_ERR db 'ERR: MCB crashed', 0DH, 0AH, '$' 
	NO_MEM_ERR db 'ERR: there is not enough memory to execute this function', 0DH, 0AH, '$' 
	ADDR_ERR db 'ERR: invalid memory address', 0DH, 0AH, '$'
	FREE db 'memory has been freed' , 0DH, 0AH, '$'
	
	FN_ERR db 'ERR: function doesnt exist', 0DH, 0AH, '$' 
	FILE_ERR db 'ERR: file not found(load err)', 0DH, 0AH, '$' 
	ROUTE_ERR db 'ERR: route not found(load err)', 0DH, 0AH, '$' 
	FILES_ERR db 'ERR: you opened too many files', 0DH, 0AH, '$'
	ACCESS_ERR db 'ERR: no access', 0DH, 0AH, '$' 
	MEM_ERR db 'ERR: insufficient memory', 0DH, 0AH, '$' 
	ENVS_ERR db 'ERR: wrong string of environment ', 0DH, 0AH, '$' 	
	NORMAL_END db  'Load was successful' , 0DH, 0AH, '$'
	ALLOCATION_END db  'Allocation was successful' , 0DH, 0AH, '$'
	ALL_FILE_ERR db  'ERR: file not found(allocation err)' , 0DH, 0AH, '$'
	ALL_ROUTE_ERR db  'ERR: route not found(allocation err)' , 0DH, 0AH, '$'

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
	
	mov AX, DATA
	mov ES, AX
	mov BX, offset OVLS_ADDR
	mov DX, offset CL_POS
	mov AX, 4b03h
	int 21h 
	
	jnc _loadS
	
_fn_err:
	cmp AX, 1
	jne _file_err
	mov DX, offset EOF
	call PRINT
	mov DX, offset FN_ERR
	call PRINT
	jmp _loadE
_file_err:
	cmp AX, 2
	jne _route_err
	mov DX, offset FILE_ERR
	call PRINT
	jmp _loadE
_route_err:
	cmp AX, 3
	jne _fileS_err
	mov DX, offset EOF
	call PRINT
	mov DX, offset ROUTE_ERR
	call PRINT
	jmp _loadE
_fileS_err:
	cmp AX, 4
	jne _access_err
	mov DX, offset FILES_ERR
	call PRINT
	jmp _loadE
_access_err:
	cmp AX, 5
	jne _mem_err
	mov DX, offset ACCESS_ERR
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
	mov DX, offset ENVS_ERR
	call PRINT
	jmp _loadE

_loadS:
	mov DX, offset NORMAL_END
	call PRINT
	
	mov AX, WORD PTR OVLS_ADDR
	mov ES, AX
	mov WORD PTR OVLS_ADDR, 0
	mov WORD PTR OVLS_ADDR+2, AX

	call OVLS_ADDR
	mov ES, AX
	mov AH, 49h
	int 21h

_loadE:
	pop ES
	pop DS
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
	
	mov PROGRAM, DX

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
	mov SI, PROGRAM
	
_fn:
	mov DL, byte ptr [SI]
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

ALLOCATION PROC
	push AX
	push BX
	push CX
	push DX

	push DX 
	mov DX, offset DTA_MEM
	mov AH, 1Ah
	int 21h
	pop DX 
	mov CX, 0
	mov AH, 4Eh
	int 21h

	jnc _all_success

_all_file_err:
	cmp AX, 2
	je _all_route_err
	mov DX, offset ALL_FILE_ERR
	call PRINT
	jmp _all_end
_all_route_err:
	cmp AX, 3
	mov DX, offset ALL_ROUTE_ERR
	call PRINT
	jmp _all_end

_all_success:
	push DI
	mov DI, offset DTA_MEM
	mov BX, [DI+1Ah] 
	mov AX, [DI+1Ch]
	pop DI
	push CX
	mov CL, 4
	shr BX, Cl
	mov CL, 12
	shl AX, CL
	pop CX
	add BX, AX
	add BX, 1
	mov AH, 48h
	int 21h
	mov WORD PTR OVLS_ADDR, AX
	mov DX, offset ALLOCATION_END
	call PRINT

_all_end:
	pop DX
	pop CX
	pop BX
	pop AX
	ret
ALLOCATION ENDP

OVL_START PROC
	push DX
	call PATH
	mov DX, offset CL_POS
	call ALLOCATION
	call LOAD
	pop DX
	ret
OVL_START ENDP

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

	mov DX, offset FILE1
	call OVL_START
	mov dx, offset EOF
	call PRINT
	mov DX, offset FILE2
	call OVL_START

_end:
	xor AL, AL
	mov AH, 4ch
	int 21h
	
MAIN      ENDP

_endC:
CODE ENDS
END MAIN
