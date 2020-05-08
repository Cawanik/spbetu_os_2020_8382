testpc segment
       assume CS:testpc, ds:testpc, es:nothing, ss:nothing
       org 100h
start: jmp begin

memory_label db 'Memory(B): ', '$'
memory_value db '000000', 13, 10, '$'

expanded_memory_label db 'Expanded memory(KB): ', '$'
expanded_memory_value db '000000', 13, 10, '$'

mcb_start db 'MCB type = ', '$'
mcb_owner db ' | Owner = ', '$'
mcb_owner_value db '00000', '$'
mcb_size db ' | Size(B) = ', '$'
mcb_size_value db '00000', '$'
mcb_last db " | Last bytes = ", '$'
rn db 13, 10, '$'

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

wrd_to_dec proc near
  push bx
  mov bx, 10
  in_loop:
    div bx
    add dl, 030h
    mov [si], dl
    xor dx, dx
    dec si
    cmp ax, 0
    jne in_loop
  pop bx
  ret
wrd_to_dec endp 

begin:
  mov dx, offset memory_label
  mov ah, 09h
  int 21h

  mov ah, 04ah
  mov bx, 0ffffh
  int 21h

  mov ax, 16
  mul bx

  mov si, offset memory_value
  add si, 5

  call wrd_to_dec

  mov dx, offset memory_value
  mov ah, 09h
  int 21h

  mov dx, offset expanded_memory_label
  int 21h

  mov al, 030h
  out 070h, al
  in al, 071h
  mov bl, al
  mov al, 031h
  out 070h, al
  in al, 071h

  mov si, offset expanded_memory_value
  add si, 5

  mov ah, al
  mov al, bl
  mov dx, 0
  call wrd_to_dec

  mov dx, offset expanded_memory_value
  mov ah, 09h
  int 21h


  mov ah, 052h
  int 21h

  mov es, es:[bx - 2]

  mcb_print:
    mov dx, offset mcb_start
    mov ah, 09h
    int 21h

    mov al, es:[0h]
    call byte_to_hex
    mov cx, ax
    mov dl, cl
    mov ah, 02h
    int 21h
    mov dl, ch
    int 21h

    mov dx, offset mcb_owner
    mov ah, 09h
    int 21h

    mov ax, es:[01h]
    mov di, offset mcb_owner_value
    add di, 3
    call wrd_to_hex

    mov dx, offset mcb_owner_value
    mov ah, 09h
    int 21h
    
    mov dx, offset mcb_size
    mov ah, 09h
    int 21h

    mov ax, es:[03h]
    mov bx, 16
    mul bx
    mov si, offset mcb_size_value
    add si, 5
    call wrd_to_dec
    mov dx, offset mcb_size_value
    mov ah, 09h
    int 21h

    mov si, 08h
    mov cx, 8
    mov ah, 02h

    last_print:
      mov dl, es:[si]
      int 21h
      inc si
      loop last_print

    mov dx, offset rn
    mov ah, 09h
    int 21h

    mov al, es:[0h]
    cmp al, 05ah
    je finish

    mov ax, es
    add ax, es:[03h]
    inc ax
    mov es, ax
    jmp mcb_print

  finish:
    xor al, al
    mov ah, 4ch
    int 21h

testpc ends
       end start  
