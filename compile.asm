; _compile actually compiles the brainfuck file
;
;     the input file's path is passed in as a pointer to a null-terminated string in rdi
;     the output file's path is passed in the same way in rsi
;     the mode (used by _finish) is passed in by rdx
;     if the -f argument was used, rcx contains a pointer to a null-terminated string
;     determining the name of the function. otherwise, it should be zero

; macros (very cool)
%define INFD 3 		; input file descriptor
%define BUFSIZE 128	; read buffer size

section .rodata
	header db  "section .data",10,			\
		   "memory db 4096 dup (0)",10,10,	\
		   "section .text",10,			\
		   "global ",0
	start db    "_start",0
	newline db 10,0
	header2 db ":",10,				\
		   "push rbx",10,			\
		   "lea rbx, [rel memory]",10,10,0
	exit db    "mov rax, 60",10,			\
		   "xor rdi, rdi",10,			\
		   "syscall",0
	return db  "pop rbx",10,			\
		   "ret",0
	
	; simple static operations (+, -, <, >, ., and ,)
	increment db "inc byte [rbx]",10,10,0
	decrement db "dec byte [rbx]",10,10,0
	shiftl db "dec rbx",10,10,0
	shiftr db "inc rbx",10,10,0
	printc db "mov rax, 1",10,	\
		  "mov rdi, 1",10,	\
		  "mov rsi, rbx",10,	\
		  "mov rdx, 1",10,	\
		  "syscall",10,10,0
	getc db   "xor rax, rax",10,	\
		  "xor rdi, rdi",10,	\
		  "mov rsi, rbx",10,	\
		  "mov rdx, 1",10,	\
		  "syscall",10,10,0
	
	tmp_asm db "bf_tmp.asm",0

section .data
	; brackets consist of two parts: a conditional jump and a label
	; each one needs some undefined data after to set a number to make them unique
	openjmp db "cmp byte [rbx], 0",10,	\
		   "jz LE"
	openjmpnum db 16 dup(0)
	openlabel db "L"
	openlabelnum db 16 dup(0)
	closejmp db "cmp byte [rbx], 0",10,	\
		    "jnz L"
	closejmpnum db 16 dup(0)
	closelabel db "LE"
	closelabelnum db 16 dup(0)
	
section .bss
	readbuf db BUFSIZE dup(?)

section .text
global _compile
extern _preprocess
extern _write
extern _flush_write
extern _error
extern _num_to_str
extern _finish

_compile:
	; push some parameters so they're not modified
	push rsi
	push rdx
	push rcx

	; open the input file (pathname is already in the proper register, rdi)
	mov rax, 2	; syscall open
	mov rsi, 0	; O_RDONLY
	syscall
	cmp rax, 0
	js _error
	
	; call the preprocessor
	call _preprocess
	cmp rax, 0
	js _error

	; create/open the output (asm) file
	mov rax, 2	; syscall open
	mov rdi, tmp_asm; temporary file to put assembly in
	mov rsi, 101	; O_CREAT | O_WRONLY
	mov rdx, 0x1a4	; mode 644
	syscall
	cmp rax, 0
	js _error
	
	; write the initial text every program will share
	; if the value on the top of the stack is nonzero, write the header
	; with the string pointed to by that value as the entrypoint.
	; otherwise, write the header with _start as the entrypoint.
	mov rdi, header
	call _write

	cmp qword [rsp], 0
	jne write_header
	push start
	mov rbx, 4 ; magic number so we know to remove the string from the stack

	write_header:
	mov rdi, qword [rsp]
	call _write
	mov rdi, newline
	call _write
	mov rdi, qword [rsp]
	call _write
	mov rdi, header2
	call _write

	cmp rbx, 4
	jne dont_pop
	add rsp, 8
	dont_pop:

	; progressively read through the file, and write instructions to the output file
	xor r13, r13 ; r13 stores the bracket number (increments every time a [ is encountered) 
	read_loop:
		; read the next batch of data
		xor rax, rax
		mov rdi, INFD
		mov rsi, readbuf
		mov rdx, BUFSIZE
		syscall
		cmp rax, 0
		js _error
		mov r12, rax ; move the number of bytes read to a register that won't be modified by any function

		; the value returned is the amount of bytes read. if it reads nothing, the end of the file has been reached
		cmp r12, 0
		je exit_read_loop

		; process every character in the file and write instructions to the output file
		xor rbx, rbx ; rbx stores the index in the buffer
		process_read_loop:
			; assembly switch statement challenge??? (gone wrong)
			; this puts the text corresponding to the instruction in rdi.
			; the brackets have some extra stuff for putting the right number
			; on their text and working with the bracket nesting stack.

			cmp byte [readbuf+rbx], '+'
			jne i1
			mov rdi, increment
			jmp write_i

			i1: cmp byte [readbuf+rbx], '-'
			jne i2
			mov rdi, decrement
			jmp write_i

			i2: cmp byte [readbuf+rbx], '<'
			jne i3
			mov rdi, shiftl
			jmp write_i

			i3: cmp byte [readbuf+rbx], '>'
			jne i4
			mov rdi, shiftr
			jmp write_i

			i4: cmp byte [readbuf+rbx], '.'
			jne i5
			mov rdi, printc
			jmp write_i

			i5: cmp byte [readbuf+rbx], ','
			jne i6
			mov rdi, getc
			jmp write_i

			i6: cmp byte [readbuf+rbx], '['
			jne i7

			; first write the conditional jump
			mov rdi, r13 ; get the bracket number
			mov rsi, openjmpnum
			call _num_to_str
			mov word [openjmpnum+rax-1], 0x000a ; append a newline and a null byte to the result
			mov rdi, openjmp	            ; (they're backwards because endianness or something)
			call _write

			; write the label
			mov rdi, r13
			mov rsi, openlabelnum
			call _num_to_str
			mov dword [openlabelnum+rax-1], 0x000a0a3a ; append colon, double newline, and a null byte
			mov rdi, openlabel
			call _write

			; update bracket number stuff and exit. jumping to write_i is unnecessary since the stuff has already been written
			push r13
			inc r13
			jmp exit_switch

			i7: cmp byte [readbuf+rbx], ']'
			jne i8

			; this is basically the same as the [ section
			mov rdi, [rsp]
			mov rsi, closejmpnum
			call _num_to_str
			mov word [closejmpnum+rax-1], 0x000a
			mov rdi, closejmp
			call _write
			
			mov rdi, [rsp]
			mov rsi, closelabelnum
			call _num_to_str
			mov dword [closelabelnum+rax-1], 0x000a0a3a
			mov rdi, closelabel
			call _write

			add rsp, 8
			jmp exit_switch

			i8: jmp exit_switch
			
			write_i:
			call _write

			exit_switch:
			; advance the index and exit if it's reached the end
			inc rbx
			cmp rbx, r12
			jne process_read_loop
	jmp read_loop

	exit_read_loop:
	; write the final section of code, which is either a ret instruction or an exit syscall
	; depending on whether or not the value at the top of the stack is nonzero
	pop rdi
	cmp rdi, 0
	je footer_exit

	mov rdi, return
	jmp write_footer

	footer_exit:
	mov rdi, exit

	write_footer:
	call _write
	call _flush_write

	; finish up: assemble, link and clean temporary files
	pop rdi		; mode
	pop rsi		; outfile
	call _finish
ret
