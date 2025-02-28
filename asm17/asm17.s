section .bss
    buffer resb 1024

section .data
    error_msg db "Usage: ./asm17 <shift>", 10
    error_len equ $ - error_msg
    invalid_msg db "Error: Invalid shift parameter (must be a number)", 10
    invalid_len equ $ - invalid_msg

section .text
    global _start

_start:
    ; Vérifier les arguments
    pop rdi             ; nombre d'arguments
    cmp rdi, 2
    jne error
    
    pop rdi             ; ignore argv[0]
    pop rdi             ; prend argv[1] - le décalage
    
    ; Déboguer l'argument de décalage
    mov r8, rdi         ; Sauvegarder le pointeur d'argument
    
    ; Convertir le décalage en nombre avec support pour les négatifs et nombres à plusieurs chiffres
    call atoi
    cmp rax, -1
    je invalid_arg
    
    ; Garder le décalage dans r9
    mov r9, rax

read_input:
    ; Lire depuis stdin
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, buffer     ; buffer
    mov rdx, 1024       ; taille max
    syscall
    
    ; Si EOF ou erreur
    cmp rax, 0
    jle exit_success
    
    ; Garder la longueur lue
    mov r12, rax        ; sauvegarder la longueur
    
    ; Traiter chaque caractère
    mov rcx, rax        ; compteur pour la boucle
    mov rsi, buffer     ; pointeur sur le buffer

cipher_loop:
    movzx rax, byte [rsi]  ; charger le caractère
    
    ; Vérifier si c'est une lettre
    mov r10b, al        ; sauvegarder le caractère original
    
    ; Vérifier si majuscule
    cmp al, 'A'
    jl not_a_letter
    cmp al, 'Z'
    jle upper_case
    
    ; Vérifier si minuscule
    cmp al, 'a'
    jl not_a_letter
    cmp al, 'z'
    jg not_a_letter
    
    ; Traiter minuscule
    sub al, 'a'         ; convertir en 0-25
    jmp apply_shift

upper_case:
    sub al, 'A'         ; convertir en 0-25

apply_shift:
    ; Ajouter le décalage (peut être négatif)
    movsx rax, al       ; étendre le signe pour permettre des valeurs négatives
    add rax, r9
    
    ; Gérer les débordements (modulo 26)
.normalize:
    cmp rax, 0
    jl .add_26
    cmp rax, 26
    jl .finish_normalize
    sub rax, 26
    jmp .normalize
    
.add_26:
    add rax, 26
    jmp .normalize
    
.finish_normalize:
    ; Maintenant rax contient la position normalisée (0-25)
    
    ; Reconvertir en lettre
    cmp r10b, 'a'       ; vérifier si c'était une minuscule
    jge lowercase
    add al, 'A'         ; majuscule
    jmp save_char
    
lowercase:
    add al, 'a'         ; minuscule
    jmp save_char
    
not_a_letter:
    ; Si ce n'est pas une lettre, laisser tel quel
    mov al, r10b

save_char:
    mov [rsi], al       ; sauvegarder le résultat

next_char:
    inc rsi
    loop cipher_loop
    
    ; Écrire le résultat
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, buffer     ; buffer
    mov rdx, r12        ; longueur
    syscall
    
    jmp read_input

invalid_arg:
    ; Si l'argument est "-1", le traiter comme cas spécial
    cmp byte [r8], '-'
    jne .regular_invalid
    cmp byte [r8+1], '1'
    jne .regular_invalid
    cmp byte [r8+2], 0
    jne .regular_invalid
    
    ; C'est bien "-1", donc fixer r9 à -1 et continuer
    mov r9, -1
    jmp read_input
    
.regular_invalid:
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, invalid_msg
    mov rdx, invalid_len
    syscall
    mov rdi, 1
    jmp exit

error:
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, error_msg  ; message
    mov rdx, error_len  ; longueur
    syscall
    mov rdi, 1
    jmp exit

exit_success:
    xor rdi, rdi        ; return 0

exit:
    mov rax, 60         ; sys_exit
    syscall

; Fonction atoi : Convertit une chaîne en entier
; Entrée: RDI = adresse de la chaîne
; Sortie: RAX = valeur numérique, -1 si erreur
atoi:
    push rbx            ; Sauvegarder rbx
    push rcx            ; Sauvegarder rcx
    push rdx            ; Sauvegarder rdx
    
    mov rax, 0          ; Initialiser le résultat
    mov rcx, 0          ; Initialiser l'indice
    mov rdx, 0          ; Flag pour le signe (0 = positif, 1 = négatif)
    
    ; Vérifier si le premier caractère est un signe
    movzx rbx, byte [rdi]
    cmp rbx, '-'
    jne .check_plus
    mov rdx, 1          ; Nombre négatif
    inc rcx             ; Avancer l'indice
    jmp .start_convert
    
.check_plus:
    cmp rbx, '+'
    jne .start_convert
    inc rcx             ; Avancer l'indice
    
.start_convert:
    ; Si pas de chiffres après le signe, c'est une erreur
    movzx rbx, byte [rdi + rcx]
    test rbx, rbx       ; Fin de chaîne?
    jz .error
    
    ; Convertir chaque caractère
.convert_loop:
    movzx rbx, byte [rdi + rcx]
    test rbx, rbx       ; Si fin de chaîne (0)
    jz .done
    
    cmp rbx, '0'        ; Vérifier si c'est un chiffre
    jl .error
    cmp rbx, '9'
    jg .error
    
    ; Multiplier le résultat par 10 et ajouter le nouveau chiffre
    imul rax, 10
    sub rbx, '0'        ; Convertir ASCII en valeur numérique
    add rax, rbx
    
    inc rcx
    jmp .convert_loop
    
.done:
    ; Appliquer le signe si nécessaire
    test rdx, rdx
    jz .positive
    neg rax
    
.positive:
    pop rdx
    pop rcx
    pop rbx
    ret
    
.error:
    mov rax, -1
    pop rdx
    pop rcx
    pop rbx
    ret
