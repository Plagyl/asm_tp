section .data
    newline db 10
    newline_len equ 1

section .bss
    buffer resb 1024    ; Buffer pour la chaîne d'entrée
    reversed resb 1024  ; Buffer pour la chaîne inversée

section .text
    global _start

_start:
    ; Lire l'entrée standard
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, buffer     ; destination
    mov rdx, 1024       ; taille max
    syscall
    
    ; Vérifier si la lecture a réussi
    test rax, rax
    jl exit_error       ; Seulement si erreur de lecture (-1)
    
    ; Si longueur 0, c'est une chaîne vide mais valide
    cmp rax, 0
    je empty_string
    
    ; Stocker la longueur du texte lu
    mov r12, rax
    
    ; Vérifier si le dernier caractère est un saut de ligne
    dec r12             ; Se positionner sur le dernier caractère
    cmp byte [buffer + r12], 10
    jne no_newline
    
    ; Si c'est un saut de ligne, on l'ignore pour l'inversion
    ; mais on le garde pour l'affichage
    dec r12
    
no_newline:
    ; La longueur effective de la chaîne à inverser
    mov r13, r12
    inc r13             ; +1 car l'index commence à 0
    
    ; Inverser la chaîne
    xor rcx, rcx        ; rcx = index dans la chaîne inversée
    
reverse_loop:
    ; Vérifier si on a terminé
    cmp r12, -1
    je print_result
    
    ; Récupérer le caractère de la fin
    movzx rax, byte [buffer + r12]
    
    ; Le mettre au début de la chaîne inversée
    mov [reversed + rcx], al
    
    ; Passer au caractère suivant
    dec r12
    inc rcx
    jmp reverse_loop
    
empty_string:
    ; Cas spécial: chaîne vide
    xor rcx, rcx        ; Longueur zéro
    
print_result:
    ; Ajouter un terminateur nul à la chaîne inversée
    mov byte [reversed + rcx], 0
    
    ; Afficher la chaîne inversée
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, reversed   ; source
    mov rdx, rcx        ; longueur
    syscall
    
    ; Afficher une nouvelle ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall
    
exit_success:
    ; Sortir avec code de retour 0
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; code 0
    syscall
    
exit_error:
    ; Sortir avec code de retour 1
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; code 1
    syscall
