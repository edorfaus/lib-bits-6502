; This table holds, for each byte value, the bitmask for the smallest
; number of bits that is necessary to represent that value.
BitmaskByValue:
	.byte 0
	.repeat 8, i
		.repeat 1 << i
			.byte (1 << (i+1)) - 1
		.endrepeat
	.endrepeat
