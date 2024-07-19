; This file creates names for various NES things, to make them easier to
; use. This includes things like PPU registers and sprite OAM offsets.
;
; Typically, this will be included very early, since other libs depend
; on it, and it doesn't actually take any space in the final ROM.

PPUCtrl   = $2000
PPUMask   = $2001
PPUStatus = $2002
PPUScroll = $2005
PPUAddr   = $2006
PPUData   = $2007

; OAMAddr and OAMDMA are used to trigger a DMA transfer to PPU OAM.
OAMAddr = $2003
OAMDMA  = $4014

; Sprite represents the layout of each entry in the OAM sprite metadata.
; See also: https://www.nesdev.org/wiki/PPU_OAM
.struct Sprite
	PosY .byte ; Y coordinate (in pixels) of the sprite, minus one.
	Tile .byte ; Tile index number of the sprite. (See wiki for 8x16.)
	Attr .byte ; Attributes: flip vert/horz, priority, palette index.
	PosX .byte ; X coordinate (in pixels) of the sprite.
.endstruct

APUPulse1DutyVol = $4000 ; DDLCVVVV
APUPulse1Sweep   = $4001 ; EPPPNSSS
APUPulse1TimerLo = $4002 ; LLLLLLLL
APUPulse1TimerHi = $4003 ; CCCCCHHH ; Write resets the phase (pop)

APUPulse2DutyVol = $4004 ; DDLCVVVV
APUPulse2Sweep   = $4005 ; EPPPNSSS
APUPulse2TimerLo = $4006 ; LLLLLLLL
APUPulse2TimerHi = $4007 ; CCCCCHHH ; Write resets the phase (pop)

APUTriangleLinCntr = $4008 ; CRRRRRRR
; There is no register at  $4009
APUTriangleTimerLo = $400A ; LLLLLLLL
APUTriangleTimerHi = $400B ; CCCCCHHH ; Write sets the reload flag

APUNoiseFlagsVol   = $400C ; --LCVVVV
; There is no register at  $400D
APUNoiseModePeriod = $400E ; M---PPPP
APUNoiseLenCntr    = $400F ; CCCCC--- ; Write restarts envelope

APUDMCFlagsRate  = $4010
APUDMCDirectLoad = $4011
APUDMCSampleAddr = $4012
APUDMCSampleLen  = $4013

; APU status/control (read/write)
; Read: IF-DNT21 : I = DMC interrupt, F = frame interrupt,
;     D = DMC active, N/T/2/1 = length ctr > 0 for that channel.
;     Reading clears the frame interrupt flag.
; Write: ---DNT21 : Enable DMC, Noise, Triangle, Pulse2, Pulse1 channel.
;     Writing clears the DMC interrupt flag.
APUStatusCtrl = $4015

; APU Frame Counter (write)
;     MI------ : Mode (0 = 4-step, 1 = 5-step), Inhibit IRQ
;     Writing resets the frame counter, and if the M bit is set, clocks
;     all of the controlled units immediately.
APUFrameCntr = $4017
