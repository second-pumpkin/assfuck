; this file does everything after the compiler:
; assembles, links, and cleans up any temporary files used

;     the mode is passed in by rdi:
;         a mode of 0 outputs a standalone executable binary
;         a mode of 1 outputs the assembly
;         a mode of 2 outputs the object file
;     the output file is passed in by rsi

section .rodata
	nasm_argv0 db "/usr/bin/nasm",0
	nasm_argv1 db "-f",0
	nasm_argv2 db "elf64",0
	nasm_argv3 db "bf_tmp.asm",0

	ld_argv0 db "/usr/bin/ld",0
	ld_argv1 db "bf_tmp.o",0
	ld_argv2 db "-o",0
	ld_argv3 db "bf_tmp",0

	nasm_argv dq nasm_argv0, nasm_argv1, nasm_argv2, nasm_argv3, 0
	ld_argv dq ld_argv0, ld_argv1, ld_argv2, ld_argv3, 0

section .text
global _finish

_finish:
	push rsi
	mov rbx, rdi
	
	; if the mode is 1, skip assembling and linking
	cmp rbx, 1
	jne assemble
	mov rdi, nasm_argv3
	jmp finalize

	assemble:
	mov rdi, nasm_argv0
	mov rsi, nasm_argv
	call _fork_and_wait

	; if the mode is 2, skip linking
	cmp rbx, 2
	jne link
	mov rdi, ld_argv1
	jmp finalize

	link:
	mov rdi, ld_argv0
	mov rsi, ld_argv
	call _fork_and_wait
	mov rdi, ld_argv3

	finalize:
	; rename the file to the output file. the final temporary file has already been put in rdi
	mov rax, 82	; syscall rename
	pop rsi		; output file
	syscall

	; delete the temporary files
	cmp rbx, 1	; if the mode is 1, there's nothing to delete
	je exit
	
	mov rax, 87	; syscall unlink
	mov rdi, nasm_argv3 ; bf_tmp.asm
	syscall

	cmp rbx, 2	; if the mode is 2, everything was deleted
	je exit

	mov rax, 87
	mov rdi, ld_argv1 ; bf_tmp.o
	syscall

	exit:
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
