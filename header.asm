.include "nes2header.inc"

; The ID of the mapper being used. See the nesdev wiki for details.
nes2mapper 0
; PRG ROM size; must be a multiple of 16K; should be a power of 2.
nes2prg 2 * 16 * 1024
; CHR ROM size; must be a multiple of 8K; should be a power of 2.
nes2chr 1 * 8 * 1024
; Work RAM size (not battery-backed).
;nes2wram 1 * 8 * 1024
; PPU nametable mirroring: 'H' horizontal, 'V' vertical, '4' no mirror.
; ('4' is 4-way VRAM, 'V' is side-by-side screens, 'H' is above-below.)
nes2mirror 'V'
; The intended TV system: 'N' NTSC, 'P' PAL; or both if dual compat.
nes2tv 'N'

nes2end
