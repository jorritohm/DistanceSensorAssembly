;
; Abstandshalter.asm
;
; Created: 05/06/2024 22:20:34
; Authors : Philipp Drüke, Jorrit Ohm

.include "m328pdef.inc"

.cseg
.org 0x00
    rjmp main

;===============================================================
main:
;----
	;---set LED Pins to Trigger---------------------------------
	SBI DDRD, 7		; green
	SBI DDRD, 6		; yellow
	SBI DDRD, 5		; red 
	SBI DDRD, 4		; buzzer
						
;===============================================================
main_loop:
;---------
	RCALL loop_delay
	SBI   DDRB, 0         ;pin PB0 as o/p (Trigger)
    SBI   PORTB, 0		  ;start high
    RCALL trigger_timer	  ;delay 10µs
    CBI   PORTB, 0        ;end of high	

    ;---calculate distance--------------------------------------
    RCALL echo_PW         ;compute Echo pulse width count

	;---set LEDs if distance < 128------------------------------
	CPI R28, 127
	BRMI setLED
   	
	;---reset LEDs----------------------------------------------	
	CBI PORTD, 7	; clear green LED
	CBI PORTD, 6	; clear yellow LED
	CBI PORTD, 5	; clear red LED
	CBI PORTD, 4	; clear buzzer

	;---loop----------------------------------------------------
	RJMP main_loop

;==============================================================
setLED:
;------
	;---set red LED---------------------------------------------
    CPI R28, 30		; if distance < 30 
    BRMI red		; red aufrufen

	;---set yellow LED------------------------------------------
    CPI R28, 60		; if distance < 60
    BRMI yellow		; yellow aufrufen

	;---set green LED-------------------------------------------
	CPI R28, 127	; if distance < 100
	BRMI green		; green aufrufen

;==============================================================
red:
;---
	SBI PORTD, 5	; set red LED
	SBI PORTD, 6	; set ýellow LED
	SBI PORTD, 7	; set green LED
	SBI PORTD, 4	; set buzzer
	RJMP main_loop	; loop

;==============================================================
yellow:
;------
	SBI PORTD, 6	; set yellow LED
	SBI PORTD, 7	; set green LED
	CBI PORTD, 5	; clear red LED
	CBI PORTD, 4	; clear buzzer
	RJMP main_loop	; loop

;==============================================================
green:
;-----
	SBI PORTD, 7	; set green LED
	CBI PORTD, 6	; clear yellow LED
	CBI PORTD, 5	; clear red LED
	CBI PORTD, 4	; clear buzzer
	RJMP main_loop	; loop

;===============================================================
echo_PW:
;-------
	CBI   DDRB, 0         ; pin PB0 as o/p (Echo)
    LDI   R20, 0b00000000
    STS   TCCR1A, R20     ; Timer 1 normal mode
    LDI   R20, 0b11000101 ; set for rising edge detection &
    STS   TCCR1B, R20     ; prescaler=1024, noise cancellation ON
    ;-----------------------------------------------------------
l1: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l1              ; loop until rising edge is detected
    ;-----------------------------------------------------------
    LDS   R16, ICR1L      ; store count value at rising edge
    ;-----------------------------------------------------------
    OUT   TIFR1, R21      ; clear flag for falling edge detection
    LDI   R20, 0b10000101
    STS   TCCR1B, R20     ; set for falling edge detection
    ;-----------------------------------------------------------
l2: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l2              ; loop until falling edge is detected
    ;-----------------------------------------------------------
    LDS   R28, ICR1L      ; store count value at falling edge
    ;-----------------------------------------------------------
    SUB   R28, R16        ; count diff R22 = R22 - R16
    OUT   TIFR1, R21      ; clear flag for next sensor reading
    RET

;===============================================================
trigger_timer:			  ; 10 usec delay via Timer 0
;------------
    CLR   R20
    OUT   TCNT0, R20      ; initialize timer0 with count=0
    LDI   R20, 20
    OUT   OCR0A, R20      ; OCR0 = 20
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20     ; timer0: CTC mode, prescaler 8
    ;-----------------------------------------------------------
l0: IN    R20, TIFR0      ; get TIFR0 byte & check
    SBRS  R20, OCF0A      ; if OCF0=1, skip next instruction
    RJMP  l0              ; else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R20
    OUT   TCCR0B, R20     ; stop timer0
    ;-----------------------------------------------------------
    LDI   R20, (1<<OCF0A) ; set bit in Register
    OUT   TIFR0, R20      ; clear OCF0 flag
    RET
;===============================================================
loop_delay:               ;0.125 sec delay via timer1
;--------
.EQU value = 63583        ;value to give 0.125 sec delay
    LDI   R20, high(value)
    STS   TCNT1H, R20
    LDI   R20, low(value)
    STS   TCNT1L, R20     ;initialize counter TCNT1 = value
    ;-------------------------------------------------------
    LDI   R20, 0b00000000
    STS   TCCR1A, R20
    LDI   R20, 0b00000101
    STS   TCCR1B, R20     ;normal mode, prescaler = 1024
    ;-------------------------------------------------------
delay_loop:
;----------
	IN    R20, TIFR1      ;get TIFR1 byte & check
    SBRS  R20, TOV1       ;if TOV1=1, skip next instruction
    RJMP  delay_loop      ;else, loop back & check TOV1 flag
    ;-------------------------------------------------------
    LDI   R20, 1<<TOV1
    OUT   TIFR1, R20      ;clear TOV1 flag
    ;-------------------------------------------------------
    LDI   R20, 0b00000000
    STS   TCCR1B, R20     ;stop timer0
    RET