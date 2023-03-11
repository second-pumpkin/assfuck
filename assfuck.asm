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
	argv_loop:
		; exit if the zero has been reached
		cmp qword [rsp], 0
		je exit_argv_loop
		
		; detect - arguments
		pop rbx
		cmp byte [rbx], '-'
		jne set_infile
		
		; -o
		cmp byte [rbx+1], 'o'
		jne continue_argv_loop
		pop rsi
		jmp continue_argv_loop
		
		; arguments not prefixed with a - are treated as the input file
		set_infile:
		mov rdi, rbx
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
