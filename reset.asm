.segment "LIBCODE"

RESET:
	; Start by making sure we're in a known state, and setting things up
	; the way we want them (at least to start with). Some of this is not
	; technically necessary at real power-on and reset, but allows code
	; to simulate a reset with "JMP ($FFFC)".

	; disable IRQs and decimal mode
	sei
	cld

	; APU: inhibit IRQ, 4-step mode, reset frame counter
	ldx #%0100_0000
	stx APUFrameCntr

	; Reset the stack
	ldx #$FF
	txs

	; Set X = 0
	inx

	; APU DMC: disable IRQs, no looping, rate index = 0
	stx APUDMCFlagsRate
	; APU: disable all audio channels, clear DMC interrupt flag
	stx APUStatusCtrl
	; APU: set DMC output value to 0 so it doesn't affect other volumes
	stx APUDMCDirectLoad

	; These are the power-up/reset state of these registers, and the PPU
	; ignores these writes at power-up and (only sometimes) at reset,
	; but this makes sure in case we got here some other way.
	stx PPUCtrl ; disable PPU NMI, various other settings
	stx PPUMask ; turn off all rendering, not grayscale, no emphasis

	; Clear the vblank flag, since it might be set spuriously.
	; Also resets the w latch to get address writes into a known state.
	bit PPUStatus

	; We want to make the screen black as soon as possible, which means
	; we have to set the background color to black. However, the PPU may
	; (or may not) ignore this until about a frame has passed, something
	; we here work around by re-doing the writes several times. It is
	; acceptable that this may end up causing a short graphical glitch.
	; We avoid the palette corruption bug by enabling vertical writes.
	ldy #%0000_0100
	sty PPUCtrl ; Disable PPU NMI, vertical mode, various other settings
	stx PPUMask ; turn off all rendering, not grayscale, no emphasis
	ldy #$3F
	sty PPUAddr
	stx PPUAddr
	sty PPUData

	; We need to wait for the PPU to stabilize; this is the first of the
	; two loops we use to do that. (This waits for vblank.)
	:
		bit PPUStatus
	bpl :-

	; We know there's about 29780 cycles in each frame, so we have
	; about that many cycles to wait before we know the PPU is stable.
	; We may as well spend what we can of them doing something useful.

	; Clear the internal main RAM. Conveniently, X is already 0.
	txa
	@clearRamLoop:
		; As above, just in case we now can, try to set the BG to black.
		ldy #%0000_0100
		sty PPUCtrl
		sta PPUMask
		ldy #$3F
		bit PPUStatus ; reset the w latch, in case it got out of sync.
		sty PPUAddr
		sta PPUAddr
		sty PPUData
		; 2+4+4 + 2+4+4+4+4 = 28 cycles

		sta $00, x   ; ZP
		sta $0100, x ; Stack
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
	; 2 + (28 + 4 + 5*7 + 2 + 3)*256 - 1 = 18433 cycles
	; or, if the code straddles a page boundary, 18689 cycles

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

	; This is the second loop to wait for the PPU to have stabilized.
	:
		bit PPUStatus
	bpl :-

	; We are now in vblank, with a stable PPU that will accept writes.

	; Ensure that these are zero, as we changed them earlier.
	stx PPUCtrl
	stx PPUMask

	; We don't retry setting the BG here because the main code will
	; probably be setting the actually wanted palette soon anyway.

	; Jump to the main entry point of the program.
	jmp Main
