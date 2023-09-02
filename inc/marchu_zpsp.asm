.scope	ZPSP

start:	
		LDX #(tst_tbl_end-tst_tbl-1)	; initialize the pointer to the table of values
		; LDX #$10			; start testing with value 0

; step 0; up - w0 - write the test value
marchU:	
		LDA tst_tbl,X	; get the test value into A

		LDY #$27		; write value at bottom of screen
	:	STA $07D0,Y
		DEY
		BPL :-

		TXS				; save the index of the test value into SP
		TAX				; save the test value into X
		; TXA				; copy the test value into A
		LDY #$00

marchU0:
		STA $00,Y		; w0 - write the test value
		STA $0100,Y		;    - also to stack page
		; STA $0700,Y		; also write to the screen
		INY				; count up
		BNE marchU0		; repeat until Y overflows back to zero

		; STY $00			; intentionally create an error for testing
; step 1; up - r0,w1,r1,w0
; A contains test value
marchU1:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR $0100,Y		; r0s - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		EOR $00,Y		; r1 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $0100,Y		; w1s - also stack page
		EOR $0100,Y		; r1s
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $00,Y		; w0 - write the test value to the memory location
		STA $0100,Y		; w0s - also stack page
		INY				; count up
		BNE marchU1		; repeat until Y overflows back to zero

; 100ms delay for finding bit rot
marchU1delay:
		delay_cycles 10000
		LDY #$00		; reset Y to 0

		TXA				; recover test value
; step 2; up - r0,w1
; A contains test value from prev step
marchU2:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR $0100,Y		; r0s  - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		STA $0100,Y		; w1s - also stack page
		EOR #$FF		; invert
		INY				; count up
		BNE marchU2		; repeat until Y overflows back to zero

; 100ms delay for finding bit rot
marchU2delay:
		delay_cycles 10000
		LDY #$FF		; reset Y to 0

		JMP continue

zp_bad:	JMP findbit

continue:
		TXA				; recover test value
		EOR #$FF		; invert
; step 3; down - r1,w0,r0,w1
marchU3:EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF
		EOR $0100,Y		; r1s - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		EOR $00,Y		; r0 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $0100,Y		; w0s - write the test value
		EOR $0100,Y		; r0s - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		STA $0100,Y		; w1s - also stack page
		DEY				; count down
		CPY #$FF		; did we wrap?
		BNE marchU3		; repeat until Y overflows back to FF

; step 4; down - r1,w0
; A contains the inverted test value from prev step
marchU4:EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		EOR $0100,Y		; r1s - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		STA $0100,Y		; w0s - also stack page
		EOR #$FF
		DEY				; count down
		CPY #$FF		; did we wrap?
		BNE marchU4		; repeat until Y overflows back to FF

		TSX				; recover the test value index from SP
		DEX				; choose the next one
		CPX #$FF		; see if we've wrapped
		; BNE marchup		; start again with next value
		BPL marchup		; start again with next value
		JMP zp_good

marchup:
		JMP marchU



; A contains the bits (as 1) that were found to be bad
; Y contains the address (offset) of the address where bad bit(s) were found
findbit:LDX #8			; start at high bit
		CLC				; clear carry
chkbit:	ROL				; move tested bit into carry
		BCS flasherr	; bit set, display it
		DEX				; count down
		BNE chkbit		; test next bit
wha:	JMP wha			; should not get here?


.proc flasherr			; time to flash the screen
		TXS  			; X is holding the bad bit, save it in the SP

		; XXX HACK: print the bank number on the bottom line
		; clear the bottom lines
		STA TXTSET		; text mode
		STA LOWSCR		; page 2 off

		; clear_text_screen
		inline_print bad_msg, $0750

		TSX					; get the bad bits mask from the sp
		TXA					; into A
		AND #$0F			; get low nybble
		TAY					; use it as an index
		LDA hex_tbl,Y		; into the hex table
		ORA #$80
		STA $0758			; TODO write low nybble to screen should set top bit to make it normal text

	flash_byte:
		STA TXTSET			; text mode
		LDX #$00			; a long pause at beginning and between flashes
        LDY #$00
		XYdelay 4
		TSX	
	flash_bit:
		STA TXTCLR 			; turn on graphics
		STA HIRES 			; set high res
		STA MIXSET			; mixed mode
		TXA					; save bit counter in A

		XYbeep $FF, $FF

		STA TXTSET			; text mode
		; TXA					; save bit counter in A

		LDX #$7F			; pause with low res on
        LDY #$00
		XYdelay 2

        TAX					; move bit counter back to X
        DEX 
		BNE flash_bit
		JMP flash_byte
.endproc

bad_msg:.asciiz "BAD BIT   "
	bad_msg_len = * - bad_msg

hex_tbl:.asciiz "0123456789ABCDEF"

zp_good:
		; lda #$08			; simulate error
		; jmp findbit			; simulate error
.endscope