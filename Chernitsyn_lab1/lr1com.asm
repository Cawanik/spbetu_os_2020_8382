TESTPC SEGMENT
        ASSUME cs:TESTPC, ds:TESTPC, es:NOTHING, ss:NOTHING
        ORG 100H
START: jmp BEGIN
;DATA
FF_type 	db 'PC',10,13,'$'
FE_FB_type 	db 'PC/XT',10,13,'$'
FA_type 	db 'PS2 ver. 30',10,13,'$'
FC_type 	db 'PS2 ver. 50/60 or AT',10,13,'$'
F8_type 	db 'PS2 ver. 80',10,13,'$'
FD_type 	db 'PCjr',10,13,'$'
F9_type 	db 'PC Convertible',10,13,'$'
typePC 		db 'Your IBM PC type is ','$'
typeMSDOS 	db 'Your MSDOS type is ','$'
old_ver		db '<2.0',10,13,'$'
new_ver 	db '0x.0y',10,13,'$'
serialOEM 	db 'Your serial OEM number is ','$'
serialUser 	db 10,13,'Your serial user number is ','$'
ErrorMsg	db 'ERROR!',10,13,'$'
;-----------------------------------------------------
WriteMsg PROC near 
        mov ah,09h
        int 21h
        ret
WriteMsg ENDP
;-----------------------------------------------------
TETR_TO_HEX PROC near
        and al,0Fh
        cmp al,09
        jbe NEXT
        add al,07
NEXT:   add al,30h ; код нуля
        ret
TETR_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_HEX PROC near
;байт в al переводится в два символа в шест. сс ax 
        push cx
        mov ah,al
        call TETR_TO_HEX
        xchg al,ah
        mov cl,4
        shr al,cl
        call TETR_TO_HEX ;al - старшая 
        pop cx ;ah - младшая цифра
        ret
BYTE_TO_HEX ENDP
;-----------------------------------------------------
WRD_TO_HEX PROC near
; перевод в 16сс 16ти разрядного числа
; ax - число, di - адрес последнего символа 
        push bx
        mov bh,ah
        call BYTE_TO_HEX
        mov [di],ah
        dec di
        mov [di],al
        dec di
        mov al,bh
        call BYTE_TO_HEX
        mov [di],ah
        dec di
        mov [di],al
        pop bx
        ret
WRD_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_DEC PROC near
; перевод байта в 10сс, si - адрес поля младшей цифры
; al содержит исходный байт
        push cx
        push dx
        xor ah,ah
        xor dx,dx
        mov cx,10
loop_bd: div cx
        or dl,30h
        mov [si],dl
        dec si
        xor dx,dx
        cmp ax,10
        jae loop_bd
        cmp al,00h
        je end_l
        or al,30h
        mov [si],al
end_l:  pop dx
        pop cx
        ret
BYTE_TO_DEC ENDP
;-----------------------------------------------------
WRITE_AL_HEX PROC NEAR
        push ax
        push dx
        call BYTE_TO_HEX

        mov dl, al
        mov al, ah
        mov ah, 02h
        int 21h

        mov dl, al
        int 21h
        pop dx
        pop ax
        ret
WRITE_AL_HEX ENDP
;-----------------------------------------------------
BEGIN:
		mov ax, 0F000h
		mov es, ax
		mov al, es:[0FFFEh]
		
		mov dx, offset typePC
		call WriteMsg
		
		mov dx, offset FF_type
		cmp al, 0FFh
		je WRITE_TYPE
		
		mov dx, offset FE_FB_type
		cmp al, 0FEh
		je WRITE_TYPE
		cmp al, 0FBh
		je WRITE_TYPE
		
		mov dx, offset FC_type
		cmp al, 0FCh
		je WRITE_TYPE
		
		mov dx, offset FA_type
		cmp al, 0FAh
		je WRITE_TYPE
		
		mov dx, offset F8_type
		cmp al, 0F8h
		je WRITE_TYPE
		
		mov dx, offset FD_type
		cmp al, 0FDh
		je WRITE_TYPE
		
		mov dx, offset F9_type
		cmp al, 0F9h
		je WRITE_TYPE
		
		mov dx, offset ErrorMsg
		
WRITE_TYPE:
		call WriteMsg
		
		mov dx, offset typeMSDOS
		call WriteMsg
		
		mov ah, 30h
		int 21h
		
		cmp al, 0
		jne SKIP_1
		mov dx, offset old_ver
		call WriteMsg
		
SKIP_1:
		mov si, offset new_ver
		add si, 1
		call BYTE_TO_DEC
		add si, 4
		mov al, ah
		call BYTE_TO_DEC
		mov dx, offset new_ver
		call WriteMsg
		
		mov ah, 30h
		int 21h
		
		mov dx, offset serialOEM
		call WriteMsg
		mov al, bh
		call WRITE_AL_HEX
		
		mov ah, 30h
		int 21h

		mov dx, offset serialUser
		call WriteMsg
		mov al, bl
		call WRITE_AL_HEX
		mov al, ch
		call WRITE_AL_HEX
		mov al, cl
		call WRITE_AL_HEX
		
		xor al,al
		mov AH,4Ch
		int 21h
TESTPC ENDS
		END START;