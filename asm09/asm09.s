section .data
    usage_msg db "Usage: ./asm09 [-b] <number>", 0x0A
    usage_len equ $ - usage_msg
    invalid_msg db "Invalid number", 0x0A
    invalid_len equ $ - invalid_msg
    newline db 0x0A
    newline_len equ $ - newline
    zero_char db "0"

section .bss
    buffer resb 65  ; Buffer pour la conversion

section .text
    global _start

_start:
    ; Gestion des arguments
    pop rcx         ; Nombre d'arguments
    cmp rcx, 2
    jl usage_error
    cmp rcx, 3
    jg usage_error

    pop rsi         ; Ignorer le nom du programme
    pop rsi         ; Premier argument

    ; Vérifier l'option -b
    mov rdx, 0      ; Flag binaire (0=hex)
    mov rdi, rsi
    call check_binary_option
    cmp rax, 1
    jne convert_number
    mov rdx, 1      ; Mode binaire activé
    dec rcx         ; Vérifier s'il reste un argument
    jz usage_error
    pop rsi         ; Récupérer le vrai nombre

convert_number:
    call atoi
    cmp rax, -1
    je invalid_number

    ; Sauvegarde du nombre à convertir
    mov rbx, rax

    ; Préparation du buffer
    mov rdi, buffer
    mov rcx, 64
    mov al, 0
    rep stosb       ; Remplir le buffer de zéros
    
    ; Cas spécial: zéro
    test rbx, rbx
    jnz normal_conversion
    
    ; Traitement spécial pour zéro
    mov rsi, zero_char
    mov rdx, 1
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall
    jmp print_newline
    
normal_conversion:
    ; Conversion selon le mode
    test rdx, rdx
    jnz convert_to_binary

convert_to_hex:
    mov rdi, buffer
    mov rax, rbx
    mov rcx, 16
    call do_conversion
    jmp print_result

convert_to_binary:
    mov rdi, buffer
    mov rax, rbx
    mov rcx, 2
    call do_conversion

print_result:
    ; Chercher le début des chiffres significatifs (ignorer les zéros en tête)
    mov rsi, buffer
.find_nonzero:
    cmp byte [rsi], '0'
    jne .found_nonzero
    cmp byte [rsi], 0
    je .found_nonzero  ; Si on atteint la fin, ne pas avancer le pointeur
    inc rsi
    jmp .find_nonzero

.found_nonzero:
    ; Calculer la longueur de la chaîne
    mov rdi, rsi
    call strlen
    mov rdx, rax    ; Longueur
    
    ; Afficher le résultat
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall

print_newline:
    ; Ajouter un saut de ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall

    ; Exit propre
    mov rax, 60
    xor rdi, rdi
    syscall

; Fonction de conversion
; Entrée: 
;   RAX = nombre à convertir
;   RCX = base (2 ou 16)
;   RDI = buffer pour le résultat
; Sortie:
;   Le buffer contient la représentation du nombre
do_conversion:
    push rbx
    push rdx
    push rdi
    
    ; Pointer vers la fin du buffer
    mov rbx, rdi
    add rbx, 63    ; Garder un octet pour le terminateur
    mov byte [rbx], 0
    
.convert_loop:
    test rax, rax
    jz .done
    
    ; Diviser RAX par la base
    xor rdx, rdx
    div rcx
    
    ; Convertir le reste en caractère
    cmp rdx, 10
    jl .digit
    add rdx, 'A' - 10 - '0'
.digit:
    add rdx, '0'
    
    ; Stocker le caractère
    dec rbx
    mov [rbx], dl
    jmp .convert_loop
    
.done:
    ; Copier le résultat au début du buffer
    mov rax, rbx
    pop rdi
    push rdi
    
.copy_loop:
    cmp byte [rax], 0
    je .end_copy
    mov dl, [rax]
    mov [rdi], dl
    inc rax
    inc rdi
    jmp .copy_loop
    
.end_copy:
    mov byte [rdi], 0
    
    pop rdi
    pop rdx
    pop rbx
    ret

check_binary_option:
    cmp byte [rdi], '-'
    jne .no
    inc rdi
    cmp byte [rdi], 'b'
    jne .no
    inc rdi
    cmp byte [rdi], 0
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

atoi:
    xor rax, rax
    xor rcx, rcx
.loop:
    movzx r8, byte [rsi + rcx]
    test r8, r8
    jz .done
    cmp r8, '0'
    jb .error
    cmp r8, '9'
    ja .error
    sub r8, '0'
    imul rax, 10
    add rax, r8
    inc rcx
    jmp .loop
.done:
    ret
.error:
    mov rax, -1
    ret

strlen:
    xor rax, rax
.loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

usage_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    mov rdi, 1
    jmp exit

invalid_number:
    mov rax, 1
    mov rdi, 1
    mov rsi, invalid_msg
    mov rdx, invalid_len
    syscall
    mov rdi, 1

exit:
    mov rax, 60
    syscall
