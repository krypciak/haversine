global ReadStrided

section .text

bits 64

ReadStrided:
	; rdi - buffer
	; rsi - size (unused)
	; rdx - outer loop count
	; rcx - inner loop count
	; r8 - stride

	align 64

.outer_loop:
	mov r10, rcx
	mov rax, rdi

.inner_loop:
	vmovdqu ymm0, [rax]
	vmovdqu ymm0, [rax + 0x20]

	add rax, r8
	dec r10
	jnz .inner_loop

	dec rdx
	jnz .outer_loop

	ret
