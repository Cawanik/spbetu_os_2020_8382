TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN

IBMT db 'IBM PC TYPE IS: ', '$'
BR db 0dh, 0ah, '$'
PC db 'PC', '$'
PCXT db 'PC/XT', '$'
;AT db 'AT', '$'
PS230 db 'PS2 model 30', '$'
PS250 db 'PS2 model 50 or 60 or AT', '$'
PS280 db 'PS2 model 80', '$'
PSJR db 'PSjr', '$'
PSC db 'PS Conventible', '$'

VHEADER db 'Version:', '$'
LT2S db '< 2.0', '$'
VNUMBER db '      ', '$'
OEMHEADER db 'OEM:', '$'
OEMNUMBER db '   ', '$'
SHEADER db 'Serial number:', '$'
SNUMBER db '         ', '$'

IBMPS dw 7 dup(0) ; 7 types, easy index access


TETR_TO_HEX PROC near 
and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
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

BYTE_TO_DEC PROC near

 push CX
 push DX
 xor AH,AH
 xor DX,DX
 mov CX,10
loop_bd: div CX
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
end_l: pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP

BEGIN:
PCMODEL:
 mov CX, 0

 mov DX, offset PS280
 mov [IBMPS + BX], DX
 add BX, 2

 mov DX, offset PSC
 mov [IBMPS + BX], DX
 add BX, 2

 mov DX, offset PS230
 mov [IBMPS + BX], DX
 add BX, 2

 mov DX, offset PCXT
 mov [IBMPS + BX], DX
 add BX, 2

 mov DX, offset PS250
 mov [IBMPS + BX], DX
 add BX, 2
 
 mov DX, offset PSJR
 mov [IBMPS + BX], DX
 add BX, 2
 
 mov DX, offset PCXT
 mov [IBMPS + BX], DX
 add BX, 2

 mov DX, offset PC
 mov [IBMPS + BX], DX
 mov BX, 0

 mov DX, offset IBMT
 mov AH, 09h
 int 21h
 mov AX, 0F000h
 mov ES, AX
 mov AL, ES:[0FFFEh]
 mov AH, 0
 sub AL, 0f8h
 shl AL, 1
 mov BX, AX


 mov DX, [IBMPS + BX]
 mov AH,09h
 int 21h
 mov dx, offset br
 int 21h

VERSION:
 mov DX, offset VHEADER
 int 21h
 mov AH, 30h
 int 21h

 cmp al, 0
 je LT2
 mov si, offset VNUMBER
 push si
 add si, 1
 push ax
 call BYTE_TO_DEC
 pop ax
 pop si
 push si
 add si, 2
 mov byte ptr [si], 2eh
 pop si
 add si, 3
 xchg al, ah
 call BYTE_TO_DEC
 mov ah, 09h
 mov dx, offset VNUMBER
 int 21h
 mov dx, offset br
 int 21h
 jmp OEM

LT2:
 mov DX, offset LT2S
 mov AH, 09h
 int 21h
 mov dx, offset br
 int 21h

OEM:
 mov dx, offset OEMHEADER
 int 21h
 mov al, bh
 mov si, offset OEMNUMBER
 add si, 2
 call BYTE_TO_DEC
 mov ah, 09h
 mov dx, offset OEMNUMBER
 int 21h
 mov dx, offset br
 int 21h

SERIAL:
 mov dx, offset SHEADER
 int 21h
 mov si, offset SNUMBER
 add si, 7
 mov ax, cx
 call BYTE_TO_DEC
 dec si
 mov al, bl
 call BYTE_TO_DEC
 mov dx, offset SNUMBER
 mov ah, 09h
 int 21h
 mov dx, offset br
 int 21h

 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START 
