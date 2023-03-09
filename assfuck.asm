; this file will deal with command line arguments and set the appropriate parameters

section .rodata
	infile db "./example.bf",0	; file that will be compiled
	outfile db "./example.asm",0	; compiled file path

section .data
	its db 8 dup(0)

section .text
global _start
extern _compile

extern _num_to_str

_start:
	mov rdi, infile
	mov rsi, outfile
	call _compile

	; exit success
	mov rax, 60
	mov rdi, 0
	syscall
