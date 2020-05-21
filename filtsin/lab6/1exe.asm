.model small

.stack 100h

.data

error_string db 'Error: 00000h', 13, 10, '$'

segm dw 0
seg_offset_cmd dd 0
seg_offset_fcbf dd 0
seg_offset_fcbs dd 0
program_path db 100 dup(0)

keep_ss dw 0
keep_sp dw 0
keep_ds dw 0

reason_code db 'Reason: 00000h', 13, 10, '$'
return_code db 'Return: 00000h', 13, 10, '$'

lb db 'Offset: 0000', 13, 10, '$'

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

print_error_code proc near
  push di
  push dx

  mov di, offset error_string
  add di, 11
  call wrd_to_hex

  mov dx, offset error_string
  mov ah, 09h
  int 21h

  pop dx
  pop di
  ret
print_error_code endp

main:
  mov ax, @data
  mov ds, ax

  mov bx, offset last_byte
  mov ah, 04ah
  int 21h
  jnc run_prog

  call print_error_code
  jmp finish

  run_prog:
  mov bp, offset seg_offset_cmd
  mov [bp], es
  mov ah, 080h
  mov [bp + 2], ah

  mov bp, offset seg_offset_fcbf
  mov [bp], es
  mov ah, 05ch
  mov [bp + 2], ah
  
  mov bp, offset seg_offset_fcbs
  mov [bp], es
  mov ah, 06ch
  mov [bp + 2], ah

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
  mov ds:[bp], byte ptr '1'
  mov ds:[bp + 1], byte ptr 'c'
  mov ds:[bp + 2], byte ptr 'o'
  mov ds:[bp + 3], byte ptr 'm'
  mov ds:[bp + 4], byte ptr '.'
  mov ds:[bp + 5], byte ptr 'c'
  mov ds:[bp + 6], byte ptr 'o'
  mov ds:[bp + 7], byte ptr 'm'

  mov dx, offset program_path

  mov keep_ss, ss
  mov keep_sp, sp
  mov keep_ds, ds

  mov ax, ds
  mov es, ax
  mov bx, offset segm

  mov ax, 04b00h
  int 21h

  mov ss, keep_ss
  mov sp, keep_sp
  mov ds, keep_ds

  jnc good_run

  call print_error_code
  jmp finish 

  good_run:

  mov ah, 04dh
  int 21h

  push ax
  xor al, al
  xchg ah, al
  mov di, offset reason_code
  add di, 12
  call wrd_to_hex

  pop ax
  xor ah, ah
  mov di, offset return_code
  add di, 12
  call wrd_to_hex
  
  mov dx, offset reason_code
  mov ah, 09h
  int 21h

  mov dx, offset return_code
  mov ah, 09h
  int 21h

  finish:
  mov ah, 04ch
  int 21h

last_byte:

end main