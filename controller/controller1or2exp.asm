; This file contains code for reading the main NES/Famicom controllers
; and the expansion controllers, as if they were one controller.
;
; That is, both the first and second controller, and Famicom expansion
; controllers, and in such a way that it doesn't matter which one is
; used - pressing a button on any of them acts the same way. Obviously,
; this expects normal controllers (or compatible) on the expansion port.
;
; This does not attempt to handle DPCM DMA conflicts internally.

.segment "ZEROPAGE"

; ControllerPress holds bits for each button that was newly pressed in
; the latest reading (meaning it was not pressed in the previous one,
; but is pressed now).
ControllerPress: .res 1

; ControllerNow holds bits for each button that was held down in the
; latest reading, whether or not it was also held in earlier readings.
ControllerNow: .res 1

; ControllerPrevious holds the value that ControllerNow held before the
; latest reading. This is used internally to generate ControllerPress.
ControllerPrevious: .res 1

.segment "LIBCODE"

; Read the current value of the controller buttons.
; Updates: ControllerPress, ControllerNow, ControllerPrevious
; Clobbers: A, X
ControllerRead:
	; Strobe the controller shift register
	lda #%0000_0001
	sta Controller1
	lda #%0000_0000
	sta Controller1

	; Save the current values as the previous ones
	lda ControllerNow
	sta ControllerPrevious

	; Read the controllers
	ldx #8
	@readLoop:
		lda Controller1
		ora Controller2
		lsr a
		bcs :+
			lsr a
		:
		rol ControllerNow
	dex
	bne @readLoop

	; Update the Press bits
	lda ControllerPrevious
	eor #$FF
	and ControllerNow
	sta ControllerPress

	rts
