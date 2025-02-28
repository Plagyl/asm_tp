section .data
    hello_msg db "Hello Universe!"    ; Message à écrire
    hello_len equ $ - hello_msg       ; Longueur du message
    
    usage_msg db "Usage: ./asm14 <filename>", 10  ; Message d'usage
    usage_len equ $ - usage_msg               ; Longueur du message d'usage
    
    error_msg db "Error: cannot open file", 10  ; Message d'erreur
    error_len equ $ - error_msg               ; Longueur du message d'erreur

section .text
    global _start

_start:
    ; Vérifier si un argument a été fourni
    pop rcx         ; Nombre d'arguments
    cmp rcx, 2      ; Il nous faut exactement 2 arguments (nom du programme + nom du fichier)
    jne usage_error
    
    ; Ignorer le nom du programme
    pop rdi
    
    ; Récupérer le nom du fichier
    pop rdi         ; rdi = nom du fichier
    
    ; Ouvrir/créer le fichier
    mov rax, 2      ; sys_open
    mov rsi, 0x241  ; O_WRONLY | O_CREAT | O_TRUNC (0x41 = O_WRONLY | O_CREAT, 0x200 = O_TRUNC)
    mov rdx, 0o666  ; Permissions pour le fichier (lecture/écriture)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    cmp rax, 0
    jl file_error   ; Échec si rax < 0
    
    ; Sauvegarder le descripteur de fichier
    mov r8, rax     ; Sauvegarder le descripteur dans r8
    
    ; Écrire le message dans le fichier
    mov rax, 1      ; sys_write
    mov rdi, r8     ; Descripteur de fichier
    mov rsi, hello_msg  ; Message à écrire
    mov rdx, hello_len  ; Longueur du message
    syscall
    
    ; Fermer le fichier
    mov rax, 3      ; sys_close
    mov rdi, r8     ; Descripteur de fichier
    syscall
    
    ; Sortie normale
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; Code 0 (succès)
    syscall
    
usage_error:
    ; Afficher le message d'usage
    mov rax, 1      ; sys_write
    mov rdi, 2      ; stderr
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    
    ; Sortie avec erreur
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; Code 1 (erreur)
    syscall
    
file_error:
    ; Afficher le message d'erreur
    mov rax, 1      ; sys_write
    mov rdi, 2      ; stderr
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    
    ; Sortie avec erreur
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; Code 1 (erreur)
    syscall
