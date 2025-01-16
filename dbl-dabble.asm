; This file implements the double-dabble algorithm for turning binary
; numbers into binary coded decimal (BCD), plus some algorithms for
; unpacking the resulting BCD into ASCII digits.
;
; This code is primarily targeted towards high speed rather than low
; size, but still tries to avoid wasting space for no good reason. Thus,
; we unroll the loops, but don't automatically use the fastest bcd2ascii
; code, because its rather small cycle gain has a pretty big data cost.

; Example usage, given appropriate variables BinaryNum and AsciiOut:
; BinNumToAscii:
;   mBinToBcd BinaryNum, AsciiOut
;   mBcdToAscii AsciiOut
;   rts
; ...
; jsr BinNumToAscii

; This macro is the main double-dabble algorithm, converting the binary
; number in bcdInput to packed BCD in half of bcdOutput. Only half of
; bcdOutput is used, on the assumption that you'll afterwards expand it
; into ASCII digits using one of the macros for that.
; Clobbers: A, X, bcdInput
.macro mBinToBcd bcdInput, bcdOutput
	.assert .sizeof(bcdInput) > 0, error, "invalid bcdInput"
	.assert .sizeof(bcdOutput) > 0, error, "invalid bcdOutput"

	.local @bcdScratchSize, @bcdScratch
	@bcdScratchSize = (.sizeof(bcdOutput) + 1) / 2
	; The scratch space is stored big-endian, because that allows the
	; conversion to ASCII to happen in-place without temporary storage.
	@bcdScratch = bcdOutput + @bcdScratchSize - 1

	; Unfortunately, the @bcdScratch<N> variables can't be made local,
	; since the .local keyword doesn't seem to work with .ident(...).

	lda #0
	.repeat @bcdScratchSize-1, i
		sta @bcdScratch-(i+1)
		.ident(.sprintf("@bcdScratch%d", i+1)) .set 0
	.endrepeat

	; First 3 shifts don't need an add-check, since >= 5 needs 3 bits.
	.repeat 3
		asl bcdInput+.sizeof(bcdInput)-1
		rol a
	.endrepeat
	@bcdScratch0 .set %0111

	.local @addCount, @shiftCount, @nextBit, @tmp, @firstByteInA
	@addCount .set 0
	@shiftCount .set 1
	@firstByteInA .set 1

	.repeat 8 * .sizeof(bcdInput) - 3, bit
		; This code essentially runs the algorithm on build-time, using
		; all 1-bits as input (on the assumption that hits the limits
		; as fast or faster than any other input). The results are used
		; to figure out when we need to start outputting code for each
		; byte of the output, so we can avoid wasting cycles.
		@nextBit .set 1
		.repeat @shiftCount, i
			@tmp .set .ident(.sprintf("@bcdScratch%d", i))

			.if @tmp >= $50
				@tmp .set @tmp + $30
			.endif
			.if (@tmp & $0F) >= $05
				@tmp .set @tmp + $03

				.if i >= @addCount
					@addCount .set i + 1
				.endif
			.endif

			@tmp .set (@tmp << 1) | @nextBit
			@nextBit .set @tmp >> 8
			@tmp .set @tmp & $FF

			.ident(.sprintf("@bcdScratch%d", i)) .set @tmp
		.endrepeat

		.if @nextBit > 0
			.ident(.sprintf("@bcdScratch%d", @shiftCount)) .set @nextBit
			@shiftCount .set @shiftCount + 1

			; Limit the byte count to the size of the scratch space.
			.if @shiftCount > @bcdScratchSize
				@shiftCount .set @bcdScratchSize
			.endif
		.endif

		; Build-time done for this bit, now generate the run-time code.

		asl bcdInput+.sizeof(bcdInput)-1-((bit + 3) / 8)

		.repeat @shiftCount, i
			.if @firstByteInA = 1 && i = 0
				tax
				lda bcdAdd3Table, x
				rol a
				.if @addCount > 1
					sta @bcdScratch-i
					@firstByteInA .set 0
				.endif
			.elseif i < @addCount
				ldx @bcdScratch-i
				lda bcdAdd3Table, x
				rol a
				sta @bcdScratch-i
			.else
				rol @bcdScratch-i
			.endif
		.endrepeat
	.endrepeat
	.if @firstByteInA = 1
		sta @bcdScratch-0
	.endif
.endmacro

; Expands the packed BCD into ASCII digits in a straightforward way.
; Clobbers: A
.macro mBcdToAscii bcdOutput
	.local @bcdScratchSize, @bcdScratch
	@bcdScratchSize = (.sizeof(bcdOutput) + 1) / 2
	@bcdScratch = bcdOutput + @bcdScratchSize - 1

	.repeat .sizeof(bcdOutput) / 2, i
		lda @bcdScratch-i
		and #$0F
		ora #'0'
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)

		lda @bcdScratch-i
		lsr a
		lsr a
		lsr a
		lsr a
		ora #'0'
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)-1
	.endrepeat
.endmacro

; Expands the packed BCD into ASCII digits using the MMC5's multiplier.
; Clobbers: A, MMC5 multiplier regs
.macro mBcdToAsciiMMC5 bcdOutput
	.local @bcdScratchSize, @bcdScratch, @mmc5_MultA, @mmc5_MultB
	@bcdScratchSize = (.sizeof(bcdOutput) + 1) / 2
	@bcdScratch = bcdOutput + @bcdScratchSize - 1
	@mmc5_MultA = $5205
	@mmc5_MultB = $5206

	lda #$10
	sta @mmc5_MultA

	.repeat .sizeof(bcdOutput) / 2, i
		lda @bcdScratch-i
		sta @mmc5_MultB

		and #$0F
		ora #'0'
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)

		lda @mmc5_MultB
		ora #'0'
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)-1
	.endrepeat
.endmacro

; Define the table if not already done. Used internally by the macros
; that need this table, which are rather data-heavy for little gain.
.macro _mSetup_BcdToAsciiTableHi
	.ifndef bcdAsciiTableHi
		.pushseg
		.segment "LIBDATA"
		.align $100
		bcdAsciiTableHi:
			.repeat 10, i
				.res 16, '0'+i
			.endrepeat
			; Crossing a page boundary will not cause failures, but
			; will cause the code to run slower.
			@ok = (.hibyte(*) = .hibyte(bcdAsciiTableHi))
			.assert @ok, warning, "bcdAsciiTableHi crosses pages"
		.popseg
	.endif
.endmacro

; Expands the packed BCD into ASCII digits using a big lookup table.
; Clobbers: A, X
.macro mBcdToAsciiTable bcdOutput
	.local @bcdScratchSize, @bcdScratch
	@bcdScratchSize = (.sizeof(bcdOutput) + 1) / 2
	@bcdScratch = bcdOutput + @bcdScratchSize - 1

	.repeat .sizeof(bcdOutput)/2, i
		lda @bcdScratch-i
		tax

		and #$0F
		ora #'0'
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)

		lda bcdAsciiTableHi, x
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)-1
	.endrepeat
	_mSetup_BcdToAsciiTableHi
.endmacro

; Expands the packed BCD into ASCII digits using two big lookup tables.
; Clobbers: A, X
.macro mBcdToAsciiTables bcdOutput
	.local @bcdScratchSize, @bcdScratch
	@bcdScratchSize = (.sizeof(bcdOutput) + 1) / 2
	@bcdScratch = bcdOutput + @bcdScratchSize - 1

	.repeat .sizeof(bcdOutput)/2, i
		ldx @bcdScratch-i

		lda bcdAsciiTableLo, x
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)

		lda bcdAsciiTableHi, x
		sta bcdOutput+.sizeof(bcdOutput)-1-(i*2)-1
	.endrepeat
	_mSetup_BcdToAsciiTableHi
	.ifndef bcdAsciiTableLo
		.pushseg
		.segment "LIBDATA"
		.align $100
		bcdAsciiTableLo:
			.repeat 10, h
				.if h > 0
					.res 16-10
				.endif
				.repeat 10, i
					.byte '0'+i
				.endrepeat
			.endrepeat
			; Crossing a page boundary will not cause failures, but
			; will cause the code to run slower.
			@ok = (.hibyte(*) = .hibyte(bcdAsciiTableLo))
			.assert @ok, warning, "bcdAsciiTableLo crosses pages"
		.popseg
	.endif
.endmacro

.segment "LIBDATA"

; This is a table of packed-BCD nibble pairs, where looking up a nibble
; pair will return a new nibble pair with 3 added to nibbles >= 5. It
; assumes valid input, that is, that each nibble is in the 0-9 range.
bcdAdd3Table:
	.repeat 10, high
		.if high > 0
			; Align the next elements to where they need to be.
			.res 16-10
		.endif
		; Boolean expressions return 1 if true, 0 if false.
		@high .set (high + (high >= 5) * 3) << 4
		.repeat 10, low
			.byte @high | (low + (low >= 5) * 3)
		.endrepeat
	.endrepeat

; The table crossing a page boundary will not cause anything to fail,
; but it will slow the algorithm down, so warn since we want max speed.
@hi = .hibyte(bcdAdd3Table)
.assert .hibyte(*) = @hi, warning, "bcdAdd3Table crosses page boundary"
