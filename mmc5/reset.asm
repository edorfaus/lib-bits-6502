; This code tries to initialize the MMC5 to a known good state.
;
; It is intended as a starting point, something to copy and modify,
; rather than as something to keep as-is. Currently, the result should
; resemble NROM enough that it can (mostly) be used as such.
;
; It does not try to clear or initialize everything, only the most
; significant parts - e.g. it disables the IRQs, but does not clear the
; corresponding IRQ flags, expecting anyone using it to clear it first.
;
; Some of this code is completely unnecessary at power-on, and probably
; at a hardware reset, but may help for software resets ("JMP ($FFFC)"),
; or just as a way of documenting (via code) what is expected.
;
; Some of it is risky, in that it changes the banking setup from under
; itself, and thus makes assumptions about the state of the system.
;
; Clobbers: A, X
MMC5Reset:
	lda #0

	; MMC5 PRG RAM write protect: disable writing to it
	sta MMC5PRGWriteProtect1
	sta MMC5PRGWriteProtect2

	; MMC5 internal extended RAM mode: use mode 0 (seems to be default)
	sta MMC5ExtRAMMode

	; WARNING: the following section makes assumptions that, if wrong,
	; can cause this code to be unmapped while it is executing.
	; MMC5 PRG banking: set high area to $FF, like at power-up
	ldx #$FF
	stx MMC5PRGBank4
	; MMC5 PRG banking: set the other areas to decreasing ROM banks
	dex
	stx MMC5PRGBank3
	dex
	stx MMC5PRGBank2
	dex
	stx MMC5PRGBank1
	; MMC5 PRG banking: set mode 3 (8K banks), like at power-up. This is
	; done after the above, as this way seems a little bit safer.
	ldx #3
	stx MMC5PRGBankMode

	; MMC5 PRG banking: set RAM area to first RAM bank
	sta MMC5PRGBank0

	; MMC5 scanline IRQ: disable IRQs
	sta MMC5ScanlineIRQStatus
	; MMC5 scanline IRQ: target scanline = 0 so it will not set the flag
	sta MMC5ScanlineIRQTarget

	; MMC5 audio: PCM mode: IRQ disabled, write mode
	sta MMC5PCMMode
	; MMC5 audio: Pulse channels off
	sta MMC5PulseStatusCtrl

	; MMC5 Vertical Split Mode: disabled
	sta MMC5VertSplitMode

	; MMC5 nametable mapping: vertical mirroring using CIRAM
	ldx #$44 ; 01, 00, 01, 00
	stx MMC5NametableMap

	; MMC5 CHR banking mode: 8K banks (as a simple but decent default)
	sta MMC5CHRBankMode
	; MMC5 upper CHR bank bits: use the first bank
	sta MMC5CHRUpperBank
	; MMC5 CHR banking: in 8K mode only these two registers matter
	sta MMC5CHRBankB
	sta MMC5CHRBank7

	rts
