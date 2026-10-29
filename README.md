# mini-printf

A from-scratch implementation of `printf` in x86-64 assembly — no libc, no helpers, just syscalls.

Built incrementally on [pwn.college](https://pwn.college), working through each feature one challenge at a time: literal output, newline escapes, escaped syntax characters, decimal markers, multiple format arguments, string markers, and finally arbitrary hex byte escapes.

## Features

- Literal text output
- `\n` — newline escape
- `\\` — escaped backslash
- `\xNN` — arbitrary hex byte output
- `%d` — signed decimal integer
- `%s` — string argument
- `%%` — literal percent sign
- Multiple format arguments in a single format string
- No libc dependency — raw `write` syscalls throughout

## How it works

### Argument layout

On Linux x86-64, when a program starts, the stack looks like this:

```
[rsp]      argc
[rsp+8]    argv[0]   ← program name
[rsp+16]   argv[1]   ← format string
[rsp+24]   argv[2]   ← first format argument
...
```

`mini-printf` reads directly off the stack — no function call overhead, no libc `main`. `rbp` is saved as the original `rsp` so arguments are accessed as `[rbp+16]` (format string), `[rbp+24]` (first arg), etc. `r9` tracks which argument is next, incrementing each time a `%d` or `%s` is consumed.

### The scan loop

Rather than copying the format string or building an output buffer, the implementation scans in place and writes segments of the original string directly. Two registers track state:

- `r8` — pointer to the start of the current unwritten segment
- `rdx` — byte count of that segment

The main loop (`count`) walks `rcx` forward byte by byte. On a normal character it just increments both `rcx` and `rdx`. The moment it hits `\` or `%`, it branches to handle the special case — but before doing anything, it first flushes whatever plain text has accumulated since the last flush via `partial_write`.

### partial_write

`partial_write` issues a `write(1, r8, rdx)` syscall to flush the current segment, then resets `r8` to point just past the character that triggered the flush and zeroes `rdx`. This is what makes the whole architecture work without an intermediate buffer — segments of the format string are written verbatim, and only the escape/format characters need special handling.

### Escape sequences

For `\n`, the byte at `rcx-1` (the backslash position) is overwritten in place with `0x0a`, then `partial_write` flushes that single byte. For `\\`, `partial_write` flushes just the backslash. For `\xNN`, two hex digit characters are decoded into a single byte value, written into the buffer at `rcx-1`, flushed, and then `rcx` skips past the two hex digits before the scan continues.

Hex digit decoding (`check_hex`) handles `0-9`, `A-F`, and `a-f` by subtracting the appropriate ASCII base to get a 0–15 value. The two nibbles are combined with a 4-bit left shift and `or` to produce the final byte.

### Integer formatting

`%d` pulls the next argument off the stack as a raw string (since all argv entries are strings), converts it to an integer with `atoi`, then converts back to a decimal string with `itoa` for output.

`atoi` walks the digit characters, accumulating into `rcx` with `imul`/`add`. Negative numbers are handled by checking for a leading `-`, running the same loop, and negating the result at the end.

`itoa` works by repeated division by 10 — each remainder gives a digit, pushed onto the stack in reverse order, then popped off and written into the output buffer in the right order. The digit count in `rdi` drives the write loop so it knows exactly how many digits to pop.

## Build & Run

```bash
make
./mini-printf "Hello, \x57orld\n%d bottles of %s\n" 99 "beer"
```

## Requirements

- x86-64 Linux
- `gcc` (for the assembler/linker via `as` and `ld`, or use `gcc` directly)
- `make`

## Files

```
mini-printf.s   — the implementation
Makefile        — build config
README.md       — this file
```
