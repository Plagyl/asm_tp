section .data
    success_msg db "message: Hello, client!", 10
    success_len equ $ - success_msg
    
    timeout_msg db "Timeout: no response from server", 10
    timeout_len equ $ - timeout_msg
    
    ; Adresse du serveur
    server_ip dd 0x0100007f    ; 127.0.0.1 en format réseau (little-endian)
    server_port dw 0x3905      ; Port 1337 en format réseau (little-endian)
    
    ; Message à envoyer
    send_buffer db "Hello, server!", 0
    send_len equ $ - send_buffer - 1
    
    ; Constantes
    AF_INET equ 2              ; IPv4
    SOCK_DGRAM equ 2           ; UDP
    SOL_SOCKET equ 1           ; Socket level pour setsockopt
    SO_RCVTIMEO equ 20         ; Option pour timeout de réception

section .bss
    recv_buffer resb 1024      ; Buffer pour recevoir la réponse
    sockaddr resb 16           ; Structure sockaddr_in
    timeval resb 16            ; Structure timeval pour timeout

section .text
    global _start

_start:
    ; Créer un socket UDP
    mov rax, 41                ; sys_socket
    mov rdi, AF_INET           ; IPv4
    mov rsi, SOCK_DGRAM        ; UDP
    xor rdx, rdx               ; Protocole par défaut
    syscall
    
    ; Vérifier si le socket a été créé correctement
    test rax, rax
    js error_exit
    
    ; Sauvegarder le descripteur de socket
    mov r15, rax
    
    ; Configurer le timeout (1 seconde)
    ; struct timeval { tv_sec = 1, tv_usec = 0 }
    mov qword [timeval], 1     ; tv_sec = 1
    mov qword [timeval+8], 0   ; tv_usec = 0
    
    ; Appeler setsockopt pour configurer le timeout de réception
    mov rax, 54                ; sys_setsockopt
    mov rdi, r15               ; socket
    mov rsi, SOL_SOCKET        ; level
    mov rdx, SO_RCVTIMEO       ; optname
    mov r10, timeval           ; optval
    mov r8, 16                 ; optlen
    syscall
    
    ; Ignorer les erreurs de setsockopt
    
    ; Préparer la structure sockaddr_in
    mov word [sockaddr], AF_INET        ; sin_family = AF_INET
    mov ax, [server_port]               ; Charger le port
    mov [sockaddr+2], ax                ; sin_port = 1337 (format réseau)
    mov eax, [server_ip]                ; Charger l'adresse IP
    mov [sockaddr+4], eax               ; sin_addr = 127.0.0.1 (format réseau)
    mov qword [sockaddr+8], 0           ; Mettre à zéro le reste
    
    ; Envoyer le message
    mov rax, 44                ; sys_sendto
    mov rdi, r15               ; socket
    mov rsi, send_buffer       ; buffer
    mov rdx, send_len          ; length
    mov r10, 0                 ; flags
    mov r8, sockaddr           ; dest_addr
    mov r9, 16                 ; addrlen
    syscall
    
    ; Vérifier si l'envoi a échoué
    test rax, rax
    js try_recv                ; Si erreur, essayer quand même de recevoir
    
try_recv:
    ; Tenter de recevoir une réponse
    mov rax, 45                ; sys_recvfrom
    mov rdi, r15               ; socket
    mov rsi, recv_buffer       ; buffer
    mov rdx, 1023              ; length (laisser de la place pour le zéro terminal)
    mov r10, 0                 ; flags
    xor r8, r8                 ; src_addr = NULL
    xor r9, r9                 ; addrlen = NULL
    syscall
    
    ; Vérifier si la réception a échoué (probablement timeout)
    test rax, rax
    js timeout
    
    ; Ajouter un caractère nul de fin
    mov byte [recv_buffer + rax], 0
    
    ; Message reçu avec succès
    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rsi, success_msg       ; message
    mov rdx, success_len       ; length
    syscall
    
    ; Fermer le socket
    mov rax, 3                 ; sys_close
    mov rdi, r15               ; socket
    syscall
    
    ; Sortir avec succès
    mov rax, 60                ; sys_exit
    xor rdi, rdi               ; code 0
    syscall
    
timeout:
    ; Afficher le message de timeout
    mov rax, 1                 ; sys_write
    mov rdi, 1                 ; stdout
    mov rsi, timeout_msg       ; buffer
    mov rdx, timeout_len       ; length
    syscall
    
    ; Fermer le socket
    mov rax, 3                 ; sys_close
    mov rdi, r15               ; socket
    syscall
    
    ; Sortir avec erreur
    mov rax, 60                ; sys_exit
    mov rdi, 1                 ; code 1
    syscall
    
error_exit:
    ; Sortir avec erreur
    mov rax, 60                ; sys_exit
    mov rdi, 1                 ; code 1
    syscall
