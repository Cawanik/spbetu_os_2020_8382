overlay segment
   assume cs:overlay, ds:overlay
   start: jmp main
   msg_address db "has address:     ", 13, 10, "$"

main proc far
   push ax
   push ds
   push di
   mov ax, cs
   mov ds, ax
   mov di, offset msg_address
   push di
   add di, 10h
   call WRD_TO_HEX
   pop di
   call print
   pop di
   pop ds
   pop ax
   retf
main endp

print proc near
   ; prints di content
   push dx
   push ax
   mov ah, 9h
   mov dx, di
   int 21h
   pop ax
   pop dx
   ret
print endp

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP

overlay ends
end start 