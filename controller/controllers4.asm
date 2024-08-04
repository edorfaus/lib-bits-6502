; This file contains code for reading both the main NES/Famicom
; controllers and expansion controllers, as 4 separate controllers.
;
; It reads the main controllers (D0 on each port) as controller 1 and 2,
; and the expansion controllers (D1 on each port) as controller 3 and 4.
;
; This does not attempt to handle DPCM DMA conflicts.

.segment "ZEROPAGE"

; ControllerPress holds bits for each button that was newly pressed in
; the latest reading (meaning it was not pressed in the previous one,
; but is pressed now). Four bytes, one for each controller.
ControllerPress: .res 4

; ControllerNow holds bits for each button that was held down in the
; latest reading, whether or not it was also held in earlier readings.
; There is one byte for each of the four controllers.
ControllerNow: .res 4

; ControllerPrevious holds the value that ControllerNow held before the
; latest reading. This is used internally to generate ControllerPress.
ControllerPrevious: .res 4

.segment "LIBCODE"

; Read the current value of the controller buttons.
; Updates: ControllerPress, ControllerNow, ControllerPrevious
; Clobbers: A, X
ControllerRead:
	; Save the current values as the previous ones
	ldx #.sizeof(ControllerNow)-1
	@previousLoop:
		lda ControllerNow, x
		sta ControllerPrevious, x

		dex
	bpl @previousLoop

	; Strobe the controller shift register; initialize ControllerNow
	lda #%0000_0001
	sta Controller1
	sta ControllerNow+3
	lda #%0000_0000
	sta Controller1

	; Read the controllers
	clc
	@readLoop:
		lda Controller1
		lsr a
		rol ControllerNow+0
		lsr a
		rol ControllerNow+2

		lda Controller2
		lsr a
		rol ControllerNow+1
		lsr a
		rol ControllerNow+3
	bcc @readLoop

	; Update the Press bits
	ldx #.sizeof(ControllerNow)-1
	@pressLoop:
		lda ControllerPrevious, x
		eor #$FF
		and ControllerNow, x
		sta ControllerPress, x

		dex
	bpl @pressLoop

	rts
