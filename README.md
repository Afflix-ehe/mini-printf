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

The program walks the format string byte by byte, tracking the start of the current unwritten segment (`r8`) and its length (`rdx`). When it hits a format specifier or escape sequence, it flushes the accumulated segment with a `partial_write`, handles the special case (escape substitution, argument formatting, etc.), then continues scanning. A final `write` syscall flushes whatever's left when the null terminator is reached.

Integer conversion is handled with hand-rolled `atoi` and `itoa` routines. Hex byte decoding resolves two ASCII hex digits into a single byte inline, writes it directly into the buffer, then flushes up to and including that byte before continuing.

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
