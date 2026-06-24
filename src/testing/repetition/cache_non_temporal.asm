global CacheNonTemporalRegular
global CacheNonTemporalNonTemporal

section .text

bits 64

CacheNonTemporalRegular:
	; rdi - dest_buffer
	; rsi - dest_buffer_size
	; rdx - read_buffer
	; rcx - read_buffer_size

	align 64

	;   r9 - dest_buffer pointer
	mov r9, rdi
	;   r10 - read_buffer index
	xor r10, r10

	;   convert rcx to mask
	sub rcx, 1

	;   rax - dest_buffer + dest_buffer_size
	mov rax, rdi
	add rax, rsi

.loop:
	mov r11, rdx
	add r11, r10

	vmovdqu ymm0, [r11 + 0x00]
	vmovdqu ymm1, [r11 + 0x20]

	vmovdqu [r9 + 0x00], ymm0
	vmovdqu [r9 + 0x20], ymm1

	add r10, 0x40
	and r10, rcx

	add r9, 0x40
	cmp r9, rax
	jb  .loop

	ret

CacheNonTemporalNonTemporal:
	; rdi - dest_buffer
	; rsi - dest_buffer_size
	; rdx - read_buffer
	; rcx - read_buffer_size

	align 64

	;   r9 - dest_buffer pointer
	mov r9, rdi
	;   r10 - read_buffer index
	xor r10, r10

	;   convert rcx to mask
	sub rcx, 1

	;   rax - dest_buffer + dest_buffer_size
	mov rax, rdi
	add rax, rsi

.loop:
	mov r11, rdx
	add r11, r10

	vmovdqu ymm0, [r11 + 0x00]
	vmovdqu ymm1, [r11 + 0x20]

	;        the only change is here
	vmovntdq [r9 + 0x00], ymm0
	vmovntdq [r9 + 0x20], ymm1

	add r10, 0x40
	and r10, rcx

	add r9, 0x40
	cmp r9, rax
	jb  .loop

	sfence
	ret
