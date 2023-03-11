### assfuck

a brainfuck compiler written in assembly. right now, it's in a very early stage. it'll compile the program to assembly, but that's about it. when the program is compiled, you'll have to assemble/link it yourself.

since it's written in assembly, this program obviously isn't portable. it only works for machines with a 64 bit x86 cpu running linux.

despite being a compiler, there is no compiler optimizations due the aforementioned very early stage the program is in. sorry :((

---

dependencies:

- nasm

usage:

```bash
assfuck input.bf -o output.asm
```

notes:

hope you like it bestie <3
