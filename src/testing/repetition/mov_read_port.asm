global MOV1x1AllBytesASM
global MOV1x2AllBytesASM
global MOV1x3AllBytesASM
global MOV1x4AllBytesASM
global MOV1x5AllBytesASM

section .text

bits 64

MOV1x1AllBytesASM:
	align 64

.loop:
	times 1 mov rax, [rdi]
	sub   rsi, 1
	jnle  .loop
	ret

MOV1x2AllBytesASM:
	align 64

.loop:
	times 2 mov rax, [rdi]
	sub   rsi, 2
	jnle  .loop
	ret

MOV1x3AllBytesASM:
	align 64

.loop:
	times 3 mov rax, [rdi]
	sub   rsi, 3
	jnle  .loop
	ret

MOV1x4AllBytesASM:
	align 64

.loop:
	times 4 mov rax, [rdi]
	sub   rsi, 4
	jnle  .loop
	ret


MOV1x5AllBytesASM:
	align 64

.loop:
	times 5 mov rax, [rdi]
	sub   rsi, 5
	jnle  .loop
	ret
