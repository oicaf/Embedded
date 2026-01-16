;odczyt kodu RC-5 z pilota i wyswietlenie na LCD informacji od jakiego urzadzenia jest pilot i ktory przycisk zostal wcisniety
;testowane na pilocie od tunera SAT PHILIPS DSX6010, odpowiednik oryginalnego pilota oznaczony RC2582/01-LP
;
;wykonac zworke od RC5 do P3.2
;wykonac zworki od P1.0...P1.7 do D0...D7, od P3.5 do RS i od P3.7 do EN

IR	BIT	P3.2
RS	BIT	P3.5
E	BIT	P3.7

ORG 30H

ACALL	init

main:			;program glowny
CLR	A
MOV	B,#0

loop:
JB	IR,loop		;oczekiwanie na pierwszy bit startu (niski)
NOP

MOV	R0,#245		;odliczenie czasu 3/4 bitu (1335,5us dla zegara 11,059MHz)
loop1:
NOP
NOP
NOP
DJNZ	R0,loop1

MOV	R1,#7		;pobranie 7 kolejnych bitow (drugi bit startu, bit toggle, numer / adres urzadzenia)
loop3:
MOV	C,IR
RLC	A
NOP
NOP
MOV	R0,#233		;odliczenie czasu calego bitu (1778us dla zegara 11,059MHz)
loop2:
NOP
NOP
NOP
NOP
NOP
DJNZ	R0,loop2
DJNZ	R1,loop3

XCH	A,B		;pierwsze 7 bitow (drugi bit startu, bit toggle, numer / adres urzadzenia) do rejestru B

MOV	R1,#6		;pobranie 6 kolejnych bitow (numer komendy)
loop4:
MOV	C,IR
RLC	A
NOP
NOP
MOV	R0,#233		;odliczenie czasu calego bitu (1778us dla zegara 11,059MHz)
loop5:
NOP
NOP
NOP
NOP
NOP
DJNZ	R0,loop5
DJNZ	R1,loop4

MOV	R0,B		;R0 = drugi bit startu, bit toggle, numer / adres urzadzenia (bity 0-6)
MOV	R1,A		;R1 = numer komendy (bity 0-5)

MOV	A,R0
ANL	A,#40H		;spr. drugiego bitu startu (1 - OK, 0 - NOK)
JZ	error

ACALL	clear
MOV	A,#' '
ACALL	write_char

MOV     DPTR,#TEXT1
ACALL	write_text
MOV	A,R0
ANL	A,#1FH		;odciecie drugiego bitu startu oraz bitu toggle
CJNE	A,#0,dev5
MOV     DPTR,#DEVICE0
ACALL	write_text
JMP	main1

dev5:
CJNE	A,#5,error
MOV     DPTR,#DEVICE5
ACALL	write_text
JMP	main1

error:
ACALL	clear
MOV	A,#' '
ACALL	write_char
MOV     DPTR,#ERR
ACALL	write_text
JMP	main

main1:
MOV     P1,#0C0h	;kursor na poczatek drugiej linii
MOV	A,#1
ACALL	delay_ms
ACALL   write_inst

MOV     DPTR,#TEXT2
ACALL	write_text
MOV	A,R1
ANL	A,#3FH		;odciecie dwoch ostatnich bitow
CJNE	A,#10,stdby
MOV     DPTR,#DIGITENTRY
ACALL	write_text
JMP	main

stdby:
CJNE	A,#12,mut
MOV     DPTR,#STANDBY
ACALL	write_text
JMP	main

mut:
CJNE	A,#13,volH
MOV     DPTR,#MUTE
ACALL	write_text
JMP	main

volH:
CJNE	A,#16,volL
MOV     DPTR,#VOLUME_H
ACALL	write_text
JMP	main

volL:
CJNE	A,#17,bght_H
MOV     DPTR,#VOLUME_L
ACALL	write_text
JMP	main

bght_H:
CJNE	A,#18,bght_L
MOV     DPTR,#BRIGHT_H
ACALL	write_text
JMP	main

bght_L:
CJNE	A,#19,prog_H
MOV     DPTR,#BRIGHT_L
ACALL	write_text
JMP	main

prog_H:
CJNE	A,#32,prog_L
MOV     DPTR,#PROGRAM_H
ACALL	write_text
JMP	main

prog_L:
CJNE	A,#33,fr
MOV     DPTR,#PROGRAM_L
ACALL	write_text
JMP	main

fr:
CJNE	A,#50,ff
MOV     DPTR,#FAST_REW
ACALL	write_text
JMP	main

ff:
CJNE	A,#52,ply
MOV     DPTR,#FAST_FOR
ACALL	write_text
JMP	main

ply:
CJNE	A,#53,stp
MOV     DPTR,#PLAY
ACALL	write_text
JMP	main

stp:
CJNE	A,#54,rec
MOV     DPTR,#STOP
ACALL	write_text
JMP	main

rec:
CJNE	A,#55,numbers
MOV     DPTR,#RECORDING
ACALL	write_text
JMP	main

numbers:
ADD	A,#30H
ACALL	write_char

JMP	main

;*********************** PROCEDURY ****************************

write_inst:		;zapis instrukcji
CLR	RS
SETB	E
CLR	E
RET

write_data:		;zapis danych
SETB	RS
SETB	E
CLR	E
RET

init:			;inicjalizacja LCD
CLR	E
MOV	A,#50
ACALL	delay_ms
MOV     P1,#30h
ACALL	write_inst
MOV	A,#5
ACALL	delay_ms
ACALL	write_inst
MOV	A,#1
ACALL	delay_ms        
ACALL	write_inst
MOV     P1,#38h		;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                .           .3G¹V¹V  4G¹V·q    ..          .3G¹V¹V  4G¹V¶q    MAIN    C   63G¹V¹V  4G¹V                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           