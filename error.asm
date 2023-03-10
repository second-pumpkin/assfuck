; _error prints an error message and exits

;     the error number is passed in by rax

section .rodata
	; error messages start with a byte showing their length
	error_generic db 24,"ERROR: undefined error: "
	unbalanced_brackets db 41,"ERROR: unbalanced brackets in input file",10
        unknown_input db 26,"ERROR: unknown input file",10
        access_denied db 25,"ERROR: permission denied",10
	unspecified_input db 32,"ERROR: input file not specified",10
	unspecified_output db 48,"ERROR: output file not specified. use -o [file]",10

	errors dq unbalanced_brackets, unknown_input, access_denied, unspecified_input, unspecified_output

section .bss
	error_num db 8 dup(?) ; buffer to print the error number in

section .text
global _error
extern _num_to_str

_error:
	xor rsi, rsi
	xor rbx, rbx
	
	; check the error number and set the error message depending on that
	cmp rax, -979
	cmove rsi, [errors]	; unbalanced brackets
	cmp rax, -2
	cmove rsi, [errors+8]	; unknown input
	cmp rax, -13
	cmove rsi, [errors+16]	; permission denied
	cmp rax, -999
	cmove rsi, [errors+24]	; unspefied input
	cmp rax, -1001
	cmove rsi, [errors+32]	; unspecified output
	
	; if rsi is still zero, set it to a generic error message and mark that
	cmp rsi, 0
	jne dont
	mov rsi, error_generic
	mov rbx, rax
	dont:

	; set the length of the error message
	xor rax, rax
	mov al, byte [rsi]
	mov rdx, rax
	inc rsi

	; syscall write
	mov rax, 1
	mov rdi, 1 ; stdout
	syscall

	; if the message was a gerneic error, print the error number as well
	cmp rbx, 0
	jns exit

	not rbx
	inc rbx
	
	mov rdi, rbx
	mov rsi, error_num
	call _num_to_str
	mov byte [rsi+rax-1], 10 ; newline imo
	
	mov rdx, rax
	mov rax, 1
	mov rdi, 1
	syscall

	exit:
	; syscall exit
	mov rax, 60
	mov rdi, 1
	syscall

