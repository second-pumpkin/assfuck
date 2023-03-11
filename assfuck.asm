; this file will deal with command line arguments and set the appropriate parameters

section .rodata
	infile db "./example.bf",0	; file that will be compiled
	outfile db "./example.asm",0	; compiled file path

section .data
	its db 8 dup(0)

section .text
global _start
extern _compile
extern _error

_start:
	; ignore argc and the first argument
	add rsp, 16

	; process each argument. argv always ends in zero, so loop until it hits that
	xor rdi, rdi
	xor rsi, rsi
	xor rdx, rdx
	xor rcx, rcx
	argv_loop:
		; exit if the zero has been reached
		cmp qword [rsp], 0
		je exit_argv_loop
		
		; detect - arguments
		pop rbx
		cmp byte [rbx], '-'
		je a1
		mov rdi, rbx ; arguments not prefixed with - are treated as the input file
		jmp continue_argv_loop
		
		; -o
		a1: cmp byte [rbx+1], 'o'
		jne a2
		pop rsi
		jmp continue_argv_loop

		; -a
		a2: cmp byte [rbx+1], 'a'
		jne a3
		mov rdx, 1
		jmp continue_argv_loop

		; -j
		a3: cmp byte [rbx+1], 'j'
		jne a4
		mov rdx, 2
		jmp continue_argv_loop

		; -f
		a4: cmp byte [rbx+1], 'f'
		jne continue_argv_loop
		pop rcx
		cmp rdx, 0
		jne continue_argv_loop
		mov rdx, 2

		continue_argv_loop:
	jmp argv_loop
	exit_argv_loop:

	; if either the input or the output files weren't specified, throw an error
	cmp rdi, 0
	jne e1
	mov rax, -999
	jmp _error

	e1: cmp rsi, 0
	jne no
	mov rax, -1001
	jmp _error
	
	no:
	; compile :)
	call _compile

	; exit success
	mov rax, 60
	mov rdi, 0
	syscall
