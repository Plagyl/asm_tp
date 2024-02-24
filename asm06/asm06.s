section .data
    newline db 10
    error_msg db "Usage: ./asm06 <num1> <num2>", 10
    error_msg_len equ $ - error_msg

section .bss
    num1 resq 1
    num2 resq 1
    result resb 20

section .text
    global _start

_start:
    ; Vérifier le nombre d'arguments
    cmp qword [rsp], 3
    jne .error

    ; Récupérer et convertir le premier argument
    mov rsi, [rsp + 16]
    call atoi
    cmp rax, -1       ; Vérifier si la conversion a échoué
    je .error
    mov [num1], rax

    ; Récupérer et convertir le deuxième argument
    mov rsi, [rsp + 24]
    call atoi
    cmp rax, -1       ; Vérifier si la conversion a échoué
    je .error
    mov [num2], rax

    ; Additionner les nombres
    mov rax, [num1]
    add rax, [num2]

    ; Convertir et afficher le résultat
    mov rdi, result
    call itoa
    
    ; Calculer la longueur de la chaîne
    mov rsi, result
    call strlen

    ; Afficher le résultat
    mov rax, 1
    mov rdi, 1
    mov rsi, result
    mov rdx, rdx
    syscall

    ; Afficher un saut de ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Sortie propre
    mov rax, 60
    xor rdi, rdi
    syscall

.error:
    ; Gestion d'erreur
    mov rax, 1
    mov rdi, 1
    mov rsi, error_msg
    mov rdx, error_msg_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

; Conversion chaîne -> entier (avec gestion du signe et des erreurs)
atoi:
    xor rax, rax          ; Initialiser rax (résultat)
    xor rcx, rcx          ; Initialiser rcx (indicateur de signe)
    movzx r8, byte [rsi]  ; Lire le premier caractère

    ; Gérer les nombres négatifs
    cmp r8, '-'
    jne .loop
    inc rsi
    mov rcx, 1            ; Indiquer que le nombre est négatif

.loop:
    movzx r8, byte [rsi]  ; Charger le caractère actuel
    test r8, r8           ; Vérifier la fin de chaîne
    jz .end

    ; Vérifier si le caractère est un chiffre (0-9)
    cmp r8, '0'
    jl .error
    cmp r8, '9'
    jg .error

    sub r8, '0'           ; Convertir le caractère en chiffre
    imul rax, rax, 10     ; Multiplier rax par 10
    add rax, r8           ; Ajouter le chiffre converti
    inc rsi               ; Passer au caractère suivant
    jmp .loop

.end:
    test rcx, rcx         ; Vérifier si le nombre est négatif
    jz .positive
    neg rax
.positive:
    ret

.error:
    mov rax, -1           ; Retourner une erreur (-1)
    ret

; Conversion entier -> chaîne (avec gestion du signe)
itoa:
    mov rbx, rdi
    add rbx, 19
    mov byte [rbx], 0
    dec rbx

    mov rcx, 10
    xor r9, r9
    test rax, rax
    jns .digits
    neg rax
    mov r9, 1

.digits:
    xor rdx, rdx
    div rcx
    add dl, '0'
    mov [rbx], dl
    dec rbx
    test rax, rax
    jnz .digits

    test r9, r9
    jz .copy
    mov byte [rbx], '-'
    dec rbx

.copy:
    mov rsi, rbx
    inc rsi
    mov rdi, result
.loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .loop
    ret

; 🏷️ **Calcul de la longueur de chaîne**
strlen:
    xor rdx, rdx
.loop:
    cmp byte [rsi + rdx], 0
    je .done
    inc rdx
    jmp .loop
.done:
    ret

