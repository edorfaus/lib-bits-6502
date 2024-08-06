; This file contains functionality for reading the Family BASIC keyboard
; controller, and seeing not only which keys are held down, but which
; ones were newly pressed on the last call to FBKbdRead.
;
; This does not include an event buffer or autorepeat system, only the
; same kind of is-pressed functionality as for the regular controllers.
;
; Note that while this contains many comments which reference details of
; how Family BASIC reads the keyboard, this code was not copied from
; there - it was written separately based on documentation about the
; keyboard, and then afterwards the Family BASIC code was consulted for
; validation (since none of the hardware was on hand for testing). Even
; after that, any additions or adjustments were written separately, only
; based on whatever new information was found, not on copying the code.

.segment "ZEROPAGE"

; Temporary variable that is used internally. Its value does not need to
; be preserved between calls.
.ifndef TmpX
	TmpX: .res 1
.endif

; FBKbdPress holds the keys that are newly pressed, rather than held
; down since the previous read.
FBKbdPress: .res 9

; FBKbdNow holds the keys that are currently down, regardless of whether
; they were also held down on the previous read.
FBKbdNow:   .res 9

; FBKbdPrevious holds the keys that were down on the previous read,
; whether or not they are still held down now. This is used internally
; to update the FBKbdPress array.
FBKbdPrevious: .res 9

; FBKbdStatus holds a set of flags with the current keyboard status:
; Bit 0 is set if the keyboard was detected as being present.
; Bit 6 is set if there are any keys currently down (as per Now).
; Bit 7 is set if there are any keys down other than CTR or L/RSHIFT.
; (This is also used for temporary storage while inside of FBKbdRead.)
FBKbdStatus: .res 1

.segment "LIBCODE"

; If fbKeyboardDelayColumn1Read is non-zero, the FBKbdRead routine will
; wait between selecting column 1 and reading it, like Family BASIC
; does, instead of reading immediately. This is off by default because
; it is believed to not be necessary, but is provided in case it is.
; Enabling this will also invalidate the timing notes, taking more time.
.ifndef fbKeyboardDelayColumn1Read
	fbKeyboardDelayColumn1Read = 0
.endif

; FBKbdRead reads the current state of the keyboard controller.
; Updates: FBKbdPress, FBKbdNow, FBKbdPrevious, FBKbdStatus
; Clobbers: A, X, Y, TmpX
; Runs in 789 cycles if the keyboard is detected as present, otherwise
; it runs in 790 or 847 cycles, depending on how that was detected.
; This timing assumes that all the variables are in ZEROPAGE, that the
; code does not cross page boundaries, and includes the rts but not jsr.
; Otherwise it will take longer to run, but should still work.
FBKbdRead:
	lda #%0000_0101 ; reset keyboard to first row ; 2 cycles
	sta $4016       ; 4 cycles

	; Family BASIC waits 16 cycles between these two writes to $4016.
	; I'm not so sure that's needed, but do some work here in part to
	; somewhat match that, and in part to save having to do it later.
	; We end up at just 8 cycles between them, hopefully that's enough.

	; copy FBKbdNow to FBKbdPrevious, first byte (rest later)
	lda FBKbdNow+0      ; 3 cycles
	sta FBKbdPrevious+0 ; 3 cycles

	ldy #%0000_0100 ; column 0, next row unless just reset ; 2 cycles
	sty $4016       ; 4 cycles

	; Family BASIC waits 55 cycles between writing to $4016 and reading
	; from $4017, in a busy loop (so clearly just to wait for the kbd).
	; We instead spend that time by preparing variables for later use.

	; copy FBKbdNow to FBKbdPrevious (remaining 8 bytes of 9 total)
	.repeat 8, i
		lda FBKbdNow+1+i      ; 3 cycles
		sta FBKbdPrevious+1+i ; 3 cycles
	.endrepeat
	; 6 cycles times 8 is 48 cycles

	; set up the loop counter
	ldx #0   ; 2 cycles

@nextRow:
	stx TmpX ; 3 cycles

	ldx #%0000_0110 ; column 1, same row ; 2 cycles

	; At this point, there's been either 55 cycles from the initial
	; column-0 write above, or 55 cycles from the next-row write below.
	; This perfectly matches Family BASIC's waits between rows, while
	; spending the time doing useful work instead of just busy-looping.

	lda $4017 ; read column 0 : get 4 bits, xxxK_KKKx ; 4 cycles

	; Family BASIC does 11 cycles of work here, I do that later instead.

	stx $4016 ; switch to column 1 ; 4 cycles

	; Family BASIC waits another 55 cycles here. However, as long as the
	; problem capacitance isn't in the cable between the Famicom and the
	; keyboard, the circuit and datasheets suggest that's unnecessary.
	.if fbKeyboardDelayColumn1Read
		ldx #10 ; 2 cycles
		:
			dex ; 2 cycles
		bne :-  ; 3 or 2 cycles; (2+3)*x-1 total for the loop
		nop ; 2 cycles
		nop ; 2 cycles
		; total 2+(2+3)*10-1+2+2 = 55 cycles
	.endif

	ldx $4017 ; read column 1 : get 4 bits, xxxK_KKKx ; 4 cycles

	; Family BASIC does more work here, and then loops back up to do
	; another write,wait-loop,read process. I'm instead writing now
	; and then doing the work while waiting (instead of wasting cycles).

	sty $4016 ; advance to next row (and switch to column 0) ; 4 cycles

	; col 0 in A ; shift left 3 and mask, to put keys into high bits
	asl a ; 2 cycles each
	asl a
	asl a
	ora #$0F ; 2 cycles

	; col 1 in X; shift right 1 and mask, to put keys into low bits
	sta FBKbdStatus ; 3 cycles
	txa             ; 2 cycles
	lsr a           ; 2 cycles
	ora #$F0        ; 2 cycles

	; combine col 0 and 1, and invert (so 1 means key is pressed)
	and FBKbdStatus ; 3 cycles
	eor #$FF        ; 2 cycles

	; store in current keyboard state
	ldx TmpX        ; 3 cycles
	sta FBKbdNow, x ; 4 cycles

	; update the Press array, since we have to spend the time anyway.
	lda FBKbdPrevious, x ; 4 cycles
	eor #$FF             ; 2 cycles
	and FBKbdNow, x      ; 4 cycles
	sta FBKbdPress, x    ; 4 cycles

	; loop
	inx          ; 2 cycles
	cpx #9       ; 2 cycles
	bne @nextRow ; 3 cycles (2 on last)

	; At this point, 706 cycles have been spent. However, we also want
	; to detect whether the keyboard is actually connected, to avoid
	; spurious keypresses (and to allow the caller to make decisions).
	; To that end, we have already moved the keyboard to the 10th row,
	; and waited 49 cycles. Just 6 more to go before we can read safely.

	ldx #$00 ; 2 cycles
	nop      ; 2 cycles
	nop      ; 2 cycles

	lda $4017 ; 4 cycles
	stx $4016 ; turn off the matrix without moving col/row ; 4 cycles

	; I'm not sure if we need to wait for another 55 cycles here, to
	; read the next value, but we might - so we do so just to be safe.

	and #%0001_1110 ; 2 cycles
	cmp #%0001_1110 ; 2 cycles
	bne @noKeyboard ; 2 cycles, 3 if branch taken

	; Check if any key is down right now (to let others check quickly)
	lda FBKbdNow+7 ; 3 cycles
	asl a ; drop CTR bit, move LSHIFT to same bit as RSHIFT ; 2 cycles
	ora FBKbdNow+0 ; 3 cycles
	and #%1111_1101 ; mask out RSHIFT and LSHIFT ; 2 cycles
	.repeat 6, i
		ora FBKbdNow+1+i ; 3 cycles
	.endrepeat
	; 3 cycles times 6 is 18 cycles
	ora FBKbdNow+8 ; 3 cycles

	bne @haveKeys ; 2 or 3 cycles
		; we did not have any of those keys, now include CTR and SHIFT
		ora FBKbdNow+0 ; 3 cycles
		ora FBKbdNow+7 ; 3 cycles
		beq @haveNoKeys ; 2 or 3 cycles
			; we have those keys, so set the flag value accordingly
			; we spent 10 cycles getting here, need to spend 5 more
			ldy #%0100_0001 ; 2 cycles
			bne @haveKeysDone ; always branches ; 3 cycles
@haveKeys:
	; we have keys, so set the corresponding bits of the flag value
	; we spent 3 cycles getting here, need to spend 12 more
	rol FBKbdStatus ; long nop (since we're setting it below) ; 5 cycles
	nop ; 2 cycles
	ldy #%1100_0001 ; 2 cycles
	bne @haveKeysDone ; always branches ; 3 cycles
@haveNoKeys:
	; we did not have any keys, so only set the flag value for presence
	; we spent 11 cycles getting here, need to spend 4 more
	nop ; 2 cycles
	ldy #%0000_0001 ; 2 cycles
@haveKeysDone:
	; total 15 cycles for every path through the above branches

	sty FBKbdStatus ; set the flags to the right value ; 3 cycles

	; Now read again to verify that the keyboard was indeed present
	; (at least judging by it following the expected behavior).
	lda $4017       ; 4 cycles
	and #%0001_1110 ; 2 cycles
	bne @noKeyboard ; 2 cycles, 3 if branch taken

	; We have a keyboard, so we're done (we already set the variable).
	; At this point, we've spent 77 cycles after the loop, 783 total.

	rts ; 6 cycles

@noKeyboard:
	; We detected no keyboard is present, after either 21 or 78 cycles
	; after the loop.

	; clear the flags to say that the keyboard is not present
	stx FBKbdStatus ; 3 cycles

	; Clear the Press and Now arrays to remove any spurious keypresses.
	.repeat 9, i
		stx FBKbdPress+i ; 3 cycles
		stx FBKbdNow+i   ; 3 cycles
	.endrepeat
	; 9*6 = 54 cycles

	; At this point, we've spent 78 or 135 cycles after the main loop,
	; total 784 or 841 cycles.

	rts ; 6 cycles
