section .data
        msg db "1337", 0x0A
        len equ $ - msg
        expected db "42", 0

section .text
        global _start

_start:
	pop rdi
        cmp rdi, 2 ; rdi = argc donc verifie si 2 arguments
        jne _error ;si diff jump

        pop rdi
	pop rdi
	mov al, [rdi]
	cmp al, "4"
	jne _error
	
	mov al, [rdi+1]
	cmp al, "2"
	jne _error

	mov al, [rdi+2]
	cmp al, 0x00
	jne _error
	je _bon

_bon:
	mov rax, 1
	mov rdi, 1
	mov rsi, msg
	mov rdx, len
	syscall

	mov rax, 60
	mov rdi, 0
	syscall

_error:
        mov rax, 60 
        mov rdi, 1
        syscall

