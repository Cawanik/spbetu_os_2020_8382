code segment
assume cs:code, es:nothing, ds:nothing, ss:nothing

main proc far
  push ax
  push dx
  push ds
  push di

  mov ax, cs
  mov ds, ax

  mov di, offset seg_label
  add di, 18
  call wrd_to_hex

  mov dx, offset seg_label
  mov ah, 09h
  int 21h

  pop di
  pop ds
  pop dx
  pop ax
  retf
main endp

seg_label db 'Segment (#2): 00000h', 13, 10, '$'

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

code ends
end main
