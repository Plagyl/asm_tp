section .data
    invalid_input db "Entrée invalide", 10
    newline db 10

section .bss
    output_buffer resb 32

section .text
    global _start

_start:
    ; Vérifier si un argument est passé
    cmp qword [rsp], 2
    jne invalid_input_error

    ; Récupérer l'argument
    mov rsi, [rsp + 16]  ; Adresse de l'argument
    call atoi            ; Convertir l'argument en entier

    ; Vérifier si la conversion a réussi
    cmp rax, -1
    je invalid_input_error

    ; Si l'entrée est 0 ou 1, la somme est 0
    cmp rax, 1
    jle sum_zero

    ; Calculer la somme des nombres inférieurs à l'entier donné
    mov rcx, rax         ; RCX = nombre donné
    dec rcx              ; Exclure le nombre donné
    xor rax, rax         ; RAX = somme (initialisée à 0)
    xor rbx, rbx         ; RBX = compteur (initialisé à 0)

sum_loop:
    inc rbx              ; Incrémenter le compteur
    add rax, rbx         ; Ajouter le compteur à la somme
    cmp rbx, rcx         ; Comparer le compteur avec le nombre donné - 1
    jl sum_loop          ; Répéter tant que le compteur < nombre donné - 1

    jmp print_result

sum_zero:
    xor rax, rax         ; RAX = 0 (somme pour 0 ou 1)

print_result:
    ; Convertir la somme en chaîne de caractères
    mov rdi, output_buffer
    call int_to_string

    ; Afficher la somme
    mov rsi, output_buffer
    call print_string

    ; Retourner 0 (succès)
    mov rdi, 0
    jmp exit

invalid_input_error:
    ; Afficher un message d'erreur
    mov rsi, invalid_input
    call print_string

    ; Retourner 1 (échec)
    mov rdi, 1

exit:
    ; Quitter le programme
    mov rax, 60          ; syscall: exit
    syscall

; Fonction pour convertir une chaîne en entier (atoi) avec gestion stricte des erreurs
atoi:
    xor rax, rax         ; RAX = 0 (résultat)
    xor rcx, rcx         ; RCX = compteur
    xor r8, r8           ; Indicateur de validité (au moins un chiffre lu)

    movzx rdx, byte [rsi]  ; Lire le premier caractère

    ; Vérifier si l'entrée est vide ou commence par un saut de ligne
    cmp rdx, 0
    je atoi_invalid
    cmp rdx, 10
    je atoi_invalid

    ; Vérifier si l'entrée commence par un '-'
    cmp rdx, '-'
    je atoi_invalid

atoi_loop:
    movzx rdx, byte [rsi + rcx]  ; Charger le prochain caractère

    cmp rdx, 0                  ; Vérifier la fin de la chaîne
    je atoi_done
    cmp rdx, 10                 ; Vérifier un saut de ligne
    je atoi_done

    ; Vérifier si le caractère est un chiffre
    cmp rdx, '0'
    jb atoi_invalid
    cmp rdx, '9'
    ja atoi_invalid

    sub rdx, '0'                ; Convertir le caractère en chiffre
    imul rax, rax, 10           ; Multiplier le résultat par 10
    add rax, rdx                ; Ajouter le chiffre au résultat
    inc rcx                     ; Passer au caractère suivant
    mov r8, 1                   ; Indiquer qu'on a traité au moins un chiffre
    jmp atoi_loop

atoi_invalid:
    mov rax, -1                 ; Retourner -1 pour signaler une entrée invalide
    ret

atoi_done:
    cmp r8, 0                   ; Si aucun chiffre n'a été lu, entrée invalide
    je atoi_invalid
    ret

; Fonction pour convertir un entier en chaîne de caractères
int_to_string:
    mov rbx, 10          ; Base 10
    xor rcx, rcx         ; Compteur de chiffres

int_to_string_loop:
    xor rdx, rdx         ; RDX = 0
    div rbx              ; Diviser RAX par 10
    add rdx, '0'         ; Convertir le reste en caractère
    push rdx             ; Empiler le caractère
    inc rcx              ; Incrémenter le compteur
    cmp rax, 0           ; Vérifier si RAX == 0
    jne int_to_string_loop

    ; Dépiler les caractères dans le buffer
    mov rdi, output_buffer

int_to_string_done:
    pop rax              ; Dépiler un caractère
    mov [rdi], al        ; Stocker le caractère dans le buffer
    inc rdi              ; Passer à la position suivante
    loop int_to_string_done

    ; Ajouter un caractère nul pour terminer la chaîne
    mov byte [rdi], 0
    ret

; Fonction pour afficher une chaîne de caractères
print_string:
    mov rdi, 1           ; Descripteur de fichier (stdout)
    mov rax, 1           ; syscall: write
    mov rdx, 0           ; Longueur de la chaîne (calculée ci-dessous)

print_string_length:
    cmp byte [rsi + rdx], 0
    je print_string_output
    inc rdx
    jmp print_string_length

print_string_output:
    syscall
    ret

