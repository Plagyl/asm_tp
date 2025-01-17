section .data
    newline db 0xA  ; Caractère de nouvelle ligne

section .text
    global _start

_start:
    ; Récupérer le nombre d'arguments (argc)
    mov rdi, [rsp]            ; rdi = argc
    cmp rdi, 2
    je  get_argument
    ; Si argc != 2, afficher un message d'erreur
    jmp no_argument

get_argument:
    ; Récupérer le deuxième argument (argv[1])
    mov rsi, [rsp + 16]       ; rsi = argv[1]

    ; Calculer la longueur de la chaîne
    xor rcx, rcx              ; rcx = 0 (compteur)
find_length:
    cmp byte [rsi + rcx], 0   ; Comparer chaque caractère avec '\0'
    je  display_message       ; Si '\0', passer à l'affichage
    inc rcx                   ; Incrémenter le compteur
    jmp find_length           ; Répéter pour le caractère suivant

display_message:
    ; Appel système pour afficher argv[1]
    mov rax, 1                ; syscall numéro 1 : write
    mov rdi, 1                ; stdout
    mov rdx, rcx              ; rdx = longueur de la chaîne
    syscall

    ; Ajouter un saut de ligne
    mov rax, 1                ; syscall numéro 1 : write
    mov rdi, 1                ; stdout
    lea rsi, [newline]        ; Adresse du saut de ligne
    mov rdx, 1                ; Longueur = 1
    syscall

    ; Quitter le programme avec succès
    mov rax, 60               ; syscall numéro 60 : exit
    xor rdi, rdi              ; Code de retour 0
    syscall

no_argument:
    ; Afficher un message d'erreur si aucun argument n'est fourni
    mov rax, 1                ; syscall numéro 1 : write
    mov rdi, 1                ; stdout
    lea rsi, [msg_no_arg]     ; Adresse du message d'erreur
    mov rdx, len_no_arg       ; Longueur du message d'erreur
    syscall

    ; Quitter le programme avec une erreur
    mov rax, 60               ; syscall numéro 60 : exit
    mov rdi, 1                ; Code de retour 1
    syscall

section .data
    msg_no_arg db 'Erreur : aucun argument fourni.', 0xA
    len_no_arg equ $ - msg_no_arg

