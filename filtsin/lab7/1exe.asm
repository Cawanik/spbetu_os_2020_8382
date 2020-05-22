.model small

.stack 100h

.data
  error_dealloc db 'Dealloc error: 00000h', 13, 10, '$'
  error_file db 'File error: 00000h', 13, 10, '$'
  error_alloc db 'Alloc error: 00000h', 13, 10, '$'
  error_run db 'Run error: 00000h', 13, 10, '$'
  program_path db 100 dup(?)
  dta db 43 dup(0)
  ovl_seg dw 0
  ovl_addr dd 0

.code

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

call_ovl proc near
  push es
  mov si, 02ch
  mov es, es:[si]

  mov si, 0

  out_print:
    mov dl, es:[si]
    cmp dl, 0
    je finish_1
  while_print:
    mov dl, es:[si] 
    inc si
    inc bp
    cmp dl, 0
    je out_print
    jmp while_print
  finish_1:  

  add si, 3
  mov bp, offset program_path

  print_for:
    mov dl, es:[si]
    mov ds:[bp], dl
    cmp dl, 0
    je finish_print
    inc si
    inc bp
    jmp print_for  
  finish_print:

  sub bp, 8
  mov ds:[bp], byte ptr 'o'
  mov ds:[bp + 1], byte ptr 'v'
  mov ds:[bp + 2], ax
  mov ds:[bp + 3], byte ptr '.'
  mov ds:[bp + 4], byte ptr 'o'
  mov ds:[bp + 5], byte ptr 'v'
  mov ds:[bp + 6], byte ptr 'l'
  mov ds:[bp + 7], byte ptr 0

  mov dx, offset program_path
  xor cx, cx
  mov ah, 04eh
  int 21h
  jnc good_file

  mov di, offset error_file
  add di, 16
  call wrd_to_hex

  mov dx, offset error_file
  mov ah, 09h
  int 21h
  jmp finish

  good_file:

  mov bx, offset dta
  mov ax, [bx + 01ch]
  mov bx, [bx + 01ah]

  mov cl, 4
  shr bx, cl
  mov cl, 12
  shl ax, cl

  add bx, ax
  inc bx

  mov ah, 048h
  int 21h
  jnc good_alloc

  mov di, offset error_alloc
  add di, 17
  call wrd_to_hex

  mov dx, offset error_alloc
  mov ah, 09h
  int 21h
  jmp finish

  good_alloc:
  mov ovl_seg, ax
  mov ax, @data
  mov es, ax
  mov bx, offset ovl_seg
  mov dx, offset program_path
  mov ax, 04b03h
  int 21h
  jnc good_run

  mov di, offset error_run
  add di, 15
  call wrd_to_hex

  mov dx, offset error_run
  mov ah, 09h
  int 21h
  jmp finish

  good_run:
  mov ax, ovl_seg
  mov word ptr ovl_addr + 2, ax
  push ds
  call ovl_addr
  pop ds
  mov ax, ovl_seg
  mov es, ax
  mov ah, 049h
  int 21h

  finish:
    pop es
    ret
call_ovl endp

main:
  mov ax, @data
  mov ds, ax

  mov dx, offset dta
  mov ah, 01ah
  int 21h


  mov bx, offset last_byte

  mov ah, 04ah
  int 21h
  jnc good_dealloc

  mov di, offset error_dealloc
  add di, 17
  call wrd_to_hex

  mov dx, offset error_dealloc
  mov ah, 09h
  int 21h
  jmp finish_prog

  good_dealloc:
  mov ax, '1'
  call call_ovl
  mov ax, '2'
  call call_ovl

  finish_prog:
  mov ah, 04ch
  int 21h

last_byte:
end main