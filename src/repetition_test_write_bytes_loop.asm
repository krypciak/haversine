global MOVAllBytesASM
global NOPAllBytesASM
global CMPAllBytesASM
global DECAllBytesASM

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

NOPAllBytesASM:
	xor rax, rax

.loop:
	db  0x0f, 0x1f, 0x00; 3 byte noop
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
