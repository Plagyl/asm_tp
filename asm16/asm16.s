section .data
    old_string db "1337", 0
    new_string db "H4CK", 0
    str_len equ 4
    error_open db "Error: Cannot open file", 10, 0
    error_read db "Error: Cannot read file", 10, 0
    error_write db "Error: Cannot write to file", 10, 0
    len_error_open equ $ - error_open
    len_error_read equ $ - error_read
    len_error_write equ $ - error_write

section .bss
    buffer resb 1024        ; Réduit la taille du buffer

section .text
    global _start

_start:
    ; Vérifier les arguments
    pop rdi                 ; nombre d'arguments
    cmp rdi, 2
    jne exit_error
    
    pop rdi                 ; ignore argv[0]
    pop rdi                 ; prend argv[1] - nom du fichier

    ; Ouvrir le fichier en lecture/écriture
    mov rax, 2             ; sys_open
    mov rsi, 2             ; O_RDWR
    mov rdx, 0644o         ; permissions
    syscall
    
    cmp rax, 0
    jl open_error
    
    mov r8, rax            ; Sauvegarder le fd

search_loop:
    ; Lire 4 octets
    mov rax, 0             ; sys_read
    mov rdi, r8            ; fd
    mov rsi, buffer        ; buffer
    mov rdx, str_len       ; lire 4 octets
    syscall
    
    ; Vérifier si on a lu assez
    cmp rax, str_len
    jne read_error
    
    ; Comparer avec "1337"
    mov rsi, buffer
    mov rdi, old_string
    mov rcx, str_len
    repe cmpsb
    je found_string
    
    ; Si pas trouvé, reculer de 3 octets et continuer
    mov rax, 8             ; sys_lseek
    mov rdi, r8            ; fd
    mov rsi, -3            ; reculer de 3
    mov rdx, 1             ; SEEK_CUR
    syscall
    
    jmp search_loop

found_string:
    ; Reculer de 4 octets pour écrire
    mov rax, 8             ; sys_lseek
    mov rdi, r8            ; fd
    mov rsi, -4            ; reculer de 4
    mov rdx, 1             ; SEEK_CUR
    syscall
    
    ; Écrire "H4CK"
    mov rax, 1             ; sys_write
    mov rdi, r8            ; fd
    mov rsi, new_string    ; "H4CK"
    mov rdx, str_len       ; 4 octets
    syscall
    
    cmp rax, str_len
    jne write_error
    
    ; Fermer le fichier
    mov rax, 3             ; sys_close
    mov rdi, r8
    syscall
    
    xor rdi, rdi           ; return 0
    jmp exit

open_error:
    mov rax, 1             ; sys_write
    mov rdi, 1             ; stdout
    mov rsi, error_open    ; message
    mov rdx, len_error_open
    syscall
    jmp exit_error

read_error:
    mov rax, 1             ; sys_write
    mov rdi, 1             ; stdout
    mov rsi, error_read    ; message
    mov rdx, len_error_read
    syscall
    jmp exit_error

write_error:
    mov rax, 1             ; sys_write
    mov rdi, 1             ; stdout
    mov rsi, error_write   ; message
    mov rdx, len_error_write
    syscall

exit_error:
    mov rdi, 1             ; return 1

exit:
    mov rax, 60            ; sys_exit
    syscall

