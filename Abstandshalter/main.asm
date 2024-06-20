;
; Abstandshalter.asm
;
; Created: 05/06/2024 22:20:34
; Author : PDrue
;


; Replace with your application code
; Define baud rate

; Define baud rate
.include "m328pdef.inc"

.equ BAUD = 9600
.equ F_CPU = 16000000

; Calculate baud rate settings
.equ UBRR_VALUE = F_CPU / 16 / BAUD - 1

; Define string to send
.def UBRR_VALUE_High = r16
.def UBRR_VALUE_Low = r17
.def ch = r18
.def temp = r19  ; Temporäres Register für Konfiguration

.cseg
.org 0x00
    rjmp HC_SR04_sensor

/*RESET:
    ; Initialize USART
    ldi UBRR_VALUE_High, high(UBRR_VALUE)
    sts UBRR0H, UBRR_VALUE_High
    ldi UBRR_VALUE_Low, low(UBRR_VALUE)
    sts UBRR0L, UBRR_VALUE_Low
    ldi temp, (1 << RXEN0) | (1 << TXEN0)  ; Enable receiver and transmitter
    sts UCSR0B, temp
    ldi temp, (1 << UCSZ01) | (1 << UCSZ00) ; 8 data bits
    sts UCSR0C, temp

    ; Send "Hello, World!" string
    ldi ZH, high(hello_string << 1)
    ldi ZL, low(hello_string << 1)

send_loop:
    lpm ch, Z+
    tst ch
    breq done
    rcall send_char
    rjmp send_loop

done:
    rjmp done

send_char:
    ; Wait for empty transmit buffer
    lds temp, UCSR0A
    sbrs temp, UDRE0
    rjmp send_char

    ; Put data into buffer, sends the data
    sts UDR0, ch
    ret*/

HC_SR04_sensor:
;--------------

    ;-----------------------------------------------------------
agn:SBI   DDRB, 0         ;pin PB0 as o/p (Trigger)
    SBI   PORTB, 0		  ;start high
    RCALL delay_timer0	  ;delay 10µs
    CBI   PORTB, 0        ;end of high
    ;-----------------------------------------------------------
    RCALL echo_PW         ;compute Echo pulse width count
    ;-----------------------------------------------------------
    ;--RCALL byte2decimal    ;covert & display on MAX7219
    ;-----------------------------------------------------------
    RCALL delay_ms
    RJMP  agn
;===============================================================
echo_PW:
;-------
	CBI   DDRB, 0         ;pin PB0 as o/p (Echo)
    LDI   R20, 0b00000000
    STS   TCCR1A, R20     ;Timer 1 normal mode
    LDI   R20, 0b11000101 ;set for rising edge detection &
    STS   TCCR1B, R20     ;prescaler=1024, noise cancellation ON
    ;-----------------------------------------------------------
l1: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l1              ;loop until rising edge is detected
    ;-----------------------------------------------------------
    LDS   R16, ICR1L      ;store count value at rising edge
    ;-----------------------------------------------------------
    OUT   TIFR1, R21      ;clear flag for falling edge detection
    LDI   R20, 0b10000101
    STS   TCCR1B, R20     ;set for falling edge detection
    ;-----------------------------------------------------------
l2: IN    R21, TIFR1
    SBRS  R21, ICF1
    RJMP  l2              ;loop until falling edge is detected
    ;-----------------------------------------------------------
    LDS   R28, ICR1L      ;store count value at falling edge
    ;-----------------------------------------------------------
    SUB   R28, R16        ;count diff R22 = R22 - R16
    OUT   TIFR1, R21      ;clear flag for next sensor reading
    RET

	delay_timer0:             ;10 usec delay via Timer 0
;------------
    CLR   R20
    OUT   TCNT0, R20      ;initialize timer0 with count=0
    LDI   R20, 20
    OUT   OCR0A, R20      ;OCR0 = 20
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20     ;timer0: CTC mode, prescaler 8
    ;-----------------------------------------------------------
l0: IN    R20, TIFR0      ;get TIFR0 byte & check
    SBRS  R20, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  l0              ;else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R20
    OUT   TCCR0B, R20     ;stop timer0
    ;-----------------------------------------------------------
    LDI   R20, (1<<OCF0A)
    OUT   TIFR0, R20      ;clear OCF0 flag
    RET
;===============================================================
delay_ms:
;--------
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 50
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET

.dseg
hello_string:
    .db "Hello, World!", 0