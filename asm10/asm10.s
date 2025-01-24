section .data
    usage db "Usage: ./asm10 num1 num2 num3", 10
    usage_len equ $ - usage
    newline db 10
    newline_len equ 1

section .bss
    buffer resb 32  ; Buffer pour les nombres

section .text
    global _start

_start:
    ; Vérifier le nombre d'arguments
    pop rdi         ; Récupérer argc
    cmp rdi, 4
    jne error

    ; Sauter le nom du programme
    pop rsi

    ; Premier nombre comme maximum initial
    pop rsi
    call atoi
    mov r8, rax     ; r8 = max actuel

    ; Comparer avec le deuxième nombre
    pop rsi
    call atoi
    cmp rax, r8
    jle check_third
    mov r8, rax

check_third:
    ; Comparer avec le troisième nombre
    pop rsi
    call atoi
    cmp rax, r8
    jle print_result
    mov r8, rax

print_result:
    ; Convertir le nombre maximum (r8) en chaîne
    mov rax, r8
    mov rdi, buffer
    call itoa
    
    ; Calculer la longueur de la chaîne en fonction du résultat de itoa
    mov rdx, rax    ; rax contient la longueur de la chaîne
    
    ; Afficher le résultat
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, buffer
    syscall
    
    ; Afficher un retour à la ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall

exit:
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; code de retour 0
    syscall

error:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, usage
    mov rdx, usage_len
    syscall

    mov rax, 60     ; sys_exit
    mov rdi, 1      ; code de retour 1
    syscall

; Fonction atoi améliorée pour les nombres négatifs
atoi:
    xor rax, rax        ; Initialiser le résultat
    push rbx            ; Sauvegarder rbx
    xor rbx, rbx        ; rbx = 0 (positif) ou 1 (négatif)
    
    ; Vérifier le signe
    cmp byte [rsi], '-'
    jne .loop
    inc rsi             ; Sauter le signe moins
    mov rbx, 1          ; Marquer comme négatif

.loop:
    movzx rcx, byte [rsi]
    test rcx, rcx
    jz .done
    cmp rcx, '0'
    jl .done
    cmp rcx, '9'
    jg .done
    sub rcx, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .loop

.done:
    ; Si négatif, négation du résultat
    test rbx, rbx
    jz .exit
    neg rax

.exit:
    pop rbx
    ret

; Fonction itoa améliorée pour les nombres négatifs
itoa:
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rbx, rdi        ; Sauvegarder le pointeur original du buffer
    
    ; Vérifier si le nombre est négatif
    test rax, rax
    jns .positive
    
    ; Si négatif, écrire le signe moins et négation
    mov byte [rdi], '-'
    inc rdi
    neg rax
    
.positive:
    mov r9, 10          ; Diviseur = 10
    xor rcx, rcx        ; Compteur de chiffres = 0
    
    ; Cas spécial pour 0
    test rax, rax
    jnz .convert
    mov byte [rdi], '0'
    inc rdi
    jmp .finish
    
.convert:
    ; Convertir chaque chiffre
    xor rdx, rdx        ; Préparer pour div
    div r9              ; rax = quotient, rdx = reste
    add dl, '0'         ; Convertir en ASCII
    push rdx            ; Sauvegarder le chiffre
    inc rcx             ; Incrémenter le compteur
    test rax, rax       ; Tester si on a fini
    jnz .convert
    
    ; Récupérer les chiffres dans l'ordre inverse
.reverse:
    pop rdx
    mov [rdi], dl       ; Stocker le chiffre
    inc rdi             ; Avancer dans le buffer
    dec rcx             ; Décrémenter le compteur
    jnz .reverse
    
.finish:
    ; Ajouter le terminateur nul
    mov byte [rdi], 0
    
    ; Calculer la longueur (rdi - rbx)
    sub rdi, rbx
    mov rax, rdi        ; Retourner la longueur en octets
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
