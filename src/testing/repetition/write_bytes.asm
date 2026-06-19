global MOVAllBytesASM
global CMPAllBytesASM
global DECAllBytesASM
global NOP3x1AllBytesASM
global NOP1x3AllBytesASM
global NOP3x3AllBytesASM
global NOP1x9AllBytesASM

section .text

bits 64

MOVAllBytesASM:
	align 64
	xor   rax, rax

.loop:
	mov [rdi + rax], al
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

CMPAllBytesASM:
	align 64
	xor   rax, rax

.loop:
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

DECAllBytesASM:
	align 64

.loop:
	dec rsi
	jnz .loop
	ret

NOP3x1AllBytesASM:
	align 64
	xor   rax, rax

.loop:
	db  0x0f, 0x1f, 0x00; 3 byte noop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

NOP1x3AllBytesASM:
	align 64
	xor   rax, rax

.loop:
	nop
	nop
	nop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

NOP3x3AllBytesASM:
	align 64
	xor   rax, rax

.loop:
	db  0x0f, 0x1f, 0x00; 3 byte noop
	db  0x0f, 0x1f, 0x00; 3 byte noop
	db  0x0f, 0x1f, 0x00; 3 byte noop
	inc rax
	cmp rax, rsi
	jb  .loop
	ret

NOP1x9AllBytesASM:
	align 64
	xor   rax, rax

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

