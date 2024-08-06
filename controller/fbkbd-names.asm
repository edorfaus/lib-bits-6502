; This file defines some optional constants and macros that can be
; useful when working with the Family BASIC keyboard controller.

; Define constants for every key, e.g. Key_A, Key_F3, Key_RETURN.
; Also define constants like Row_Key_A that says which byte of the
; input arrays that key is found in. (This is used by the IfKey macros.)
; These can be used when looking for a specific key in the input arrays.
.macro defineKey name, row, value
	.if .match({name}, "")
		.ident(.concat("Key_", name)) = value
		.ident(.concat("Row_Key_", name)) = row
	.else
		.ident(.concat("Key_", .string(name))) = value
		.ident(.concat("Row_Key_", .string(name))) = row
	.endif
.endmacro
.macro defineRow row, key7, key6, key5, key4, key3, key2, key1, key0
	defineKey key7, row, %1000_0000
	defineKey key6, row, %0100_0000
	defineKey key5, row, %0010_0000
	defineKey key4, row, %0001_0000
	defineKey key3, row, %0000_1000
	defineKey key2, row, %0000_0100
	defineKey key1, row, %0000_0010
	defineKey key0, row, %0000_0001
.endmacro

defineRow 0, RBRACKET, LBRACKET, RETURN, F8, STOP, YEN, RSHIFT, KANA
defineRow 1, SEMICOLON, COLON, AT, F7, HAT, MINUS, SLASH, UNDERSCORE
defineRow 2, K, L, O, F6, 0, P, COMMA, PERIOD
defineRow 3, J, U, I, F5, 8, 9, N, M
defineRow 4, H, G, "Y", F4, 6, 7, V, B
defineRow 5, D, R, T, F3, 4, 5, C, F
defineRow 6, "A", S, W, F2, 3, E, Z, "X"
defineRow 7, CTR, Q, ESC, F1, 2, 1, GRPH, LSHIFT
defineRow 8, LEFT, RIGHT, UP, CLR_HOME, INS, DEL, SPACE, DOWN

.delmacro defineRow
.delmacro defineKey

; mIfKey branches to the label if the key is active in the given array.
; Clobbers: A
; Examples:
;   mIfKey FBKbdNow, Key_A, the_A_key_is_pressed
;   mIfKey FBKbdPress, Key_F2, @pressed_F2_on_this_frame
;   mIfKey FBKbdPrevious, Key_RETURN, :+
.macro mIfKey array, key, label
	mLoadKey array, key
	bne label
.endmacro

; mIfNotKey branches to the label if the key is not active in the array.
; Clobbers: A
; Examples:
;   mIfNotKey FBKbdNow, Key_A, the_A_key_is_not_pressed
;   mIfNotKey FBKbdPress, Key_F2, @did_not_press_F2_on_this_frame
;   mIfNotKey FBKbdPrevious, Key_RETURN, :+
.macro mIfNotKey array, key, label
	mLoadKey array, key
	beq label
.endmacro

; mLoadKey loads into A whether the key is active in the array.
; It sets A to 0 if the key is not active, and to non-zero otherwise.
.macro mLoadKey array, key
	lda #key
	and array+.ident(.concat("Row_", .string(key)))
.endmacro

; mLoadShiftKeys combines the two shift keys; it sets A to 0 if neither
; key is active in array, and to non-zero otherwise. This is
; constant-time, and slightly faster than checking for both separately.
.macro mLoadShiftKeys array
	lda array+0
	lsr a
	ora array+7
	and #%0000_0001
.endmacro
