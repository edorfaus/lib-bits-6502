.segment "ZEROPAGE"

; Value to be put into PPUCtrl in NMI, after doing PPU updates.
nmiPPUCtrl: .res 1
; Value to be put into PPUMask in NMI, after doing PPU updates.
nmiPPUMask: .res 1
; Value for X to be put into PPUScroll in NMI, after doing PPU updates.
nmiScrollX: .res 1
; Value for Y to be put into PPUScroll in NMI, after doing PPU updates.
nmiScrollY: .res 1

; Counter that is incremented by NMI; used by WaitForNMI.
nmiCounter: .res 1

.segment "LIBCODE"

; Turns on NMI by setting the bit in nmiPPUCtrl and in the PPUCtrl reg.
; Clobbers: A
TurnOnNMI:
	lda nmiPPUCtrl
	ora #%1000_0000
	sta nmiPPUCtrl
	bit PPUStatus
	sta PPUCtrl
	rts

; WaitForNMI loops until NMI happens (as detected via nmiCounter).
; Clobbers: A
WaitForNMI:
	lda nmiCounter
	:
		cmp nmiCounter
	beq :-
	rts

; mTriggerSpriteDMA contains code to set OAMAddr and trigger OAM DMA.
; The first argument should be the address of the sprite buffer, which
; must be aligned to a page boundary for things to work correctly (as
; only the high byte of the address is actually used).
; The code takes 12 cycles, and OAM DMA takes another 513 or 514 cycles,
; for a total of 525 or 526 cycles.
; Clobbers: A
.macro mTriggerSpriteDMA spriteBuf
	; Update OAM using OAM DMA.
	lda #0
	sta OAMAddr
	.assert .lobyte(spriteBuf)=0, error, "sprite buffer is misaligned"
	lda #.hibyte(spriteBuf)
	sta OAMDMA
	; 2+4+2+4 = 12 cycles, then 513 or 514 cycles for the DMA itself.
.endmacro

; mNmiEndVblank contains the common NMI code for finishing PPU updates
; and moving into code that does not need to happen in vblank.
; It updates PPUCtrl, PPUMask and PPUScroll from their variables, and
; then increments nmiCounter.
; It needs to be able to spend at least 32 cycles before vblank ends,
; so must be placed at most 2273-32=2241 cycles after the start of NMI.
; Clobbers: A
.macro mNmiEndVblank
	; Set the base nametable address (aka course scroll) etc.
	lda nmiPPUCtrl
	bit PPUStatus
	sta PPUCtrl
	; 3+4+4 = 11 cycles

	; Set what to actually render (sprites/BG), color effects, etc.
	lda nmiPPUMask
	sta PPUMask
	; 3 + 4 = 7 cycles

	; Set the scroll position (last because it changes as a side-effect)
	lda nmiScrollX
	sta PPUScroll
	lda nmiScrollY
	sta PPUScroll
	; 3+4 + 3+4 = 14 cycles

	; At this point, we're no longer using the PPU, so we're not as
	; constrained on cycles (since we're no longer dependent on vblank).
	; 11 + 7 + 14 = 32 cycles

	; Update the NMI counter, in case someone's waiting for the NMI.
	inc nmiCounter
.endmacro
