.include "m32def.inc"

; Develope a program that uses I/O ports and a timer/counter
; to display a message(numbers / text) on a 7-segment-display.
; ------------------------------------------------------------
; variant 			- 6
; cells number 		- 6
; indicator type 	- common anode
; direction         - to left
; cells port		- PA
; character port	- PC

.def tmp      = R16
.def sreg_tmp = R17
.def char     = R18
.def cell     = R19
.def count    = R20
.def cell_off = R21

.cseg 						; code segment
.org 0x00
	rjmp RESET

.org OC0addr				; Timer/Counter0 Compare Match
	rjmp TC0_CTC

TC0_CTC:
	in sreg_tmp, SREG
	out PORTA, cell_off
	lpm char, Z+
	out PORTC, char
	out PORTA, cell
	lsl cell
	cpi cell, 0x40
	breq GO_TO_NEXT
	rjmp END
GO_TO_NEXT:		
	ldi cell, 0x01
	movw ZH:ZL, XH:XL
	dec count
	brne END
	ldi count, 0x1e
	adiw XH:XL, 1
	cpi XL, low((CHARS_7_SEG_DISP << 1) | (1 << 4))
	ldi tmp, high((CHARS_7_SEG_DISP << 1) | (1 << 4))
	cpc XH, tmp
	brne END
	ldi XH, high((CHARS_7_SEG_DISP << 1))
	ldi XL, low((CHARS_7_SEG_DISP << 1))	 	
END:
	out SREG, sreg_tmp
	reti

RESET:
	; stack setup
	ldi tmp, high(RAMEND)
	out SPH, tmp
	ldi tmp, low(RAMEND)
	out SPL, tmp
	
	; PORTA (for cell) and PORTC (for character) setup
	ser tmp
	out DDRA,  tmp
	out DDRC,  tmp
	out PORTC, tmp
	clr tmp
	out PORTA, tmp
	
	
	cli 					; disable interrupts

	; timer/counter0 setup
	; mode       - ctc
	; prescaler  - ?
	; ocr0 (top) - ?
	;         |-----------mode----------|   |--------- prescaler - 256 ----------|
	ldi tmp, (1 << WGM01) | (0 << WGM00) | (1 << CS02) | (0 << CS01) | (0 << CS00) 
	out TCCR0, tmp
	ldi tmp, (1 << OCIE0) 	; enable Timer/Counter0 Output Compare Match Interrupt
	out TIMSK, tmp
	clr tmp
	out TCNT0, tmp			; set Timer/Counter to 0
	ldi tmp, 0x4e
	out OCR0, tmp			; set Output Compare Register to 78

	; load address of CHARS_7_SEG_DISP in Z reg
	ldi ZH, high((CHARS_7_SEG_DISP << 1))
	ldi ZL, low((CHARS_7_SEG_DISP << 1))
	; load address of CHARS_7_SEG_DISP in X reg
	ldi XH, high((CHARS_7_SEG_DISP << 1))
	ldi XL, low((CHARS_7_SEG_DISP << 1))
		
	ldi cell, 0x01
	ldi count, 0x1e
	ldi cell_off, 0x00

	sei 					; enable interrupts

MAIN:
	rjmp MAIN

.org 0x100
	;                      					  				   0     1     2     3     4     5     6     7     8     9
	CHARS_7_SEG_DISP: .db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xc0, 0xf9, 0xa4, 0xb0, 0x99, 0x92, 0x82, 0xd8, 0x80, 0x98

	; 0b11000000, ; 0
	; 0b11111001, ; 1
	; 0b10100100, ; 2
	; 0b10110000, ; 3
	; 0b10011001, ; 4
	; 0b10010010, ; 5
	; 0b10000010, ; 6
	; 0b11011000, ; 7
	; 0b10000000, ; 8
	; 0b10011000, ; 9
	; 0b11111111  ; off
