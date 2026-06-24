global CachePrefetchNormal
global CachePrefetchPrefetch

section .text

bits 64

CachePrefetchNormal:
	; rdi - buffer
	; rsi - size
	; rdx - inner count

	align 64

	mov rax, rdi

.outer_loop:
	vmovdqa ymm0, [rax]
	vmovdqa ymm1, [rax + 0x20]

	mov rax, [rax]

	mov r9, rdx

.inner_loop:
	vpxor  ymm0, ymm1
	vpaddd ymm0, ymm1

	dec r9
	jnz .inner_loop

	sub  rsi, 0x40
	jnle .outer_loop

	ret

CachePrefetchPrefetch:
	; rdi - buffer
	; rsi - size
	; rdx - inner count

	align 64

	mov rax, rdi

.outer_loop:
	vmovdqa ymm0, [rax]
	vmovdqa ymm1, [rax + 0x20]

	mov rax, [rax]

	prefetcht0 [rax]

	mov r9, rdx

.inner_loop:
	vpxor  ymm0, ymm1
	vpaddd ymm0, ymm1

	dec r9
	jnz .inner_loop

	sub  rsi, 0x40
	jnle .outer_loop

	ret
