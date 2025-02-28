;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Coffre-fort Memoire Securise - Implementation de Chiffrement RAM
;; Auteur: Jules MONCOMBLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
    ; Messages du programme
    welcome_msg     db "[+] Coffre-fort Memoire Securise", 10
                    db "    Stockez des donnees chiffrees en RAM", 10, 0
    help_msg        db "Commandes:", 10
                    db "  stocker <donnees> - Stocker des donnees chiffrees en memoire", 10
                    db "  lire              - Recuperer les donnees dechiffrees", 10
                    db "  cle <mot_de_passe> - Definir la cle de chiffrement (defaut: 42)", 10
                    db "  aide              - Afficher ce message d'aide", 10
                    db "  quitter           - Quitter le programme", 10, 0
    prompt          db "> ", 0
    stored_msg      db "[+] Donnees stockees en memoire chiffree", 10, 0
    retrieved_msg   db "[+] Donnees dechiffrees: ", 0
    key_set_msg     db "[+] Cle de chiffrement definie", 10, 0
    unknown_cmd_msg db "[-] Commande inconnue. Tapez 'aide' pour la liste des commandes", 10, 0
    no_data_msg     db "[-] Aucune donnee stockee pour l'instant", 10, 0
    newline         db 10, 0
    
    ; Chaines de commande
    cmd_help        db "aide", 0
    cmd_store       db "stocker", 0
    cmd_get         db "lire", 0
    cmd_key         db "cle", 0
    cmd_exit        db "quitter", 0
    
    ; Cle de chiffrement par defaut
    default_key     db "42", 0

section .bss
    input_buffer    resb 1024  ; Tampon d'entree
    secure_memory   resb 4096  ; Zone memoire securisee
    data_buffer     resb 1024  ; Tampon pour les donnees
    key_buffer      resb 64    ; Tampon pour la cle
    data_length     resq 1     ; Longueur des donnees stockees
    key_length      resq 1     ; Longueur de la cle de chiffrement
    cmd_buffer      resb 32    ; Tampon pour la commande

section .text
    global _start

_start:
    ; Initialiser la cle par defaut
    mov rsi, default_key
    call set_key
    
    ; Initialiser la longueur des donnees à 0
    mov qword [data_length], 0
    
    ; Afficher le message de bienvenue
    mov rsi, welcome_msg
    call print_string
    
    ; Afficher le message d'aide
    mov rsi, help_msg
    call print_string
    
main_loop:
    ; Afficher l'invite de commande
    mov rsi, prompt
    call print_string
    
    ; Lire l'entree utilisateur
    call read_line
    
    ; Extraire la commande
    call extract_command
    
    ; Verifier la commande
    call process_command
    
    ; Continuer la boucle
    jmp main_loop

; Fonction pour extraire la commande de l'entree utilisateur
extract_command:
    mov rsi, input_buffer    ; Source
    mov rdi, cmd_buffer      ; Destination pour la commande
    
    ; Passer les espaces initiaux
    .skip_initial_spaces:
        cmp byte [rsi], ' '
        jne .extract_cmd
        inc rsi
        jmp .skip_initial_spaces
    
    ; Extraire la commande
    .extract_cmd:
        xor rcx, rcx         ; Compteur de caracteres
        
    .copy_cmd_loop:
        mov al, [rsi + rcx]  ; Prochain caractere
        
        ; Verifier la fin de la commande
        cmp al, 0            ; Fin de chaine?
        je .end_of_cmd
        cmp al, ' '          ; Espace?
        je .end_of_cmd
        
        ; Copier le caractere dans le tampon de commande
        mov [rdi + rcx], al
        inc rcx
        cmp rcx, 31          ; Limite de taille de commande
        jge .end_of_cmd
        jmp .copy_cmd_loop
        
    .end_of_cmd:
        mov byte [rdi + rcx], 0  ; Terminer la commande par null
        ret

; Fonction pour traiter la commande extraite
process_command:
    ; Comparer avec "aide"
    mov rdi, cmd_buffer
    mov rsi, cmd_help
    call string_equals
    cmp rax, 1
    je .help_command
    
    ; Comparer avec "stocker"
    mov rdi, cmd_buffer
    mov rsi, cmd_store
    call string_equals
    cmp rax, 1
    je .store_command
    
    ; Comparer avec "lire"
    mov rdi, cmd_buffer
    mov rsi, cmd_get
    call string_equals
    cmp rax, 1
    je .get_command
    
    ; Comparer avec "cle"
    mov rdi, cmd_buffer
    mov rsi, cmd_key
    call string_equals
    cmp rax, 1
    je .key_command
    
    ; Comparer avec "quitter"
    mov rdi, cmd_buffer
    mov rsi, cmd_exit
    call string_equals
    cmp rax, 1
    je .exit_command
    
    ; Commande inconnue
    mov rsi, unknown_cmd_msg
    call print_string
    ret
    
.help_command:
    mov rsi, help_msg
    call print_string
    ret
    
.store_command:
    ; Trouver le debut des donnees (apres "stocker ")
    mov rsi, input_buffer
    call find_command_data
    
    ; Si pas de donnees, retourner
    cmp byte [rsi], 0
    je .empty_data
    
    ; Stocker les donnees
    call store_data
    
    ; Afficher confirmation
    mov rsi, stored_msg
    call print_string
    ret
    
.get_command:
    ; Verifier si des donnees sont stockees
    mov rax, [data_length]
    test rax, rax
    jz .no_data
    
    ; Afficher message
    mov rsi, retrieved_msg
    call print_string
    
    ; Recuperer et afficher les donnees
    call get_data
    ret
    
.no_data:
    mov rsi, no_data_msg
    call print_string
    ret
    
.key_command:
    ; Trouver le debut de la cle (apres "cle ")
    mov rsi, input_buffer
    call find_command_data
    
    ; Si pas de cle, retourner
    cmp byte [rsi], 0
    je .empty_key
    
    ; Definir la cle
    call set_key
    
    ; Afficher confirmation
    mov rsi, key_set_msg
    call print_string
    ret
    
.exit_command:
    ; Quitter le programme
    mov rax, 60  ; sys_exit
    xor rdi, rdi  ; code 0
    syscall
    
.empty_data:
.empty_key:
    ret

; Fonction pour trouver les donnees d'une commande
; Entree: RSI = buffer d'entree
; Sortie: RSI = pointeur vers les donnees
find_command_data:
    ; Passer les espaces initiaux
    .skip_initial_spaces:
        cmp byte [rsi], ' '
        jne .find_first_space
        inc rsi
        jmp .skip_initial_spaces
    
    ; Trouver le premier espace apres la commande
    .find_first_space:
        cmp byte [rsi], 0    ; Fin de chaine?
        je .end_of_input
        cmp byte [rsi], ' '  ; Espace?
        je .found_space
        inc rsi
        jmp .find_first_space
    
    .found_space:
        ; Passer les espaces apres la commande
        .skip_spaces_after_cmd:
            inc rsi
            cmp byte [rsi], ' '
            je .skip_spaces_after_cmd
            ret
    
    .end_of_input:
        mov byte [rsi], 0    ; Assurer la fin
        ret

; Fonction pour comparer deux chaines
; Entree: RDI = premiere chaine, RSI = deuxieme chaine
; Sortie: RAX = 1 si egal, 0 si different
string_equals:
    push rdi
    push rsi
    
.compare_loop:
    mov al, [rdi]
    mov bl, [rsi]
    
    ; Si les caracteres sont differents
    cmp al, bl
    jne .not_equal
    
    ; Si on a atteint la fin des deux chaines
    test al, al
    jz .equal
    
    ; Avancer au caractere suivant
    inc rdi
    inc rsi
    jmp .compare_loop
    
.equal:
    mov rax, 1    ; 1 = egal
    pop rsi
    pop rdi
    ret
    
.not_equal:
    xor rax, rax  ; 0 = different
    pop rsi
    pop rdi
    ret
    
; Fonction pour lire une ligne depuis stdin
read_line:
    mov rax, 0    ; sys_read
    mov rdi, 0    ; stdin
    mov rsi, input_buffer
    mov rdx, 1023
    syscall
    
    ; Ajouter terminateur null
    mov byte [input_buffer+rax], 0
    
    ; Remplacer newline par null si present
    cmp rax, 0
    je .done      ; Si rien n'a ete lu
    
    dec rax
    cmp byte [input_buffer+rax], 10  ; Newline?
    jne .done
    mov byte [input_buffer+rax], 0
    
.done:
    ret
    
; Fonction pour afficher une chaine
; Entree: RSI = pointeur vers la chaine
print_string:
    push rsi
    xor rdx, rdx  ; Compteur pour la longueur
    
.length_loop:
    cmp byte [rsi+rdx], 0
    je .print
    inc rdx
    jmp .length_loop
    
.print:
    mov rax, 1    ; sys_write
    mov rdi, 1    ; stdout
    ; RSI et RDX contiennent deja la chaine et la longueur
    syscall
    
    pop rsi
    ret
    
; Fonction pour definir la cle de chiffrement
; Entree: RSI = pointeur vers la cle
set_key:
    push rsi
    xor rcx, rcx  ; Compteur
    
.key_length_loop:
    cmp byte [rsi+rcx], 0
    je .set_length
    inc rcx
    cmp rcx, 63   ; Longueur max
    jge .set_max_length
    jmp .key_length_loop
    
.set_max_length:
    mov rcx, 63
    
.set_length:
    mov [key_length], rcx
    
    ; Copier la cle
    mov rdi, key_buffer
    mov rdx, rcx
    
.copy_loop:
    test rdx, rdx
    jz .done
    dec rdx
    mov al, [rsi+rdx]
    mov [rdi+rdx], al
    jmp .copy_loop
    
.done:
    pop rsi
    ret
    
; Fonction pour stocker des donnees
; Entree: RSI = pointeur vers les donnees
store_data:
    push rsi
    xor rcx, rcx  ; Compteur
    
.count_loop:
    cmp byte [rsi+rcx], 0
    je .store
    inc rcx
    cmp rcx, 1023  ; Limite
    jge .set_max_length
    jmp .count_loop
    
.set_max_length:
    mov rcx, 1023
    
.store:
    mov [data_length], rcx
    
    ; Copier les donnees dans le tampon
    mov rdi, data_buffer
    mov rdx, rcx
    
.copy_loop:
    test rdx, rdx
    jz .encrypt
    dec rdx
    mov al, [rsi+rdx]
    mov [rdi+rdx], al
    jmp .copy_loop
    
.encrypt:
    ; Chiffrer les donnees
    call encrypt_data
    
    pop rsi
    ret
    
; Fonction pour recuperer les donnees
get_data:
    ; Dechiffrer les donnees
    call decrypt_data
    
    ; Assurer que les donnees sont terminees par null
    mov rcx, [data_length]
    mov byte [data_buffer+rcx], 0
    
    ; Afficher les donnees
    mov rsi, data_buffer
    call print_string
    
    ; Ajouter une nouvelle ligne
    mov rsi, newline
    call print_string
    
    ret
    
; Fonction pour chiffrer les donnees
encrypt_data:
    xor rcx, rcx  ; Compteur
    mov rax, [data_length]
    
.encrypt_loop:
    cmp rcx, rax
    jge .done
    
    ; Obtenir le caractere a chiffrer
    mov dl, [data_buffer+rcx]
    
    ; Calculer l'index de la cle (cyclique)
    push rax
    push rdx
    
    mov rax, rcx
    xor rdx, rdx
    mov rsi, [key_length]
    div rsi        ; RDX = RCX % key_length
    
    ; Appliquer XOR avec la cle
    mov al, [key_buffer+rdx]
    pop rdx
    xor dl, al     ; XOR le caractere avec la cle
    
    ; Stocker le resultat
    mov [secure_memory+rcx], dl
    
    pop rax
    inc rcx
    jmp .encrypt_loop
    
.done:
    ret
    
; Fonction pour dechiffrer les donnees
decrypt_data:
    xor rcx, rcx  ; Compteur
    mov rax, [data_length]
    
.decrypt_loop:
    cmp rcx, rax
    jge .done
    
    ; Obtenir le caractere chiffre
    mov dl, [secure_memory+rcx]
    
    ; Calculer l'index de la cle (cyclique)
    push rax
    push rdx
    
    mov rax, rcx
    xor rdx, rdx
    mov rsi, [key_length]
    div rsi        ; RDX = RCX % key_length
    
    ; Appliquer XOR avec la cle
    mov al, [key_buffer+rdx]
    pop rdx
    xor dl, al     ; XOR le caractere chiffre avec la cle
    
    ; Stocker le resultat
    mov [data_buffer+rcx], dl
    
    pop rax
    inc rcx
    jmp .decrypt_loop
    
.done:
    ret
