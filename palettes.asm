; mWritePalettes inserts code to write a number of palettes to the PPU,
; while avoiding the palette corruption issue.
; This should be done in vblank to avoid graphical glitches.
; The palette count is optional, and defaults to 8 (all palettes).
; Clobbers: A, X
.macro mWritePalettes paletteData, paletteCount
	.ifblank paletteCount
		mWritePalettes {paletteData}, 8
		.exitmacro
	.endif
	.if !.const(paletteCount)
		.error "palette count must be constant"
		.exitmacro
	.endif
	.if paletteCount < 1 || paletteCount > 8
		.local @c
		@c = paletteCount
		.error .sprintf("palette count range: %d is not in [1..8]", @c)
		.exitmacro
	.endif
	lda #$3F
	ldx #0
	bit PPUStatus
	sta PPUAddr
	stx PPUAddr
	:
		lda paletteData, x
		sta PPUData
		inx
		cpx #(4 * paletteCount)
	bne :-
	; To avoid palette corruption, ensure we end up at a mirror of $3F00
	; so that it's safe to change PPUAddr to something else.
	; See: https://www.nesdev.org/wiki/PPU_registers#Palette_corruption
	.if (4 * paletteCount) & $0F <> 0
		; We're not at a corruption-safe address, so move to one.
		lda #$3F
		sta PPUAddr
		lda #$00
		sta PPUAddr
	.endif
	; If I understand the workaround correctly, it should now be safe to
	; write any other address to PPUAddr.
.endmacro

.ifdef Palettes
; WritePalettes writes the full set of 8 palettes from Palettes.
; This should be done in vblank to avoid graphical glitches.
; Clobbers: A, X
WritePalettes:
	mWritePalettes Palettes, 8
	rts
.endif
