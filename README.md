### assfuck

a brainfuck compiler written in assembly. works for 64 bit x86 machines running linux.

dependencies:

- nasm

---

### usage:

basic usage:

```
assfuck input.bf -o output
```

parameters:

the memory space can be changed by editing the first line in the makefile. by default, it's 16KiB

command line arguments:

- `-o file`: specifies output file. required
- `-a`: output generated assembly
- `-j`: output an object file
- `-f func`: output an object file defining a function of name `func`. if -a isn't specified, this implies -j

---

### notes:

- I'm writing this to learn assembly, so I'm not really focused on writing a good compiler. right now, there are no optimizations (I'll make them soon though :3). for the same reason, I'm not using any external libraries in this program.

- hope you like it bestie <3
