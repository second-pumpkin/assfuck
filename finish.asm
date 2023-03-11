; this file does everything after the compiler:
; assembles, links, and cleans up any temporary files used

;     the mode is passed in by rdi:
;         a mode of 0 outputs a standalone executable binary
;         a mode of 1 outputs an object file
;     the output file is passed in by rsi

section .rodata
	nasm_argv0 db "/usr/bin/nasm",0
	nasm_argv1 db "-f",0
	nasm_argv2 db "elf64",0
	nasm_argv3 db "bf_tmp.asm",0

	ld_argv0 db "/usr/bin/ld",0
	ld_argv1 db "bf_tmp.o",0
	ld_argv2 db "-o",0

section .data
	nasm_argv dq nasm_argv0, nasm_argv1, nasm_argv2, nasm_argv3, 0
	ld_argv dq ld_argv0, ld_argv1, ld_argv2, 0, 0

section .text
global _finish

_finish:
	push rsi

	; assemble
	mov rdi, nasm_argv0
	mov rsi, nasm_argv
	call _fork_and_wait

	; link
	pop qword [ld_argv+24] ; output file executable
	mov rdi, ld_argv0
	mov rsi, ld_argv
	call _fork_and_wait
ret

; fork the process and wait for the child to terminate
; pass in the path to the program to be executed on rdi and argv on rsi
_fork_and_wait:
	mov rax, 57	; syscall fork
	syscall

	cmp rax, 0
	jne wait4

	; child process
	mov rax, 59	; syscall execve
	xor rdx, rdx	; no environment variables because they're not necessary
	syscall

	wait4:
	; parent process
	mov rdi, rax	; child pid
	mov rax, 61	; syscall wait4
	xor rsi, rsi
	xor rdx, rdx
	xor r10, r10
	syscall
ret
