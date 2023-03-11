files := assfuck compile util error preprocess finish

all: ${files} link

.PHONY: assfuck
assfuck: assfuck.asm
	nasm -f elf64 assfuck.asm

compile: compile.asm
	nasm -f elf64 compile.asm

util: util.asm
	nasm -f elf64 util.asm

error: error.asm
	nasm -f elf64 error.asm

preprocess: preprocess.asm
	nasm -f elf64 preprocess.asm

finish: finish.asm
	nasm -f elf64 finish.asm

link: ${files}
	ld ${wildcard *.o} -o assfuck
