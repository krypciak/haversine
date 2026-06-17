global MOVAllBytesASM
global CMPAllBytesASM
global DECAllBytesASM
global NOP3x1AllBytesASM
global NOP1x3AllBytesASM
global NOP3x3AllBytesASM
global NOP1x9AllBytesASM
global CondNOPAllBytesASM

section .text

bits 64

MOVAllBytesASM:
	xor rax, rax

.loop:
	mov [rdi + rax], al
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

CMPAllBytesASM:
	xor rax, rax

.loop:
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

DECAllBytesASM:
.loop:
	dec rsi
	jnz .loop
	ret

NOP3x1AllBytesASM:
	xor rax, rax

.loop:
	db  0x0f, 0x1f, 0x00; 3 byte noop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

NOP1x3AllBytesASM:
	xor rax, rax

.loop:
	nop
	nop
	nop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

NOP3x3AllBytesASM:
	xor rax, rax

.loop:
	db  0x0f, 0x1f, 0x00; 3 byte noop
	db  0x0f, 0x1f, 0x00; 3 byte noop
	db  0x0f, 0x1f, 0x00; 3 byte noop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

NOP1x9AllBytesASM:
	xor rax, rax

.loop:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

CondNOPAllBytesASM:
	xor rax, rax

.loop:
	mov r10, [rdi + rax]
	inc rax

	test r10, 1
	jnz  .skip
	nop

.skip:
	cmp rax, rsi
	jb  .loop
	ret
