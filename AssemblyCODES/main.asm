;
; AssemblyCODES.asm
;
; Created: 7/4/2016 1:39:02 PM
; Author : Yousef
;

.DEVICE ATMEGA328P
.LISTMAC



.EQU IO_offset = $20
.EQU bigLoopCounter = 255
.EQU smallLoopCounter = 255

.DSEG
	.ORG $0100
arr:
	.BYTE 15

.CSEG	;interrupt vector table using JMP instruction
	.ORG $0000
		jmp reset
		nop ;INT0
		nop
		nop ;INT1
		nop
		nop ;PCINT0
		nop
		nop ;PCINT1
		nop
		nop ;PCINT2
		nop
		nop ;WDT
		nop
		nop ;TIMER2 COMPA
		nop
		nop ;TIMER2 COMPB
		nop
		nop ;TIMER2 OVF
		nop
		nop ;TIMER1 CAPT
		nop
		nop ;TIMER1 COMPA
		nop
		nop ;TIMER1 COMPB
		nop
		nop ;TIMER1 OVF
		nop
		nop ;TIMER0 COMPA
		nop
		nop ;TIMER0 COMPB
		nop
		jmp timer0_ovf
		nop ;SPI
		nop
		jmp usart_rx
		nop ;USART UDRE
		nop
		nop ;USART TX
		nop 
		nop ;ADC
		nop 
		nop ;EE READY
		nop 
		nop ;ANALOG COMP
		nop 
		jmp twi
		nop ;SPM READY
		nop 

reset:
	.ORG $0034
arr1:
	.DB $45, $41, $52, $4E, $2C, $49, $20, $4B, $69, $6C, $6C, $20, $59, $6F, $75, $F0 ;"EARN,I Kill You" ;
	clr r31
	ldi r30, $68
	clr r26
	ldi r27, $01
	sei
looop:
	lpm r0, z+
	cpi r30, $78
	brsh exitthisloop
	st x+, r0
	rjmp looop
exitthisloop:
	;initialize USART
	clr r23
	sts $00C0, r23
	ldi r23, $90
	sts $00C1, r23
	ldi r23, $06
	sts $00C2, r23
	clr r23
	sts UBRR0H, r23
	ldi r23, 6
	sts UBRR0L, r23
	;initialize timer 0 Fast-PWM
	sbi $2A-IO_offset, 6
	ldi r23, $83
	out $24, r23
	ldi r23, $05
	out $25, r23
	ldi r23, 128
	out $27, r23
	ldi r23, $01
	sts $6E, r23
	clr r29
	;initialize I2C
	ldi r23, $02
	sts $B8, r23
	clr r23
	sts $BC, r23

.MACRO start
	ldi r23, (1 << TWINT)|(1 << TWSTA)|(1 << TWEN)|(1 << TWIE)
	sts $BC, r23
.ENDMACRO

.MACRO ack
	ldi r23, (1<<TWINT)|(1<<TWEA)|(1<<TWEN)|(1<<TWIE))
	sts $BC, r23
.ENDMACRO

.MACRO pd
	ldi r23, (1<<TWINT)|(1<<TWEN)|(1<<TWIE)
	sts $BC, r23
.ENDMACRO

.MACRO nack
	ldi r23, ((1<<TWINT)|(1<<TWEN)|(1<<TWIE))&(~(1<<TWEA)))
	sts $BC, r23
.ENDMACRO

.MACRO stop
	ldi r23, (1 << TWINT)|(1 << TWSTO)|(1 << TWEN)|(1 << TWIE)
	sts $BC, r23
.ENDMACRO

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
	DelayLoop @0, r19
	cbi $28-IO_offset, 2
	cbi $28-IO_offset, 0
	DelayLoop @0, r19
.ENDMACRO

.MACRO initializeLCD
	ldi @0, $38
	sendCommandLCD @0
	DelayLoop r17, r18
	ldi @0, $01
	sendCommandLCD @0, r19
	DelayLoop r17, r18
	ldi @0, $0E
	sendCommandLCD @0, r19
	DelayLoop r17, r18
	ldi @0, $80
	sendCommandLCD @0, r19
	DelayLoop r17, r18
.ENDMACRO

.MACRO writeByteLCD
	out $25-IO_offset, @0
	sbi $28-IO_offset, 2
	sbi $28-IO_offset, 0
	DelayLoop @0, r17
	cbi $28-IO_offset, 2
	cbi $28-IO_offset, 0
	DelayLoop @0, r17
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
	initializeLCD r30
	clr r26
	ldi r27, $01
firstlineLoop:
	ld r20, x+
	cpi r26, $06
	brsh exitfirstline
	writeByteLCD r20
	rjmp firstlineLoop
exitfirstline:
	ldi r20, $C0	
	sendCommandLCD r20, r19
	ldi r26, $05
secondlineLoop:
	ld r20, x+
	cpi r26, 16
	brsh exitsecondline
	writeByteLCD r20
	rjmp secondlineLoop	 
exitsecondline:	
	clr r30
	clr r24
	clr r28
;	start
mainLOOP:
	;
	rjmp mainLOOP

usart_rx:
	lds r24, UDR0
	writeByteLCD r24	
	reti

twi:
	lds r25, $B9
	andi r25, $F8
	cpi r25, $08
	breq startSENT
	cpi r25, $18
	breq ackRECEIVED
	cpi r25, $28
	breq stopSENT
	rjmp end
startSENT:
	ldi r25, $06
	sts $BB, r25
	pd
	rjmp end
ackRECEIVED:
	sts $BB, r28
	inc r28
	pd
	rjmp end
stopSENT:
	stop
	rjmp end
end:
	reti	

timer0_ovf:
	inc r29
	cpi r29, 3
	brne end0
	clr r29
	start
end0:
	reti
	
.EXIT