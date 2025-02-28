section .bss
    buffer resb 1024    ; Buffer pour la chaîne d'entrée

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
    jl not_palindrome   ; Erreur de lecture
    
    ; Si longueur 0 ou 1, c'est un palindrome
    cmp rax, 1
    jle is_palindrome
    
    ; Stocker la longueur dans r12
    mov r12, rax
    
    ; Vérifier si le dernier caractère est un saut de ligne
    dec r12
    cmp byte [buffer + r12], 10
    jne start_check
    
    ; Ignorer le saut de ligne final s'il existe
    dec r12
    
    ; Si après avoir ignoré le saut de ligne, la longueur est 0 ou 1, c'est un palindrome
    cmp r12, 0
    jle is_palindrome
    
start_check:
    ; r13 = pointeur vers le début de la chaîne
    xor r13, r13
    
    ; r14 = pointeur vers la fin de la chaîne
    mov r14, r12
    
compare_loop:
    ; Si les pointeurs se croisent, c'est un palindrome
    cmp r13, r14
    jge is_palindrome
    
    ; Récupérer le caractère au début
get_valid_start:
    movzx rax, byte [buffer + r13]
    
    ; Vérifier si c'est une lettre ou un chiffre
    call is_alphanumeric
    test rax, rax
    jnz valid_start_char
    
    ; Pas un caractère alphanumérique, avancer au suivant
    inc r13
    
    ; Vérifier si on a dépassé la fin
    cmp r13, r14
    jg is_palindrome    ; Si oui, tout est valide
    jmp get_valid_start
    
valid_start_char:
    ; Sauvegarder le caractère de début
    mov r15, rax
    
    ; Récupérer le caractère à la fin
get_valid_end:
    movzx rax, byte [buffer + r14]
    
    ; Vérifier si c'est une lettre ou un chiffre
    call is_alphanumeric
    test rax, rax
    jnz valid_end_char
    
    ; Pas un caractère alphanumérique, reculer
    dec r14
    
    ; Vérifier si on a dépassé le début
    cmp r14, r13
    jl is_palindrome    ; Si oui, tout est valide
    jmp get_valid_end
    
valid_end_char:
    ; Comparer avec le caractère de début
    cmp r15, rax
    jne not_palindrome  ; Si différents, pas un palindrome
    
    ; Caractères identiques, continuer
    inc r13
    dec r14
    jmp compare_loop
    
is_palindrome:
    ; Sortir avec code de retour 0 (c'est un palindrome)
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; code 0
    syscall
    
not_palindrome:
    ; Sortir avec code de retour 1 (ce n'est pas un palindrome)
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; code 1
    syscall

; Fonction pour vérifier si un caractère est alphanumérique et le convertir en minuscule
; Entrée: RAX = caractère ASCII
; Sortie: RAX = 0 si non alphanumérique, sinon caractère en minuscule
is_alphanumeric:
    ; Vérifier si c'est un chiffre (0-9)
    cmp rax, '0'
    jl .not_alnum
    cmp rax, '9'
    jle .is_alnum     ; C'est un chiffre, on le garde tel quel
    
    ; Vérifier si c'est une lettre majuscule (A-Z)
    cmp rax, 'A'
    jl .not_alnum
    cmp rax, 'Z'
    jle .to_lower     ; C'est une majuscule, on la convertit
    
    ; Vérifier si c'est une lettre minuscule (a-z)
    cmp rax, 'a'
    jl .not_alnum
    cmp rax, 'z'
    jle .is_alnum     ; C'est une minuscule, on la garde
    
.not_alnum:
    xor rax, rax      ; Pas alphanumérique, retourner 0
    ret
    
.to_lower:
    add rax, 32       ; Convertir majuscule en minuscule
    
.is_alnum:
    ret
