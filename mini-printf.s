.intel_syntax noprefix
.global _start

_start:
        mov rbp, rsp
        sub rsp, 256
        cmp byte ptr [rbp], 2
        jl exit
        mov rcx, [rbp+16]
        xor rdx, rdx
        mov r8, [rbp+16]
        mov r9, 1

count:
        cmp byte ptr [rcx], 0x00
        je write
        cmp byte ptr [rcx], 0x5c
        je escape
        cmp byte ptr [rcx], 0x25
        je format_marker
        inc rdx
        inc rcx
        jmp count

escape:
        inc rcx
        inc rdx
        cmp byte ptr [rcx], 'n'
        je newline
        cmp byte ptr [rcx], 0x5c
        je backslash
        cmp byte ptr [rcx], 'x'
        je hex_code

hex_code:
        xor rbx, rbx
        movzx rdi, byte ptr [rcx+1]
        call check_hex
        mov rsi, rdi
        movzx rdi, byte ptr [rcx+2]
        call check_hex
        shl rsi, 4
        or rsi, rdi
        mov byte ptr [rcx-1], sil
        call partial_write
        add rcx, 2
        mov r8, rcx
        jmp count

check_hex:
        sub dil, '0'
        cmp dil, 9
        ja capital
        ret

capital:
        add dil, '0'
        sub dil, 'A' - 10
        cmp dil, 0x0f
        ja small
        ret

small:
        add dil, 'A' - 10
        sub dil, 'a' - 10
        cmp dil, 0x0f
        ja exit
        ret

backslash:
        call partial_write
        jmp count

format_marker:
        inc rcx
        cmp byte ptr [rcx], 0x25
    je percent_escape
        cmp byte ptr [rcx], 'd'
        je decimal
        cmp byte ptr [rcx], 's'
        je string

string:
        call partial_write
        push rcx
        mov rdi, [rbp+r9*8+16]

str_len:
        cmp byte ptr [rdi], 0x00
        je str_write
        inc rdi
        inc rdx
        jmp str_len

str_write:
        mov rdi, 1
        mov rsi, [rbp+r9*8+16]
        mov rax, 1
        syscall
        pop rcx
        inc r9
        xor rdx, rdx
        jmp count

decimal:
        call partial_write
        mov rdi, [rbp+r9*8+16]
        mov rbx, rcx
        call atoi
        inc r9
        mov rdi, rax
        mov rsi, rsp
        call itoa
        mov rdi, 1
        mov rsi, rsp
        mov rdx, rax
        mov rax, 1
        syscall
        mov rcx, rbx
        xor rdx, rdx
        jmp count

percent_escape:
        inc rdx
        call partial_write
        jmp count

newline:
        mov byte ptr [rcx-1], 0x0a
        call partial_write
        jmp count

partial_write:
        push rcx
        mov rdi, 1
    mov rsi, r8
    mov rax, 1
    syscall
        pop rcx
        inc rcx
        mov r8, rcx
        xor rdx, rdx
        ret

write:
        mov rdi, 1
        mov rsi, r8
        mov rax, 1
        syscall

exit:
        add rsp, 256
        mov rax, 60
        xor rdi, rdi
        syscall

atoi_digit:
        movzx rax, byte ptr [rdi]
        sub rax, '0'
        ret

atoi:
        xor rcx, rcx
        cmp byte ptr [rdi], '-'
        je neg_atoi
        mov dl, byte ptr [rdi]
        sub dl, '0'
        cmp dl, 9
        ja pos_done

loop:
        call atoi_digit
        add rcx, rax
        inc rdi
        mov dl, byte ptr [rdi]
    sub dl, '0'
    cmp dl, 9
    ja pos_done
        imul rcx, 10
        jmp loop

neg_atoi:
        inc rdi

neg_loop:
    call atoi_digit
    add rcx, rax
    inc rdi
        mov dl, byte ptr [rdi]
    sub dl, '0'
    cmp dl, 9
    ja neg_done
    imul rcx, 10
    jmp neg_loop

pos_done:
        mov rax, rcx
        ret

neg_done:
        mov rax, rcx
        neg rax
        ret

itoa:
        mov rax, rdi
        mov rcx, 10
        mov rdi, 0
        cmp rax, 0
        jge push_loop
        push rdi
        mov byte ptr [rsi], '-'
        inc rsi
        inc rdi
        neg rax

push_loop:
        xor rdx, rdx
        div rcx
        add rdx, 0x30
        push rdx
        inc rdi
        cmp rax, 0
        je write_loop
        jmp push_loop

write_loop:
        cmp rax, rdi
        je done_itoa
        pop rdx
        mov [rsi], dl
        inc rsi
        inc rax
        jmp write_loop

done_itoa:
        ret