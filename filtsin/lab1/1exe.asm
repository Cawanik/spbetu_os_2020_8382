.model small
.stack 100h

.data
pc_t db 'PC', 13, 10, '$'
pcxt_t db 'PC/XT', 13, 10, '$'
at_t db 'AT', 13, 10, '$'
ps2_30_t db 'PS2 model 30', 13, 10, '$'
ps2_50_t db 'PS2 model 50 or 60', 13, 10, '$'
ps2_80_t db 'PS2 model 80', 13, 10, '$'
pcjr_t db 'PCjr', 13, 10, '$'
pcconv_t db 'PC Convertible', 13, 10, '$'
another_t db 'Another ', '$'
count_types dw 9
type_array db 0ffh 
           db 0feh
           db 0fbh 
           db 0fch 
           db 0fah 
           db 0fch
           db 0f8h
           db 0fdh 
           db 0f9h
offset_array dw offset pc_t
             dw offset pcxt_t
             dw offset pcxt_t
             dw offset at_t
             dw offset ps2_30_t
             dw offset ps2_50_t
             dw offset ps2_80_t
             dw offset pcjr_t
             dw offset pcconv_t

os_ver_title db 'Version: ', '$'
os_ver db '00.00', 13, 10, '$'             
oem_title db 'OEM: ', '$'
oem_value db '  ', 13, 10, '$'
serial_title db 'Serial number: ', '$'
serial_value db '000', 13, 10, '$'

.code
jmp begin
tetr_to_hex proc near
  and al, 0fh
  cmp al, 09
  jbe next
  add al, 07
  next:
    add al, 30h
    ret
tetr_to_hex endp

byte_to_hex proc near
  push cx
  mov ah, al
  call tetr_to_hex
  xchg al, ah
  mov cl, 4
  shr al, cl
  call tetr_to_hex
  pop cx
  ret
byte_to_hex endp

wrd_to_hex proc near
  push bx
  mov bh, ah
  call byte_to_hex
  mov [di], ah
  dec di
  mov [di], al
  dec di
  mov al, bh
  call byte_to_hex
  mov [di], ah
  dec di
  mov [di], al
  pop bx
  ret
wrd_to_hex endp

byte_to_dec proc near
  push cx
  push dx
  xor ah, ah
  xor dx, dx
  mov cx, 10
  loop_bd:
    div cx
    or dl, 30h
    mov [si], dl
    dec si
    xor dx, dx
    cmp ax, 10
    jae loop_bd
    cmp al, 00h
    je end_l
    or al, 30h
    mov [si], al
  end_l:
    pop dx
    pop cx
    ret  
byte_to_dec endp


begin:
  mov ax, @data
  mov ds, ax
  
  mov ax, 0f000h
	mov es, ax 
	mov al, es:[0fffeh] 
  
  mov cx, count_types
  dec cx
  mov si, offset type_array 
  find_type:
    mov bx, cx
    mov bl, ds:[si + bx]
    cmp bl, al
    je result_type
    loop find_type
  fail_type:
    ; Ничего не нашли
    mov dx, offset another_t
    mov ah, 09h
    int 21h
    mov al, cl
    call byte_to_hex
    mov dx, ax
    mov ah, 02h
    int 21h
    jmp finish_type
  result_type:
    ; В cx индекс с нужным типом
    mov ax, cx
    mov si, offset offset_array
    mov bx, cx
    add bx, bx ; dw - 2 байта! а bx * 2 ниже не работает
    mov dx, ds:[si + bx]
    mov ah, 09h
    int 21h
  finish_type:

  ; Печать версии
  mov dx, offset os_ver_title
  mov ah, 09h
  int 21h

  mov ah, 30h
  int 21h
  
  mov si, offset os_ver
  inc si
  push ax
  call byte_to_dec
  pop ax

  xchg ah, al
  
  mov si, offset os_ver
  add si, 3
  call byte_to_dec

  mov dx, offset os_ver
  mov ah, 09h
  int 21h

  ; Печать серийника OEM
  mov dx, offset oem_title
  mov ah, 09h
  int 21h

  mov al, bh
  mov si, offset oem_value
  call byte_to_dec
  mov dx, offset oem_value
  mov ah, 09h
  int 21h
  ; Печать серийника пользователя
  mov dx, offset serial_title
  int 21h

  mov al, bl
  mov si, offset serial_value
  call byte_to_dec
  
  mov al, ch
  mov si, offset serial_value
  inc si
  call byte_to_dec

  mov al, cl
  mov si, offset serial_value
  add si, 2
  call byte_to_dec

  mov dx, offset serial_value
  mov ah, 09h
  int 21h

  xor al, al
  mov ah, 4ch
  int 21h
end
