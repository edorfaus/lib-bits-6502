; This code snippet is a way to counteract the way a BRK skips the next
; byte when the interrupt returns. That also causes problems with some
; debuggers when trying to single-step over the BRK (not into the IRQ).
; It starts by checking if this interrupt was caused by a BRK, and if
; so, adjusts the return address, and otherwise does not do anything.

IRQ:
	pha
	txa
	pha

	tsx
.ifndef stackNeverUnderflows
	; This version of the code is designed to safely handle any stack
	; state, such that it will work even if the stack wrapped around
	; (underflowed from $0100 to $01FF) while handling the interrupt.

	inx ; to the stored X
	inx ; to the stored A
	inx ; to the stored flags
	lda $0100, x
	and #%0001_0000
	beq @notBRK

		; This is a BRK, so adjust the return address to be one earlier.
		inx ; to the low byte of the return address
		lda $0100, x
		bne :+
			inx ; to the high byte of the return address
			dec $0100, x
			dex
		:
		dec $0100, x

.else
	; This version of the code is designed for the (fairly common) case
	; where you can guarantee that such an underflow/wrap-around of the
	; stack pointer will never happen. It is simpler and faster, but
	; less safe in the case that something unexpected happens.

	lda $0103, x ; load the stored flags
	and #%0001_0000
	beq @notBRK

		; This is a BRK, so adjust the return address to be one earlier.
		lda $0104, x ; low byte of the return address
		bne :+
			dec $0105, x ; high byte of the return address
		:
		dec $0104, x
.endif
	@notBRK:

	pla
	tax
	pla
	rti
