section .data
    error_msg db "Usage: echo <number> | ./asm07", 10
    error_msg_len equ $ - error_msg

    ; 📌 Tableau des 100 premiers nombres premiers
    primes dq 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71
           dq 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173
           dq 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281
           dq 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409
           dq 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541
    primes_count equ ($ - primes) / 8  ; Nombre d’éléments dans le tableau

section .bss
    input_buffer resb 20
    number resq 1

section .text
    global _start

_start:
    ; Lire l'entrée standard (stdin)
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 20
    syscall

    ; Vérifier si une entrée a été lue
    cmp rax, 1
    jle .invalid_input

    ; Vérifier si l'entrée est juste un "\n"
    cmp byte [input_buffer], 10
    je .invalid_input

    ; Convertir l'entrée en entier
    mov rsi, input_buffer
    call atoi
    cmp rax, -1
    je .invalid_input

    mov [number], rax

    ; Vérifier si le nombre est premier
    call is_prime

    ; Terminer le programme avec le résultat
    mov rax, 60
    mov rdi, rbx
    syscall

.invalid_input:
    mov rax, 60
    mov rdi, 2
    syscall

; Fonction pour vérifier si un nombre est premier
is_prime:
    mov rax, [number]      ; Charger n
    cmp rax, 2             ; Si n < 2 → pas premier
    jl .not_prime

    mov rsi, primes        ; Charger l'adresse du tableau de nombres premiers
    mov rcx, primes_count  ; Nombre d’éléments dans le tableau

.loop:
    mov rdx, [rsi]         ; Charger le nombre premier actuel
    cmp rdx, rax           ; Comparer avec n
    je .prime              ; Si égal, alors n est premier
    add rsi, 8             ; Passer au nombre suivant
    loop .loop             ; Répéter jusqu'à la fin du tableau

.not_prime:
    mov rbx, 1             ; Retourner 1 (pas premier)
    ret

.prime:
    mov rbx, 0             ; Retourner 0 (premier)
    ret

; Fonction pour convertir une chaîne en entier (atoi)
atoi:
    xor rax, rax
    xor rcx, rcx
    xor r8, r8

    cmp byte [rsi], 0
    je .invalid

.next_char:
    movzx r8, byte [rsi + rcx]
    cmp r8, '0'
    jb .check_end
    cmp r8, '9'
    ja .invalid
    sub r8, '0'
    imul rax, 10
    add rax, r8
    inc rcx
    jmp .next_char

.check_end:
    cmp r8, 0
    je .done
    cmp r8, 10
    je .done

.invalid:
    mov rax, -1
    ret

.done:
    ret

