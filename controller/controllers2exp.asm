; This file contains code for reading the main NES/Famicom controllers
; and the corresponding expansion controllers, as 2 separate controllers
; (allowing use of expansion controllers as replacements for the main
; controllers).
;
; In other words, this merges D0 and D1 from each controller port, to
; support both built-in and expansion controllers, but otherwise keeps
; the ports separate, to allow for 2 distinct players.
;
; This does not attempt to handle DPCM DMA conflicts.

.segment "ZEROPAGE"

; ControllerPress holds bits for each button that was newly pressed in
; the latest reading (meaning it was not pressed in the previous one,
; but is pressed now). Two bytes: controller 1, then controller 2.
ControllerPress: .res 2

; ControllerNow holds bits for each button that was held down in the
; latest reading, whether or not it was also held in earlier readings.
; The first byte is for controller 1, the second for controller 2.
ControllerNow: .res 2

; ControllerPrevious holds the value that ControllerNow held before the
; latest reading. This is used internally to generate ControllerPress.
ControllerPrevious: .res 2

.segment "LIBCODE"

; Read the current value of the controller buttons.
; Updates: ControllerPress, ControllerNow, ControllerPrevious
; Clobbers: A
ControllerRead:
	; Save the current values as the previous ones
	.repeat 2, i
		lda ControllerNow+i
		sta ControllerPrevious+i
	.endrepeat

	; Strobe the controller shift register; initialize ControllerNow
	lda #%0000_0001
	sta Controller1
	sta ControllerNow+1
	lda #%0000_0000
	sta Controller1
	sta ControllerNow+0

	; Read the controllers
	clc
	@readLoop:
		lda Controller1
		and #%0000_0011
		adc #$FF
		rol ControllerNow+0

		lda Controller2
		and #%0000_0011
		adc #$FF
		rol ControllerNow+1
	bcc @readLoop

	; Update the Press bits
	.repeat 2, i
		lda ControllerPrevious+i
		eor #$FF
		and ControllerNow+i
		sta ControllerPress+i
	.endrepeat

	rts
