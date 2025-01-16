section .bss
	buffer resb 20

section .text
	global _start

_start:
	; entree utilisateur
	mov rax, 0 ;read
	mov rdi, 0 ;stdin 
	mov rsi, buffer
	mov rdx, 20
	syscall
	
	mov r8, rax ; r8 devient length rax
	mov rax, 0 ;on met rax a 0
	mov rsi, buffer

_conversion:

;verifier index buffer
	cmp r8, 0 ; check fin de chaine
	je _parite ;si equal, goto parite

;charger caractère
	movzx rcx, byte [rsi]
	cmp rcx, 0x0A ;verifie pour  \n fin de chaine
	je _parite

;verifier si c'est un chiffre

	cmp rcx, '0'
	jl _error
	cmp rcx, '9'
	jg _error

; conversion ascii / decimal

	sub rcx, '0' ; recupere valeur decimale depuis l'ascii (-48)
	imul rax, rax, 10 ; décalage pour stocker le nombre petit a petit
	add rax, rcx
	inc rsi
	dec r8
	jmp _conversion

_parite:
	test rax, 1
	jz _return_zero ;si c'est pair on va a return zero

	;sinon
	mov rax, 60
	mov rdi, 1
	syscall

_return_zero:
	mov rax, 60
	mov rdi, 0
	syscall

_error:
	mov rax, 60 ;exit
	mov rdi, 2
	syscall
