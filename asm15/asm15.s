section .data
    usage_msg db "Usage: ./asm15 <filename>", 10
    usage_len equ $ - usage_msg
    
    open_error_msg db "Error: Cannot open file", 10
    open_error_len equ $ - open_error_msg
    
    read_error_msg db "Error: Cannot read file", 10
    read_error_len equ $ - read_error_msg

    ; Magic number et valeurs à vérifier pour un binaire ELF x64
    elf_magic db 0x7F, "ELF"       ; Magic number ELF (4 octets)

section .bss
    file_header resb 16    ; Pour stocker les premiers octets du fichier

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
    
    ; Ouvrir le fichier en lecture
    mov rax, 2      ; sys_open
    mov rsi, 0      ; O_RDONLY
    mov rdx, 0      ; Mode (non utilisé pour O_RDONLY)
    syscall
    
    ; Vérifier si l'ouverture a réussi
    cmp rax, 0
    jl open_error   ; Échec si rax < 0
    
    ; Sauvegarder le descripteur de fichier
    mov r8, rax
    
    ; Lire les premiers octets du fichier (l'en-tête ELF)
    mov rax, 0      ; sys_read
    mov rdi, r8     ; descripteur de fichier
    mov rsi, file_header ; destination
    mov rdx, 16     ; lire 16 octets
    syscall
    
    ; Vérifier si la lecture a réussi
    cmp rax, 16     ; Vérifier qu'on a lu au moins 16 octets
    jl read_error
    
    ; Fermer le fichier
    mov rax, 3      ; sys_close
    mov rdi, r8
    syscall
    
    ; Vérifier le magic number ELF
    mov rsi, file_header
    mov rdi, elf_magic
    mov rcx, 4      ; Comparer 4 octets
    repe cmpsb      ; Comparer les chaînes d'octets
    jne not_elf     ; Si différents, ce n'est pas un ELF
    
    ; Vérifier le type de fichier (EI_CLASS, 5ème octet) pour x64
    cmp byte [file_header + 4], 2  ; 2 = ELFCLASS64
    jne not_elf
    
    ; Vérifier l'endianness (EI_DATA, 6ème octet)
    cmp byte [file_header + 5], 1  ; 1 = ELFDATA2LSB (little-endian)
    jne not_elf
    
    ; Vérifier la version (EI_VERSION, 7ème octet)
    cmp byte [file_header + 6], 1  ; 1 = EV_CURRENT
    jne not_elf
    
    ; C'est un binaire ELF x64
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; code 0 (c'est un ELF x64)
    syscall
    
not_elf:
    ; Ce n'est pas un binaire ELF x64
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; code 1 (ce n'est pas un ELF x64)
    syscall
    
usage_error:
    ; Afficher message d'usage
    mov rax, 1      ; sys_write
    mov rdi, 2      ; stderr
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    
    ; Sortir avec code d'erreur
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; code 1
    syscall
    
open_error:
    ; Afficher message d'erreur d'ouverture
    mov rax, 1      ; sys_write
    mov rdi, 2      ; stderr
    mov rsi, open_error_msg
    mov rdx, open_error_len
    syscall
    
    ; Sortir avec code d'erreur
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; code 1
    syscall
    
read_error:
    ; Fermer le fichier
    mov r9, rax     ; Sauvegarder le résultat de la lecture
    mov rax, 3      ; sys_close
    mov rdi, r8
    syscall
    
    ; Afficher message d'erreur de lecture
    mov rax, 1      ; sys_write
    mov rdi, 2      ; stderr
    mov rsi, read_error_msg
    mov rdx, read_error_len
    syscall
    
    ; Sortir avec code d'erreur
    mov rax, 60     ; sys_exit
    mov rdi, 1      ; code 1
    syscall
