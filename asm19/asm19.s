; asm19.asm - UDP listener saving messages to file
; Listens on UDP port 1337 and saves received messages to a file called "messages"

section .data
    ; Constants
    PORT        equ 1337
    BUFFER_SIZE equ 4096
    
    ; File descriptors
    sock_fd     dq 0      ; Socket file descriptor
    file_fd     dq 0      ; File descriptor for messages file
    
    ; Strings
    filename    db "messages", 0
    listening   db "⏳ Listening on port 1337", 10, 0
    error_msg   db "Error: ", 0
    
    ; Socket structures
    sockaddr:
        sin_family dw 2       ; AF_INET = 2
        sin_port   dw 0       ; Will be set with htons(PORT)
        sin_addr   dd 0       ; INADDR_ANY = 0
        sin_zero   times 8 db 0
    sockaddr_len equ $ - sockaddr

section .bss
    buffer      resb BUFFER_SIZE   ; Buffer for received data
    client_addr resb 16            ; Storage for client address
    client_len  resd 1             ; Length of client address

section .text
    global _start

_start:
    ; Initialize client_len to size of sockaddr structure
    mov dword [client_len], 16
    
    ; Convert port to network byte order (big endian)
    mov ax, PORT
    xchg al, ah              ; Simple htons implementation for 1337
    mov word [sin_port], ax
    
    ; Create a file for writing messages
    ; open("messages", O_CREAT | O_WRONLY | O_TRUNC, 0644)
    mov rax, 2               ; sys_open
    lea rdi, [filename]      ; filename
    mov rsi, 65              ; O_CREAT | O_WRONLY (64+1)
    mov rdx, 0644o           ; file permissions (octal)
    syscall
    
    ; Check for error
    cmp rax, 0
    jl error
    
    ; Save file descriptor
    mov [file_fd], rax
    
    ; Create UDP socket
    ; socket(AF_INET, SOCK_DGRAM, 0)
    mov rax, 41              ; sys_socket
    mov rdi, 2               ; AF_INET = 2
    mov rsi, 2               ; SOCK_DGRAM = 2
    mov rdx, 0               ; protocol = 0
    syscall
    
    ; Check for error
    cmp rax, 0
    jl error
    
    ; Save socket descriptor
    mov [sock_fd], rax
    
    ; Bind the socket to the port
    ; bind(sock_fd, &sockaddr, sizeof(sockaddr))
    mov rax, 49              ; sys_bind
    mov rdi, [sock_fd]       ; socket fd
    lea rsi, [sockaddr]      ; pointer to sockaddr struct
    mov rdx, sockaddr_len    ; length of sockaddr struct
    syscall
    
    ; Check for error
    cmp rax, 0
    jl error
    
    ; Print listening message
    mov rax, 1               ; sys_write
    mov rdi, 1               ; stdout
    lea rsi, [listening]     ; message
    mov rdx, 27              ; length
    syscall
    
receive_loop:
    ; Receive data
    ; recvfrom(sock_fd, buffer, BUFFER_SIZE, 0, &client_addr, &client_len)
    mov rax, 45              ; sys_recvfrom
    mov rdi, [sock_fd]       ; socket fd
    lea rsi, [buffer]        ; buffer
    mov rdx, BUFFER_SIZE     ; buffer size
    mov r10, 0               ; flags = 0
    lea r8, [client_addr]    ; client address
    lea r9, [client_len]     ; client address length
    syscall
    
    ; Check for error
    cmp rax, 0
    jl error
    
    ; Save received bytes count
    mov r12, rax
    
    ; Write received data to file
    ; write(file_fd, buffer, bytes_received)
    mov rax, 1               ; sys_write
    mov rdi, [file_fd]       ; file descriptor
    lea rsi, [buffer]        ; buffer with data
    mov rdx, r12             ; number of bytes received
    syscall
    
    ; Check for error
    cmp rax, 0
    jl error
    
    ; Write a newline to the file for each message
    mov byte [buffer], 10    ; newline character
    mov rax, 1               ; sys_write
    mov rdi, [file_fd]       ; file descriptor
    lea rsi, [buffer]        ; buffer with newline
    mov rdx, 1               ; one byte
    syscall
    
    ; Continue receiving
    jmp receive_loop

error:
    ; Print error message
    neg rax                  ; Get positive error code
    
    ; Exit with error code
    mov rdi, rax             ; exit code = error code
    mov rax, 60              ; sys_exit
    syscall

exit:
    ; Close the file
    mov rax, 3               ; sys_close
    mov rdi, [file_fd]       ; file descriptor
    syscall
    
    ; Close the socket
    mov rax, 3               ; sys_close
    mov rdi, [sock_fd]       ; socket descriptor
    syscall
    
    ; Exit program
    mov rax, 60              ; sys_exit
    xor rdi, rdi             ; exit code 0
    syscall
