global Read32x1AllBytesASM
global Read32x2AllBytesASM
global Read32x3AllBytesASM
global Read32x4AllBytesASM
global Read32x5AllBytesASM

global Read64x1AllBytesASM
global Read64x2AllBytesASM
global Read64x3AllBytesASM
global Read64x4AllBytesASM
global Read64x5AllBytesASM

global Read128x1AllBytesASM
global Read128x2AllBytesASM
global Read128x3AllBytesASM
global Read128x4AllBytesASM
global Read128x5AllBytesASM

global Read256x1AllBytesASM
global Read256x2AllBytesASM
global Read256x3AllBytesASM
global Read256x4AllBytesASM
global Read256x5AllBytesASM

section .text

bits 64

Read32x1AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8d, [rdi]

	add rax, 4
	cmp rax, rsi
	jb  .loop
	ret

Read32x2AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8d, [rdi]
	mov r8d, [rdi + 4]

	add rax, 8
	cmp rax, rsi
	jb  .loop
	ret

Read32x3AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8d, [rdi]
	mov r8d, [rdi + 4]
	mov r8d, [rdi + 8]

	add rax, 12
	cmp rax, rsi
	jb  .loop
	ret

Read32x4AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8d, [rdi]
	mov r8d, [rdi + 4]
	mov r8d, [rdi + 8]
	mov r8d, [rdi + 12]

	add rax, 16
	cmp rax, rsi
	jb  .loop
	ret

Read32x5AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8d, [rdi]
	mov r8d, [rdi + 4]
	mov r8d, [rdi + 8]
	mov r8d, [rdi + 12]
	mov r8d, [rdi + 16]

	add rax, 20
	cmp rax, rsi
	jb  .loop
	ret

Read64x1AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8, [rdi]

	add rax, 8
	cmp rax, rsi
	jb  .loop
	ret

Read64x2AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8, [rdi]
	mov r8, [rdi + 8]

	add rax, 16
	cmp rax, rsi
	jb  .loop
	ret

Read64x3AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8, [rdi]
	mov r8, [rdi + 8]
	mov r8, [rdi + 16]

	add rax, 24
	cmp rax, rsi
	jb  .loop
	ret

Read64x4AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8, [rdi]
	mov r8, [rdi + 8]
	mov r8, [rdi + 16]
	mov r8, [rdi + 24]

	add rax, 32
	cmp rax, rsi
	jb  .loop
	ret

Read64x5AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	mov r8, [rdi]
	mov r8, [rdi + 8]
	mov r8, [rdi + 16]
	mov r8, [rdi + 24]
	mov r8, [rdi + 32]

	add rax, 40
	cmp rax, rsi
	jb  .loop
	ret

Read128x1AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu xmm0, [rdi]

	add rax, 16
	cmp rax, rsi
	jb  .loop
	ret

Read128x2AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu xmm0, [rdi]
	vmovdqu xmm0, [rdi + 16]

	add rax, 32
	cmp rax, rsi
	jb  .loop
	ret

Read128x3AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu xmm0, [rdi]
	vmovdqu xmm0, [rdi + 16]
	vmovdqu xmm0, [rdi + 32]

	add rax, 48
	cmp rax, rsi
	jb  .loop
	ret

Read128x4AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu xmm0, [rdi]
	vmovdqu xmm0, [rdi + 16]
	vmovdqu xmm0, [rdi + 32]
	vmovdqu xmm0, [rdi + 48]

	add rax, 64
	cmp rax, rsi
	jb  .loop
	ret

Read128x5AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu xmm0, [rdi]
	vmovdqu xmm0, [rdi + 16]
	vmovdqu xmm0, [rdi + 32]
	vmovdqu xmm0, [rdi + 48]
	vmovdqu xmm0, [rdi + 64]

	add rax, 80
	cmp rax, rsi
	jb  .loop
	ret

Read256x1AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu ymm0, [rdi]

	add rax, 32
	cmp rax, rsi
	jb  .loop
	ret

Read256x2AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu ymm0, [rdi]
	vmovdqu ymm0, [rdi + 32]

	add rax, 64
	cmp rax, rsi
	jb  .loop
	ret

Read256x3AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu ymm0, [rdi]
	vmovdqu ymm0, [rdi + 32]
	vmovdqu ymm0, [rdi + 64]

	add rax, 96
	cmp rax, rsi
	jb  .loop
	ret

Read256x4AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu ymm0, [rdi]
	vmovdqu ymm0, [rdi + 32]
	vmovdqu ymm0, [rdi + 64]
	vmovdqu ymm0, [rdi + 96]

	add rax, 128
	cmp rax, rsi
	jb  .loop
	ret

Read256x5AllBytesASM:
	xor   rax, rax
	align 64

.loop:
	vmovdqu ymm0, [rdi]
	vmovdqu ymm0, [rdi + 32]
	vmovdqu ymm0, [rdi + 64]
	vmovdqu ymm0, [rdi + 96]
	vmovdqu ymm0, [rdi + 128]

	add rax, 160
	cmp rax, rsi
	jb  .loop
	ret
