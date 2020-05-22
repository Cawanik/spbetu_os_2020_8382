AStack	SEGMENT  STACK
			DW 100h DUP(?)   
AStack	ENDS

DATA SEGMENT
typePC db  'Type: PC',0DH,0ah,'$'
typeXT db  'Type: PC/XT',0DH,0ah,'$'
typeAT db  'Type: AT',0DH,0ah,'$'
typePS2_30 db  'Type: PS2 model 30',0DH,0ah,'$'
typePS2_80 db  'Type: PS2 model 80',0DH,0ah,'$'
typePCJR db  'Type: PCjr',0DH,0ah,'$'
typePCConv db  'Type: PC Convertible',0DH,0ah,'$'
Endl db '       ', 0DH,0ah,'$'
Version db  'Version:  .  ',0DH,0ah,'$'
Version2 db  'Version <2.0',0DH,0ah,'$'
OEM db  'OEM: ',0DH,0ah,'$'
UserNumber db 'User: ', 0ah, '      ', 0DH,0ah,'$'

DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack
   
   	
PrintEndl PROC near
	push ax
	mov dx, offset Endl
	mov ah, 09h
	int 21h
	pop ax
PrintEndl ENDP
		
		
TetrToHex PROC near
	and al,0Fh
	cmp al,09
		jbe next
	add al,07
next:
	add al,30h
	ret
TetrToHex ENDP


ByteToHex PROC near
	push cx
	mov ah,al
	call TetrToHex
	xchg al,ah
	mov cl,4
	shr al,cl
	call TetrToHex
	pop cx
	ret
ByteToHex ENDP


WrdToHex PROC near
	push bx
	mov bh,ah
	call ByteToHex
	mov [di],ah
	dec di
	mov [di],al
	dec di
	mov al,bh
	call ByteToHex
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
WrdToHex ENDP


ByteToDec PROC near
	push cx
	push dx
	xor ah,ah
	xor dx,dx
	mov cx,10
bd:
	div cx
	or dl,30h
	mov [si],dl
	dec si
	xor dx,dx
	cmp ax,10
		jae bd
	cmp al,00h
		je Endbd
	or al,30h
	mov [si],al
Endbd:
	pop dx
	pop cx
	ret
ByteToDec ENDP	

  ;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ 
   
Main PROC FAR
	mov ax, DATA
	mov ds, ax
   
	mov ax,0F000H
	mov es,ax 
	mov al,es:[0FFFEH] 
	
	cmp al, 0FFH
		je tPC
	cmp al, 0FEH
		je tPC_XT
	cmp al, 0Fbh
		je tPC_XT	
	cmp al, 0FCH
		je tAT	
	cmp al, 0Fah
		je tPS2_30	
	cmp al, 0F8H
		je tPS2_80	
	cmp al, 0FDH
		je tPCjr	
	cmp al, 0F9H
		je tPCconv
		

tPC:
	mov dx, offset typePC
	jmp writeType
		
tPC_XT:
	mov dx, offset typeXT
	jmp writeType

tAT:
	mov dx, offset typeAT
	jmp writeType
		
tPS2_30:
	mov dx, offset typePS2_30
	jmp writeType
		
tPS2_80:
	mov dx, offset typePS2_80
	jmp writeType
	
tPCjr:
	mov dx, offset typePCJR
	jmp writeType

tPCconv:
	mov dx, offset typePCConv
	jmp writeType
		
writeType:
	mov ah, 09h
	int 21h
	jmp OSvertion


;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

OSvertion:
	mov ah, 30h
	int 21h
	push cx
	push bx
		
printVer:
	mov ah,30h
	int 21h
	push ax
	cmp al, 0
		je ver2
	mov si,offset Version
	add si,9
	call ByteToDec
   	pop ax
   	mov al,ah
   	add si,3
	call ByteToDec
	mov dx,offset Version
	mov ah,09h
	int 21h
	jmp OEMnumber
	
ver2:
	mov dx,offset Version2
	mov ah,09h
	int 21h
	pop ax
	jmp OEMnumber	
		
OEMnumber:
	mov si,offset OEM
	add si,5
	mov al,bh
	call ByteToDec
	mov dx,offset OEM
	mov ah,09h
	int 21h
	jmp User
		
User:

	mov di,offset UserNumber
	add di,11
	mov ax,cx
	call WrdToHex
	mov al,bl
	call ByteToHex
	sub di,2
	mov [di],ax
	mov dx,offset UserNumber
	mov ah,09h
	int 21h
	
ext:
	xor al, al
	mov ah, 4Ch
	int 21h


;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\


Main ENDP
CODE ENDS
      END Main 