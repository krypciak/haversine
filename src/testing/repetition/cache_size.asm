global CacheSizeMeasure

section .text

bits 64

CacheSizeMeasure:
	; rdi - buffer
	; rsi - outer count
	; rdx - inner size

	align 64

	mov r9, rdi
	add r9, rdx

.outer_loop:
	mov rax, rdi

.inner_loop:
	vmovdqu ymm0, [rax]
	vmovdqu ymm1, [rax + 0x20]
	vmovdqu ymm2, [rax + 0x40]
	vmovdqu ymm3, [rax + 0x60]

	vmovdqu ymm0, [rax + 0x80]
	vmovdqu ymm1, [rax + 0xA0]
	vmovdqu ymm2, [rax + 0xC0]
	vmovdqu ymm3, [rax + 0xE0]

	add rax, 0x100
	cmp rax, r9
	jb  .inner_loop

	sub rsi, 1
	jnz .outer_loop

	ret
