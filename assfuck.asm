; this file will deal with command line arguments and set the appropriate parameters

section .rodata
	helptext db 									\
		"usage: assfuck [input] -o [output] [options]",10,			\
		10,									\
		"options:",10,								\
		"    -o [file]",10,							\
		"        specifies the output file. required.",10,			\
		"    -f [func]",10,							\
		"        output an object file defining a function named func.",10,	\
		"        if -a isn't specified, this implies -j.",10,			\
		"    -a",10,								\
		"        output assembly only.",10,					\
		"    -j",10,								\
		"        output an object file only.",10,				\
		"    -h",10,								\
		"        print this text and exit.",10,					\
		10
	helptextsize dq $-helptext


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
		jne a5
		pop rcx
		cmp rdx, 0
		jne continue_argv_loop
		mov rdx, 2
		jmp continue_argv_loop

		; -h
		a5: cmp byte [rbx+1], 'h'
		jne continue_argv_loop
		jmp _help

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

_help:
	; print the help text
	mov rax, 1	; syscall write
	mov rdi, 1	; stdout
	mov rsi, helptext
	mov rdx, qword [helptextsize]
	syscall

	; exit
	mov rax, 60	; syscall exit
	xor rdi, rdi	; exit success
	syscall
