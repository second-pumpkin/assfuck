; standard library but cooler (utility functions for the rest of the program)

%define OUTFD 4
%define BUFSIZE 128 ; write buffer size

section .data
	writebuf db BUFSIZE dup(0)
	writebufend dq $
	writebufpos dq writebuf ; keeps track of how far the write buffer has been written to

section .text
global _write
global _flush_write
global _num_to_str

; append the null-terminated string passed in by a pointer on rdi to writebuf, and if it fills flush the buffer to the file
_write:
	; loop through and copy every byte from the input string to writebuf
	mov rax, [writebufpos] ; load the position to write to the buffer at into rax
	write_loop:
		; copy the byte
		mov cl, byte [rdi]
		mov byte [rax], cl

		; advance the writebuf byte pointer, write the buffer if it's reached the end
		inc rax
		cmp rax, writebufend
		jne dont_flush

		mov qword [writebufpos], rax
		push rdi
		call _flush_write
		mov rax, qword [writebufpos]
		pop rdi
		
		dont_flush:
		; advance the input string byte position, exit if it's a null byte
		inc rdi
		cmp byte [rdi], 0
		je exit_write
	jmp write_loop

	exit_write:
	; update writebufpos
	mov [writebufpos], rax
ret

; actually write the writebuf. the file descriptor 4 is assumed to represent the output file
_flush_write:
	; get how many bytes to write
	mov rdx, [writebufpos]
	sub rdx, writebuf

	; syscall write
	mov rax, 1
	mov rdi, OUTFD
	mov rsi, writebuf
	syscall

	; reset the write buffer pointer to the beginning again
	mov qword [writebufpos], writebuf
ret

; convert a number passed in on rdi to a string in a buffer passed in on rsi
; returns the length of the string
_num_to_str:
	mov rcx, 10 ; the div and mul instruction doesn't accept immediates, so this is necessary
	
	; since calculate_digits_loop writes the string backwards, this loop finds the end of the string
	mov rax, rdi
	digit_length_loop:
		cmp rax, 10	; if the number has got below 10, rsi points to the last digit
		jb exit_digit_length_loop

		xor rdx, rdx	; zero this since it's treated as part of the divisor
		div rcx		; divide by 10
		inc rsi		; increment rsi to point to the next digit
	jmp digit_length_loop
	exit_digit_length_loop:
	mov byte [rsi+1], 0 ; null byte to end the string
	push rsi ; keep the pointer to the last digit for calculating the length later

	; now calculate the digits by repeatedly dividing by 10 and putting remainder in the string
	mov rax, rdi
	calculate_digits_loop:
		cmp rax, 10	; if the number has got below 10, finish up
		jb finish_digits
		
		xor rdx, rdx	; zero this since it's treated as part of the divisor
		div rcx		; divide by 10
		add dl, 48	; add 48 to the remainder to convert it to ascii
		mov [rsi], dl	; move that to the output
		dec rsi		; move rsi to the next digit's position
	jmp calculate_digits_loop
	
	finish_digits:
	; set the final digit to finish the string and calculate the length to return
	add al, 48
	mov [rsi], al
	pop rax
	sub rax, rsi
	add rax, 2
ret
