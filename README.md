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

command line arguments:

- -o: specifies output file. required
- -a: output generated assembly
- -j: output an object file
- -f: specify the name of the function. if -a isn't specified elsewhere, this implies -j. this option can be used to call brainfuck routines from c:

(*hello_world.bf prints "hello world"*)

```
assfuck hello_world.bf -o hello_world.o -f hello
```

*caller.c*:

```c
extern void hello();

int main() {
	hello();
}
```

---

### notes:

hope you like it bestie <3
