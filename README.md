### assfuck

a brainfuck compiler written in assembly. right now, it's in a very early stage. it's hard coded to compile the file at ./example.bf, and will output to ./example.asm. from there, you can use nasm to assemble the output.

since it's written in assembly, this program isn't portable. it only works for machines with a 64 bit x86 cpu running linux. you need nasm to assemble the program.

despite being a compiler, there is no compiler optimizations due the aforementioned very early stage the program is in. sorry :((
