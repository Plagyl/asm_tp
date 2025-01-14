section .data
  msg db "1337", 0x0A
  len equ $ - msg
  buffer db 0, 0, 0

section .text
  global _start

_start:
mov rax, 0 ; syscall de read
mov rdi, 0 ; dit que c'est stdin
mov rsi, buffer ; adresse du tampon
mov rdx, 3 ; registre taille max des données donc 2 + \n
syscall

;pour comparer l'entrée
mov al, [buffer] ; al est le low de rax car ASCII sur 8bits et buffer tableau 
cmp al, '4' ;simple compare buffer0 avec 4
jne not_equal ;jump vers fonction not_equal si pas egal

mov al, [buffer+1]
cmp al, '2'     ;compare le 2
jne not_equal

mov al, [buffer+2] ;
cmp al, 0x0A ; compare avec \n 
jne not_equal

mov rax, 1 ;write
mov rdi, 1 ;stdout
mov rsi, msg ;adresse message
mov rdx, len
syscall

mov rax, 60 ; exit
xor rdi, rdi ;return 0
syscall

not_equal: ;si different retourne 1
mov rax, 60
mov rdi, 1
syscall

