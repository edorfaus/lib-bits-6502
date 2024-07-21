.include "nmi-base.asm"

.segment "LIBCODE"

NMI:
	pha ; 3 cycles

	.ifdef Sprite0
		mTriggerSpriteDMA Sprite0 ; 526 cycles
	.endif

	; 2273 cycles in vblank; 3 or 529 cycles above, 32 cycles below;
	; that leaves 2238 or 1712 cycles here for updating the PPU state.

	; mNmiEndVblank updates PPUCtrl, PPUMask, PPUScroll, and nmiCounter.
	mNmiEndVblank ; 32 cycles (until end of vblank)

	pla
	rti
