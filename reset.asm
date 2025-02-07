.segment "LIBCODE"

RESET:
	; Start by making sure we're in a known state, and setting things up
	; the way we want them (at least to start with). Some of this is not
	; technically necessary at real power-on and reset, but allows code
	; to simulate a reset with "JMP ($FFFC)".

	; disable IRQs and decimal mode
	sei
	cld

	; These are the power-up/reset state of these registers, and the PPU
	; ignores these writes at power-up and reset. However, some consoles
	; don't reset the PPU, only the CPU, and this needs to be done then.
	ldx #$00
	stx PPUCtrl ; disable PPU NMI, various other settings
	stx PPUMask ; turn off all rendering, not grayscale, no emphasis

	; Reset the stack (set it to $FF)
	dex
	txs

	; Set X = 0
	inx

	; APU: inhibit IRQ, 4-step mode, reset frame counter
	ldy #%0100_0000
	sty APUFrameCntr
	; APU DMC: disable IRQs, no looping, rate index = 0
	stx APUDMCFlagsRate
	; APU: disable all audio channels, clear DMC interrupt flag
	stx APUStatusCtrl
	; APU: set DMC output value to 0 so it doesn't affect other volumes
	stx APUDMCDirectLoad

	; Clear the vblank flag, since it might be set spuriously.
	; Also resets the w latch to get address writes into a known state.
	bit PPUStatus

	; While we want to change the background to black as soon as we can,
	; trying to do so before the PPU is listening risks bus conflicts.

	; We need to wait for the PPU to stabilize; this is the first of the
	; two loops we use to do that. (This waits for vblank.)
	:
		bit PPUStatus
	bpl :-

	; Since power-on and reset move the PPU to the top of the frame, and
	; we just hit vblank, we should here have spent about 27384 cycles.
	; Since the PPU only starts listening after about 29658 CPU cycles,
	; we still need to spend a few more before we try using it.

	; Also, we want to jump to the main code at the start of vblank, so
	; we'll end up spending about 29780 cycles anyway.
	; We may as well spend what we can of them doing something useful.

	; Clear the internal main RAM. Conveniently, X is already 0.
	txa

	; We start by doing just the stack separately, because that spends
	; enough cycles that the PPU should have started listening to us.
	:
		sta $0100, x ; Stack
		inx
	bne :-
	; 2 + (5 + 2 + 3) * 256 - 1 = 2561 cycles
	; 27384 + 2561 = 29945 cycles, which is a little more than we need
	; (but I'd rather have that buffer instead of risking being short).

	; Now that the PPU should be listening to us, set the background
	; color to be black. It is acceptable that this may end up causing a
	; short graphical glitch (since we're in the visible frame area).
	stx PPUMask ; turn off all rendering, not grayscale, no emphasis
	; We avoid the palette corruption bug by enabling vertical writes.
	ldy #%0000_0100
	sty PPUCtrl ; Disable PPU NMI, vertical mode, various other settings
	ldy #$3F
	bit PPUStatus ; Reset the w latch, just is case
	sty PPUAddr
	stx PPUAddr
	sty PPUData
	stx PPUCtrl ; Turn vertical mode back off
	; 4 + 2+4 + 2 + 4 + 4+4+4 + 4 = 32 cycles

	; Now clear the rest of internal RAM.
	@clearRamLoop:
		sta $00, x   ; ZP
		;sta $0100, x ; Stack ; this is handled separately above
		sta $0200, x ; OAM buffer (in the default linker config)
		sta $0300, x
		sta $0400, x
		sta $0500, x
		sta $0600, x
		sta $0700, x

		; $0800 through $401F either do not need to be cleared, or are
		; better handled elsewhere. $4020 and up is cartridge space.

		inx
	bne @clearRamLoop
	; 2 + (4 + 5*6 + 2 + 3) * 256 - 1 = 9985 cycles
	; or, if the code straddles a page boundary, 10240 cycles

.ifdef Sprite0
	; Initialize the OAM buffer such that the sprites are off-screen,
	; and the other values have reasonable defaults.
	; Conveniently, A and X are already 0.
	clc
	:
		lda #$FF
		sta Sprite0+Sprite::PosY, x
		sta Sprite0+Sprite::PosX, x

		; As long as the OAM buffer is in internal RAM, this is not
		; necessary since it's already cleared above. However, doing it
		; anyway means it still works if OAM is moved to cartridge RAM,
		; and we have no reason to not spend the 768 cycles it takes.
		lda #$00
		sta Sprite0+Sprite::Tile, x
		; Attributes: not flipped, in front of BG, palette 4
		sta Sprite0+Sprite::Attr, x

		txa
		adc #4
		tax
	bne :-
	; 2 + (2+5+5 + 2+5+5 + 2+2+2 + 3)*(256/4)-1 = 2113 cycles
	; or, if the code straddles a page boundary, 2176 cycles
.endif

	; Total so far: 2561 + 32 + 9985 + 2113 = 14691 cycles,
	; or if straddling a page boundary, at most 14946 cycles,
	; since the first vblank was detected.

	; This loop, much like the first one, waits for vblank to happen.
	:
		bit PPUStatus
	bpl :-

	; We are now in vblank, with a stable PPU that will accept writes.

	; Jump to the main entry point of the program.
	jmp Main
