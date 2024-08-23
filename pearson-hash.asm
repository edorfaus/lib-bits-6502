; This file contains some implementations of Pearson hashing, which is a
; very simple, yet fairly good, non-cryptographic 8-bit hash, along with
; the lookup table the hash needs to function properly.
; See also: https://en.wikipedia.org/wiki/Pearson_hashing
;
; The algorithm boils down to this simple one-liner:
;     hash = 0; for (byte b in data) { hash = table[hash xor b] }
;
; Since purpose-built implementations can easily be better than generic
; ones for this, this file does not directly define any subroutines, but
; instead defines some macros that can be used to generate the code for
; hashing specific variables (or other data).
;
; There's also a macro for defining a more generic subroutine that uses
; an indirect data pointer instead of absolute addresses. While it would
; have been easier to include that routine directly, it is likely to not
; always be used, and would then just waste space in both ROM and ZP.
;
; Thus, the only thing this file always adds to the ROM is the lookup
; table (in LIBDATA), which is used by all the implementations.

; Macro for inline hashing of a specific variable that is fairly small.
; On exit, the hash is in A.
; Clobbers: X
.macro mPearsonHashSmall var
	lda #0
	.repeat .sizeof(var), i
		eor var+i
		tax
		lda PearsonHashLookup, x
	.endrepeat
.endmacro

; Macro for inline hashing of a specific variable that is a bit larger.
; On exit, the hash is in A.
; Clobbers: X, Y
.macro mPearsonHashLarge var
	lda #0
	tax
	:
		eor var, x
		tay
		lda PearsonHashLookup, y

		inx
		cpx #.sizeof(var)
	bne :-
.endmacro

; Macro for placing code to hash data pointed to by a given pointer.
; On entry, X must contain the number of bytes to be hashed, with the
; special case that 0 means 256 bytes.
; On exit, the hash is in A.
; Clobbers: X, Y, dataPtr
.macro mPearsonHashIndirect dataPtr
	lda #0

	@loop:
		ldy #0
		eor (dataPtr), y

		tay
		lda PearsonHashLookup, y

		inc dataPtr+0
		bne :+
			inc dataPtr+1
		:

		dex
	bne @loop
.endmacro

.segment "LIBDATA"

; The lookup table is a random permutation of the numbers 0-255. Pearson
; wrote that he has found very few constraints on it, just that it needs
; to be a permutation, and that T[i]=i would obviously be a bad hash.
; This table was generated with `shuf -i 0-255`, and then checked to
; verify that T[i] != i for all i, just in case it matters.
PearsonHashLookup:
	.byte 56, 47, 183, 165, 167, 143, 18, 251, 41, 135, 240, 245, 90
	.byte 124, 149, 250, 153, 174, 8, 175, 246, 69, 58, 196, 120, 36, 12
	.byte 82, 173, 159, 229, 116, 64, 170, 219, 105, 61, 182, 3, 232, 15
	.byte 98, 115, 17, 113, 74, 248, 32, 97, 95, 106, 154, 43, 111, 79
	.byte 184, 208, 176, 127, 71, 125, 57, 20, 202, 195, 237, 233, 11
	.byte 80, 186, 236, 109, 214, 10, 25, 85, 59, 201, 22, 140, 27, 104
	.byte 51, 138, 150, 203, 131, 157, 75, 4, 50, 179, 191, 151, 218, 44
	.byte 65, 247, 156, 144, 68, 137, 129, 244, 187, 147, 146, 84, 76
	.byte 55, 134, 193, 54, 1, 53, 224, 99, 30, 96, 91, 48, 152, 29, 0
	.byte 172, 100, 238, 132, 255, 119, 180, 13, 242, 161, 42, 254, 45
	.byte 21, 231, 188, 163, 212, 49, 166, 164, 46, 6, 234, 101, 199
	.byte 168, 145, 70, 139, 241, 162, 133, 217, 16, 228, 141, 88, 35
	.byte 239, 177, 31, 40, 81, 209, 226, 222, 227, 14, 39, 92, 200, 19
	.byte 112, 169, 220, 110, 37, 230, 252, 77, 108, 23, 243, 197, 123
	.byte 63, 94, 62, 225, 2, 213, 9, 190, 73, 185, 38, 211, 223, 5, 155
	.byte 28, 178, 33, 235, 89, 72, 117, 130, 83, 60, 160, 249, 189, 206
	.byte 142, 158, 205, 78, 221, 93, 198, 128, 52, 136, 210, 103, 86
	.byte 207, 114, 194, 118, 67, 171, 216, 192, 24, 181, 34, 126, 87
	.byte 121, 148, 102, 107, 253, 66, 215, 204, 122, 26, 7
