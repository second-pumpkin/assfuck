; do preprocessing on the input file:
; preprocessing involves checking for syntax errors (unclosed loops)
; as well as getting information about the code the compiler needs (maximum loop depth)

; _preprocess accepts no parameters, and returns the maximum loop depth (or -1 if the loops aren't balanced)

%define INFD 3
%define BUFSIZE 128

section .bss
	readbuf db BUFSIZE dup(?)

section .text
global _preprocess

_preprocess:
	; loop and read through the entire file
	xor rbx, rbx ; current loop depth is kept track of with rbx
	read_loop:
		; read a section of text from the input file
		xor rax, rax
		mov rdi, INFD
		mov rsi, readbuf
		mov rdx, BUFSIZE
		syscall

		; if nothing was read, everything has been read
		cmp rax, 0
		je finish
		
		; loop through this text
		xor r13, r13 ; r13 is the index in the read buffer
		process_read_loop:
			; [ increases the loop depth
			cmp byte [readbuf+r13], '['
			jne c1
			inc rbx
			jmp next_byte
			
			; ] decreases the loop depth. if the loop depth goes below zero, the file is invalid
			c1:
			cmp byte [readbuf+r13], ']'
			jne next_byte
			dec rbx
			js finish

			; increment the index, and if it's equal to the number of bytes read, try to read some more
			next_byte:
			inc r13
			cmp r13, rax
			je read_loop
		jmp process_read_loop
	
	finish:
	; put the cursor back at the beginning of the file for the compiler
	mov rax, 8	; syscall lseek
	mov rdi, INFD
	xor rsi, rsi	; zero offset
	xor rdx, rdx	; SEEK_SET
	syscall

	; set the return value
	xor rax, rax
	cmp rbx, 0
	je exit
	mov rax, -979

	exit:
ret
