; This file contains code for reading the main NES/Famicom controller.
;
; That is, only the first controller, and no expansion controllers.
; In other words, the second controller is ignored completely.
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
; Clobbers: A
ControllerRead:
	; Save the current values as the previous ones
	lda ControllerNow
	sta ControllerPrevious

	; Strobe the controller shift register; initialize ControllerNow
	lda #%0000_0001
	sta Controller1
	sta ControllerNow
	lda #%0000_0000
	sta Controller1

	; Read the controllers
	clc
	@readLoop:
		lda Controller1
		lsr a
		rol ControllerNow
	bcc @readLoop

	; Update the Press bits
	lda ControllerPrevious
	eor #$FF
	and ControllerNow
	sta ControllerPress

	rts
