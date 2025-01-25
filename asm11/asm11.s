section .data
    vowels db "aeiouAEIOU", 0   ; Liste des voyelles à compter
    newline db 10
    newline_len equ 1

section .bss
    buffer resb 1024    ; Buffer pour l'entrée
    result resb 16      ; Buffer pour afficher le résultat

section .text
    global _start

_start:
    ; Récupérer les arguments
    pop r13                 ; Nombre d'arguments
    mov r14, 0              ; Par défaut, pas d'argument de vérification
    
    cmp r13, 2              ; Vérifier s'il y a un argument (+ nom du programme)
    jl .read_input          ; Si non, passer à la lecture de l'entrée
    
    ; Récupérer les arguments
    pop r15                 ; Ignorer le nom du programme
    pop r14                 ; Récupérer l'argument
    
.read_input:
    ; Lire l'entrée de stdin
    mov rax, 0              ; sys_read
    mov rdi, 0              ; stdin
    mov rsi, buffer         ; destination
    mov rdx, 1024           ; taille max
    syscall
    
    ; Vérifier si rien n'a été lu
    test rax, rax
    jle .empty_input
    
    ; Stocker la taille de l'entrée
    mov r12, rax
    
    ; Initialiser le compteur de voyelles
    xor r8, r8              ; r8 = compteur de voyelles
    
    ; Parcourir chaque caractère de l'entrée
    xor r9, r9              ; r9 = index dans le buffer
    
.count_loop:
    ; Vérifier si on a atteint la fin
    cmp r9, r12
    jge .print_result
    
    ; Récupérer le caractère actuel
    movzx r10, byte [buffer + r9]
    
    ; Vérifier si le caractère est une voyelle
    mov rdi, r10            ; Caractère à vérifier
    call is_vowel
    
    ; Si c'est une voyelle, incrémenter le compteur
    test rax, rax
    jz .not_vowel
    inc r8
    
.not_vowel:
    ; Passer au caractère suivant
    inc r9
    jmp .count_loop
    
.empty_input:
    ; Pour entrée vide, le compteur est zéro mais on retourne une erreur
    xor r8, r8
    
    ; Afficher 0 mais le code de sortie sera 1
    mov rax, r8
    mov rdi, result
    call itoa
    mov r9, rax            ; Longueur de la chaîne
    
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; source
    mov rdx, r9             ; longueur
    syscall
    
    ; Afficher une nouvelle ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall
    
    jmp .exit_error         ; Sortir avec erreur pour entrée vide
    
.print_result:
    ; Convertir le nombre de voyelles en chaîne
    mov rax, r8
    mov rdi, result
    call itoa
    mov r9, rax            ; Longueur de la chaîne
    
    ; Afficher le résultat
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, result         ; source
    mov rdx, r9             ; longueur
    syscall
    
    ; Afficher une nouvelle ligne
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall
    
    ; Vérifier si on doit comparer avec un argument
    test r14, r14
    jz .exit_success        ; Si pas d'argument, sortir avec succès
    
    ; Convertir l'argument en nombre
    mov rdi, r14
    call atoi               ; Convertir en nombre
    
    ; Comparer avec le compteur de voyelles
    cmp rax, r8
    jne .exit_error         ; Si différent, sortir avec erreur
    
.exit_success:
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; code 0
    syscall
    
.exit_error:
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; code 1
    syscall

; Fonction is_vowel
; Entrée: RDI = caractère à vérifier
; Sortie: RAX = 1 si voyelle, 0 sinon
is_vowel:
    push rbx            ; Sauvegarder rbx
    push rcx            ; Sauvegarder rcx
    
    ; Parcourir la liste des voyelles
    xor rcx, rcx
    
.loop:
    movzx rbx, byte [vowels + rcx]
    test rbx, rbx       ; Vérifier si on est à la fin
    jz .not_vowel
    
    cmp rdi, rbx        ; Comparer avec la voyelle courante
    je .vowel
    
    inc rcx
    jmp .loop
    
.vowel:
    mov rax, 1          ; C'est une voyelle
    jmp .exit
    
.not_vowel:
    xor rax, rax        ; Ce n'est pas une voyelle
    
.exit:
    pop rcx
    pop rbx
    ret

; Fonction atoi
; Entrée: RDI = pointeur vers la chaîne
; Sortie: RAX = nombre converti
atoi:
    push r12            ; Sauvegarder r12
    push r13            ; Sauvegarder r13
    xor rax, rax        ; Initialiser à 0
    xor r12, r12        ; Compteur de caractères
    
.loop:
    movzx r13, byte [rdi + r12]
    test r13, r13       ; Vérifier si fin de chaîne
    jz .done
    
    cmp r13, '0'        ; Vérifier si c'est un chiffre
    jl .done
    cmp r13, '9'
    jg .done
    
    imul rax, 10        ; rax * 10
    sub r13, '0'        ; Convertir ASCII en nombre
    add rax, r13        ; Ajouter au résultat
    
    inc r12             ; Passer au caractère suivant
    jmp .loop
    
.done:
    pop r13
    pop r12
    ret

; Fonction itoa
; Entrée: RAX = nombre à convertir, RDI = pointeur vers buffer
; Sortie: RAX = longueur de la chaîne
itoa:
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rbx, rdi        ; Sauvegarder le pointeur original
    
    ; Cas spécial: zéro
    test rax, rax
    jnz .convert
    mov byte [rdi], '0'
    mov byte [rdi + 1], 0
    mov rax, 1
    jmp .end
    
.convert:
    mov r10, 10         ; Diviseur = 10
    xor rcx, rcx        ; Compteur = 0
    
.div_loop:
    xor rdx, rdx        ; Préparer pour division
    div r10             ; rax = quotient, rdx = reste
    
    add dl, '0'         ; Convertir en ASCII
    push rdx            ; Empiler le chiffre
    inc rcx             ; Incrémenter le compteur
    
    test rax, rax       ; Vérifier si on a fini
    jnz .div_loop
    
    ; Récupérer les chiffres dans l'ordre inverse
    mov rdx, 0          ; Index dans la chaîne
    
.stack_loop:
    pop rax             ; Dépiler un chiffre
    mov [rdi + rdx], al ; Stocker dans le buffer
    inc rdx             ; Incrémenter l'index
    dec rcx             ; Décrémenter le compteur
    jnz .stack_loop
    
    ; Ajouter le terminateur nul
    mov byte [rdi + rdx], 0
    
    ; Retourner la longueur
    mov rax, rdx
    
.end:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
