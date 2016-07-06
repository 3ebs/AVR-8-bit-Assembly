;
; AssemblyCODES.asm
;
; Created: 7/4/2016 1:39:02 PM
; Author : Yousef
;

.LISTMAC

.EQU IO_offset = $20
.EQU bigLoopCounter = 255
.EQU smallLoopCounter = 255

.DSEG
	.ORG $0100
arr:
	.BYTE 15

.CSEG
	.ORG $0000
	jmp reset
	.ORG $0024
	jmp usart_rx

reset:
	.ORG $0026
arr1:
	.DB $59, $55, $59, $55, $2C, $49, $20, $4C, $6F, $76, $65, $20, $59, $6F, $75, $F0 ;"EARN,I Kill You" ;
	clr r31
	ldi r30, $4C
	clr r26
	ldi r27, $01
looop:
	lpm r0, z+
	cpi r30, $5C
	brsh exitthisloop
	st x+, r0
	rjmp looop
exitthisloop:
	;initialize USART
	ldi r23, $90
	sts $00C1, r23
	ldi r23, $06
	sts $00C2, r23
	clr r23
	sts $00C4, r23

.MACRO DelayLoop
	push @0
	push @1
	clr @0
bigLoop:
	cpi @0, bigLoopCounter
	brsh exitBigLoop
	clr @1
smallLoop:
	cpi @1, smallLoopCounter
	brsh exitSmallLoop
	inc @1
	rjmp smallLoop
exitSmallLoop:
	inc @0
	rjmp bigLoop
exitBigLoop:
	pop @1
	pop @0
.ENDMACRO

.MACRO sendCommandLCD
	out $25-IO_offset, @0
	sbi $28-IO_offset, 2
	cbi $28-IO_offset, 0
	DelayLoop @0, @1
	cbi $28-IO_offset, 2
	cbi $28-IO_offset, 0
	DelayLoop @0, @1
.ENDMACRO

.MACRO initializeLCD
	ldi @0, $38
	sendCommandLCD @0, r19
	DelayLoop @1, @2
	ldi @0, $01
	sendCommandLCD @0, r19
	DelayLoop @1, @2
	ldi @0, $0E
	sendCommandLCD @0, r19
	DelayLoop @1, @2
	ldi @0, $80
	sendCommandLCD @0, r19
	DelayLoop @1, @2
.ENDMACRO

.MACRO writeByteLCD
	out $25-IO_offset, @0
	sbi $28-IO_offset, 2
	sbi $28-IO_offset, 0
	DelayLoop @0, @1
	cbi $28-IO_offset, 2
	cbi $28-IO_offset, 0
	DelayLoop @0, @1
.ENDMACRO

.CSEG
	;ldi r16, LOW(RAMEND)
	;out spl, r16
	;ldi r16, HIGH(RAMEND)
	;out sph, r16
	ldi r16, $FF
	out $24-IO_offset, r16
	sbi $27-IO_offset, 0
	sbi $27-IO_offset, 1
	sbi $27-IO_offset, 2
	cbi $28-IO_offset, 1
	initializeLCD r30, r17, r18
;	clr r26
;	ldi r27, $01
;firstlineLoop:
;	ld r20, x+
;	cpi r26, $06
;	brsh exitfirstline
;	writeByteLCD r20, r17
;	rjmp firstlineLoop
;exitfirstline:
;	ldi r20, $C0	
;	sendCommandLCD r20, r19
;	ldi r26, $05
;secondlineLoop:
;	ld r20, x+
;	cpi r26, 16
;	brsh exitsecondline
;	writeByteLCD r20, r17
;	rjmp secondlineLoop	 
;exitsecondline:	
	sei
	clr r23
mainLOOP:
	cp r24, r23
	breq again
	writeByteLCD r20, r17	
	mov r23, r24
	rjmp mainLOOP
again:
	rjmp mainLOOP

usart_rx:
	lds r24, UDR0
	;out $25-IO_offset, r24
	reti
	
.EXIT