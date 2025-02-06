; This file creates names for various MMC5 registers, to make them
; easier to use. This includes things like banking and audio registers.
;
; This file does not include names for the registers added by MMC5A.
;
; For more information, see: https://www.nesdev.org/wiki/MMC5

; MMC5 internal extended RAM (read/write)
; This points to the start of the internal extended RAM area, which is
; mapped to $5C00-$5FFF of the CPU address space.
; This RAM can have special behaviors, see MMC5ExtRAMMode.
MMC5ExtRAM = $5C00

; ----------------
; Operation modes
; ----------------

; MMC5 PRG banking mode (write)
;     ------MM : MM = banking mode
;     Modes: 0 = one 32K bank, 1 = two 16K banks,
;         2 = one 16K bank and two 8K banks, 3 = four 8K banks
;     This appears to reliably default to mode 3 at power-on.
MMC5PRGMode = $5100

; MMC5 CHR banking mode (write)
;     ------MM: MM = banking mode (0 = 8K, 1 = 4K, 2 = 2K, 3 = 1K)
MMC5CHRMode = $5101

; MMC5 PRG RAM write protect 1 (write)
;     ------ED: E = write enable, D = write disable
;     To enable writing to PRG RAM, set E = 1 and D = 0.
MMC5PRGWriteProtect1 = $5102

; MMC5 PRG RAM write protect 2 (write)
;     ------DE: D = write disable, E = write enable
;     To enable writing to PRG RAM, set D = 0 and E = 1.
MMC5PRGWriteProtect2 = $5103

; MMC5 internal extended RAM mode (write)
;     ------MM: MM = mode (0 = NT, 1 = ext-attr, 2 = CPU R/W, 3 = R/O)
; This controls both how the RAM is used and how it can be accessed by
; the CPU and PPU, with several subtleties. For more information, see:
; https://www.nesdev.org/wiki/MMC5#Internal_extended_RAM_mode_($5104)
MMC5ExtRAMMode = $5104

; ----------------
; PRG bankswitching (see also MMC5PRGMode above)
; ----------------

; MMC5 PRG bank 0 (write)
;     ----uaAA : PRG address lines A16-A13
;     The bit for A15 also selects between PRG RAM /CE 0 and 1, and no
;     official board used more than A13 and A14 as RAM address lines.
; This selects the RAM bank for the area mapped to $6000-$7FFF. Unlike
; the other PRG banks, this area can only be mapped to RAM, not to ROM.
MMC5PRGBank0 = $5113

; MMC5 PRG bank 1 (write)
;     RAAAAaAA : RAM/ROM select (0 = RAM, 1 = ROM), PRG A19-A13
;     The bit for A15 also selects between PRG RAM /CE 0 and 1, and no
;     official board used more than A13 and A14 as RAM address lines.
; In mode 3, this selects the bank for the area mapped to $8000-$9FFF.
; In all other modes, this register is ignored.
MMC5PRGBank1 = $5114

; MMC5 PRG bank 2 (write)
;     RAAAAaAA : RAM/ROM select (0 = RAM, 1 = ROM), PRG A19-A13
;     The bit for A15 also selects between PRG RAM /CE 0 and 1, and no
;     official board used more than A13 and A14 as RAM address lines.
; In mode 3, this selects the bank for the area mapped to $A000-$BFFF.
; In modes 1 and 2, this selects the bank for the area at $8000-$BFFF,
;     and bit 0 is ignored (A13 is instead controlled by the CPU's A13).
; In mode 0, this register is ignored.
MMC5PRGBank2 = $5115

; MMC5 PRG bank 3 (write)
;     RAAAAaAA : RAM/ROM select (0 = RAM, 1 = ROM), PRG A19-A13
;     The bit for A15 also selects between PRG RAM /CE 0 and 1, and no
;     official board used more than A13 and A14 as RAM address lines.
; In modes 2 and 3, this selects the bank for the area at $C000-$DFFF.
; In all other modes, this register is ignored.
MMC5PRGBank3 = $5116

; MMC5 PRG bank 4 (write)
;     -AAAAaAA : PRG address lines A19-A13
; In modes 2 and 3, this selects the bank for the area at $E000-$FFFF.
; In mode 1, this selects the bank for the area mapped to $C000-$FFFF,
;     and bit 0 is ignored (A13 is instead controlled by the CPU's A13).
; In mode 0, this selects the bank for the area mapped to $8000-$FFFF,
;     and bits 0 and 1 are ignored (A13-A14 are controlled by the CPU).
; Unlike the other PRG banks, this area can only map to ROM, not to RAM.
MMC5PRGBank4 = $5117

; ----------------
; CHR bankswitching (see also MMC5CHRMode above)
; ----------------

; MMC5 CHR upper bank bits (write)
;     ------BB : BB = upper bits for subsequent CHR bank writes
; In 1K and 2K modes, writes to the CHR bank registers also copy these
; bits in as the upper bits of the bank index, to access all 1024K CHR.
; In extended attribute mode, this register sets the upper bits for all
; the tile-specific bank values (probably globally, not per tile).
MMC5CHRUpperBank = $5130

; MMC5 CHR bank 0 (write)
; In 1K mode, this sets the bank index for $0000-$03FF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank0 = $5120

; MMC5 CHR bank 1 (write)
; In 1K mode, this sets the bank index for $0400-$07FF.
; In 2K mode, this sets the bank index for $0000-$07FF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank1 = $5121

; MMC5 CHR bank 2 (write)
; In 1K mode, this sets the bank index for $0800-$0BFF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank2 = $5122

; MMC5 CHR bank 3 (write)
; In 1K mode, this sets the bank index for $0C00-$0FFF.
; In 2K mode, this sets the bank index for $0800-$0FFF.
; In 4K mode, this sets the bank index for $0000-$0FFF.
; In 8K mode, this register is ignored.
; In 1K and 2K mode, the upper bits are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank3 = $5123

; MMC5 CHR bank 4 (write)
; In 1K mode, this sets the bank index for $1000-$13FF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank4 = $5124

; MMC5 CHR bank 5 (write)
; In 1K mode, this sets the bank index for $1400-$17FF.
; In 2K mode, this sets the bank index for $1000-$17FF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank5 = $5125

; MMC5 CHR bank 6 (write)
; In 1K mode, this sets the bank index for $1800-$1BFF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank6 = $5126

; MMC5 CHR bank 7 (write)
; In 1K mode, this sets the bank index for $1C00-$1FFF.
; In 2K mode, this sets the bank index for $1800-$1FFF.
; In 4K mode, this sets the bank index for $1000-$1FFF.
; In 8K mode, this sets the bank index for $0000-$1FFF.
; In 1K and 2K mode, the upper bits are taken from MMC5CHRUpperBank.
; In 8x16 sprite mode, this bank is only used for sprites, not BG, and
; writing to this register makes PPUData I/O use the sprite banks (0-7).
MMC5CHRBank7 = $5127

; MMC5 CHR bank 8 (write)
; In 8x8 sprite mode, this register is completely ignored.
; In 8x16 mode, it is only used for background tiles, not for sprites.
; In 1K mode, this sets the bank index for $0000-$03FF and $1000-$13FF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; Writing to this register makes PPUData I/O use the BG banks (8-B).
MMC5CHRBank8 = $5128

; MMC5 CHR bank 9 (write)
; In 8x8 sprite mode, this register is completely ignored.
; In 8x16 mode, it is only used for background tiles, not for sprites.
; In 1K mode, this sets the bank index for $0400-$07FF and $1400-$17FF.
; In 2K mode, this sets the bank index for $0000-$07FF and $1000-$17FF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; Writing to this register makes PPUData I/O use the BG banks (8-B).
MMC5CHRBank9 = $5129

; MMC5 CHR bank A (write)
; In 8x8 sprite mode, this register is completely ignored.
; In 8x16 mode, it is only used for background tiles, not for sprites.
; In 1K mode, this sets the bank index for $0800-$0BFF and $1800-$1BFF.
; In all other modes, this register is ignored.
; The upper bits of the bank index are taken from MMC5CHRUpperBank.
; Writing to this register makes PPUData I/O use the BG banks (8-B).
MMC5CHRBankA = $512A

; MMC5 CHR bank B (write)
; In 8x8 sprite mode, this register is completely ignored.
; In 8x16 mode, it is only used for background tiles, not for sprites.
; In 1K mode, this sets the bank index for $0C00-$0FFF and $1C00-$1FFF.
; In 2K mode, this sets the bank index for $0800-$0FFF and $1800-$1FFF.
; In 4K mode, this sets the bank index for $0000-$0FFF and $1000-$1FFF.
; In 8K mode, this sets the bank index for $0000-$1FFF.
; In 1K and 2K mode, the upper bits are taken from MMC5CHRUpperBank.
; Writing to this register makes PPUData I/O use the BG banks (8-B).
MMC5CHRBankB = $512B

; ----------------
; Various other functions
; ----------------

; MMC5 nametable mapping (write)
;     DDCCBBAA : AA/BB/CC/DD = mapping for NT at $2000/$2400/$2800/$2C00
;     Mapping values: 0 = CIRAM page 0, 1 = CIRAM page 1,
;         2 = internal extended RAM, 3 = fill-mode
MMC5NametableMap = $5105

; MMC5 fill-mode tile (write)
; This sets the tile index to use when a nametable is in fill mode.
MMC5FillModeTile = $5106

; MMC5 fill-mode color (write)
;     ------II : II = background palette index
; This sets the palette index to use when a nametable is in fill mode
; and extended attribute mode is not active.
MMC5FillModeColor = $5107

; MMC5 Vertical Split Mode (write)
;     ES-TTTTT : E = enable, S = screen side (0 = left, 1 = right),
;         T = threshold tile count
MMC5VertSplitMode = $5200

; MMC5 Vertical Split Scroll (write)
; This sets the vertical scroll value to use in the split region.
MMC5VertSplitScroll = $5201

; MMC5 Vertical Split Bank (write)
; This sets the 4K CHR bank to use (at both $0000-$0FFF and $1000-$1FFF)
; while rendering the split region.
MMC5VertSplitBank = $5202

; MMC5 scanline IRQ target scanline (write)
; This sets the scanline number at which to generate a scanline IRQ.
; Setting this to 0 will make it not generate a new IRQ (but will not
; clear an existing IRQ flag).
MMC5ScanlineIRQTarget = $5203

; MMC5 scanline IRQ status (read/write)
; Read: PF------ : P = IRQ Pending flag, F = "In Frame" flag
;     Reading will clear the IRQ Pending flag. F is set when the PPU is
;     rendering visible scanlines, and cleared when not (e.g. vblank).
; Write: E------- : E = Enable IRQ (1 = enabled)
MMC5ScanlineIRQStatus = $5204

; MMC5 Unsigned 8x8 to 16 Multiplier - low byte (read/write)
; Write: unsigned 8-bit multiplicand (one of the factors)
; Read: low byte of unsigned 16-bit product
MMC5MultA = $5205

; MMC5 Unsigned 8x8 to 16 Multiplier - high byte (read/write)
; Write: unsigned 8-bit multiplier (one of the factors)
; Read: high byte of unsigned 16-bit product
MMC5MultB = $5206

; ----------------
; Extra audio channels; see also: https://www.nesdev.org/wiki/MMC5_audio
; ----------------

MMC5Pulse1DutyVol = $5000 ; DDLCVVVV
; There is no register at $5001 (no sweep unit on this channel)
MMC5Pulse1TimerLo = $5002 ; LLLLLLLL
MMC5Pulse1TimerHi = $5003 ; CCCCCHHH ; Write resets the phase (pop)

MMC5Pulse2DutyVol = $5004 ; DDLCVVVV
; There is no register at $5005 (no sweep unit on this channel)
MMC5Pulse2TimerLo = $5006 ; LLLLLLLL
MMC5Pulse2TimerHi = $5007 ; CCCCCHHH ; Write resets the phase (pop)

; MMC5 pulse status/control (read/write)
; Read: ------21 : 2/1 = length ctr > 0 for pulse channel 2/1.
; Write: ------21 : 2/1 = Enable pulse channel 2/1.
MMC5PulseStatusCtrl = $5015

; MMC5 PCM Mode (read/write)
; Read: I------M : I = IRQ triggered, M = read-back of mode (unverified)
;     Reading clears the PCM IRQ flag.
; Write: I------M : I = PCM IRQ enabled, M = Mode (0 = write, 1 = read)
MMC5PCMMode = $5010

; MMC5 raw PCM value (write)
; Writes are ignored in read mode, and writing $00 does not change the
; output audio, but sets the IRQ flag (generating an IRQ if enabled).
MMC5PCMValue = $5011
