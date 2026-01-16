; program demonstracyjny obslugujacy modul radia FM oparty na TEA5767 z wyswietlaniem na alfanumerycznym LCD (16x2)
; layout:
;
;	CH1____100.0 MHz
;	Y100%_____stereo
;
; obsluga przyciskow:
; S1(DOWN) - wybor programu (w dol), zmniejszenie czestotliwosci o 0,1 MHz (krotkie wcisniecie < 1s), auto wyszukiwanie w dol (dluzsze wcisniecie = 1s), forsowanie w dol (trzymanie > 1s)
; S2(MODE) - tryb wyboru programu, tryb wyszukiwania stacji (manual / auto) + programowanie
; S3(UP) - wybor programu (do gory), zwiekszenie czestotliwosci o 0,1 MHz (krotkie wcisniecie < 1s), auto wyszukiwanie w gore (dluzsze wcisniecie = 1s), forsowanie w gore (trzymanie > 1s)
;
; polaczenia na plycie AVT-2500:
; od P1.4...P1.7 do D4...D7
; od P1.2 do RS
; od P1.3 do EN
; od GND do RW (bezposrednio na plytce z wyswietlaczem, pin RW nalezy wyciagnac na zewnatrz LCD zeby nie byl wpiety na stale do masy na plycie AVT-2500)
; od S1 do P3.0
; od S2 do P3.1
; od S3 do P3.2
; rozlaczyc zworki JP4 i JP5
; dodac dwa rezystory 4k7 na zlaczu "9", miedzy VCC i SCL, miedzy VCC i SDA
; wykonac zworke przy zlaczu "9" od SDA do P3.5
; wykonac zworke przy zlaczu "9" od SCL do P3.7

; polaczenia od plyty AVT-2500 do modulu radia FM:
; od Ucc do +5V
; od GND do GND
; od P3.7 (SCL) do SLC
; od P3.5 (SDA) do SDA

RS	BIT	P1.2
EN	BIT	P1.3
DOWN	BIT	P3.0
MODE	BIT	P3.1
UP	BIT	P3.2
SDA	BIT	P3.5
SCL	BIT	P3.7

ORG	30h

ACALL	init_HD44780
ACALL	init_TEA5767

ACALL	start
MOV	A,#10100000b
ACALL	write
ACALL	read_ack
MOV	A,#00h		;aktualny nr programu w eeprom pod adresem 00h
ACALL	write
ACALL	read_ack
NOP
NOP
ACALL	start
MOV	A,#10100001b
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_noack
ACALL	stop
MOV	20h,A
JNZ	loop		;gdy eeprom pusty (np. po wymianie na nowy) to aktualny nr programu w RAM pod adresem 20h (domyslnie program nr 1)
MOV	20h,#1
ACALL	init_AT24C04
loop:
ACALL	read_mem
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
ACALL	read_regs
ACALL	disp

main:
JB	MODE,main24	;spr czy wcisniety przycisk S2(MODE)
MOV	R7,#30
ACALL	delay_ms
CPL	TR0		;TR0 = 0 tryb wyboru programu, TR = 1 tryb wyszukiwania stacji (manual / auto) + programowanie
JB	TR0,main26
ACALL	write_mem
MOV	A,#00001100b	;wylaczenie migania kursora
ACALL	write_inst
SJMP	main27
main26:
MOV	A,#00001101b	;wlaczenie migania kursora
ACALL	write_inst
main27:
JNB	MODE,main27	;przycisk S2(MODE) musi zostac zwolniony zeby przejsc dalej
main24:
JB	UP,main2	;spr czy wcisniety przycisk S3(UP)
MOV	R7,#30
ACALL	delay_ms
JB	TR0,main25
INC	20h
MOV	A,20h
CJNE	A,#6,main29
MOV	20h,#1
main29:
ACALL	read_mem
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
ACALL	read_regs
ACALL	disp
ACALL	write_prog	;zapamietanie w eeprom ostatnio wybranej stacji
main28:
JNB	UP,main28	;przycisk S3(UP) musi zostac zwolniony zeby przejsc dalej
SJMP	main2
main25:
MOV	A,32h
ADD	A,#12		;zwiekszenie aktualnej czestotliwosci o ~100kHz
MOV	32h,A
CLR	A
ADDC	A,31h
MOV	31h,A
CJNE	A,#33h,main12
MOV	A,32h
CLR	C
SUBB	A,#65h
JC	main12		;spr czy poza zakresem
MOV	31h,#00101001b
MOV	32h,#10011110b	;"zawiniecie" do 87,5 MHz
main12:
ORL	33h,#10000110b	;aktywacja SEARCH UP, MUTE LEFT i MUTE RIGHT
SJMP	main3
main2:
JB	DOWN,main	;spr czy wcisniety przycisk S1(DOWN)
MOV	R7,#30
ACALL	delay_ms
JB	TR0,main30
DEC	20h
MOV	A,20h
CJNE	A,#0,main31
MOV	20h,#5
main31:
ACALL	read_mem
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
ACALL	read_regs
ACALL	disp
ACALL	write_prog	;zapamietanie w eeprom ostatnio wybranej stacji
main32:
JNB	DOWN,main32	;przycisk S1(DOWN) musi zostac zwolniony zeby przejsc dalej
AJMP	main
main30:
MOV	A,32h
CLR	C
SUBB	A,#12		;zmniejszenie aktualnej czestotliwosci o ~100kHz
MOV	32h,A
MOV	A,31h
SUBB	A,#0
MOV	31h,A
CJNE	A,#29h,main13
MOV	A,32h
CLR	C
SUBB	A,#9Eh
JNC	main13		;spr czy poza zakresem
MOV	31h,#00110011b
MOV	32h,#01100100b	;"zawiniecie" do 108.0 MHz
main13:
ANL	33h,#01111111b	;aktywacja SEARCH DOWN
ORL	33h,#00000110b	;aktywacja MUTE LEFT i MUTE RIGHT
main3:
MOV	A,#00001100b	;wylaczenie migania kursora
ACALL	write_inst
ORL	31h,#10000000b	;aktywacja MUTE (tryb manual)
ACALL	write_regs
MOV	R7,30
ACALL	delay_ms
main1:
ACALL	read_regs
ACALL	disp
MOV	A,21h
JNB	ACC.6,main4	;spr flagi BAND LIMIT
JB	ACC.4,main5	;1 = gorny limit, 0 = dolny limit
MOV	31h,#11110011b
MOV	32h,#01100100b	;"zawiniecie" do 108.0 MHz
SJMP	main6
main5:
MOV	31h,#11101001b
MOV	32h,#10011110b	;"zawiniecie" do 87,5 MHz
main6:
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
SJMP	main1
main4:
JB	UP,main7	;przerwanie wyszukiwania stacji gdy wcisniety przycisk S3(UP)
MOV	R7,#30
ACALL	delay_ms
JB	F0,main15	;forsowanie (F0 = 0 brak forsowania, F0 = 1 forsowanie)
MOV	DPTR,#0
main10:
INC	DPTR
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
MOV	A,DPH
CJNE	A,#0FFh,main14	;spr czy minela ~1s
main15:
MOV	A,21h
JNB	ACC.7,main16	;spr flagi READY
MOV	A,22h
ADD	A,#12		;zwiekszenie aktualnej czestotliwosci o ~100kHz
MOV	32h,A
CLR	A
ADDC	A,21h
MOV	31h,A
ORL	31h,#11000000b	;aktywacja MUTE i SEARCH MODE (tryb auto)
SJMP	main17
main16:
MOV	31h,21h		;skopiowanie bajtu spod adresu 21h do 31h (znaleziona stacja PLL13...PLL8)
ORL	31h,#11000000b	;aktywacja MUTE i SEARCH MODE (tryb auto)
MOV	32h,22h		;skopiowanie bajtu spod adresu 22h do 32h (znaleziona stacja PLL7...PLL0)
main17:
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
SETB	F0		;forsowanie
SJMP	main1
main14:
JNB	UP,main10	;przycisk S3(UP) musi zostac zwolniony zeby przejsc dalej
SJMP	main9
main7:
JB	DOWN,main8	;przerwanie wyszukiwania stacji gdy wcisniety przycisk przycisk S1(DOWN)
MOV	R7,#30
ACALL	delay_ms
JB	F0,main19	;forsowanie (F0 = 0 brak forsowania, F0 = 1 forsowanie)
MOV	DPTR,#0
main11:
INC	DPTR
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
MOV	A,DPH
CJNE	A,#0FFh,main18	;spr czy minela ~1s
main19:
MOV	A,21h
JNB	ACC.7,main20	;spr flage READY
MOV	A,22h
CLR	C
SUBB	A,#12		;zmniejszenie aktualnej czestotliwosci o ~100kHz
MOV	32h,A
MOV	A,21h
SUBB	A,#0
MOV	31h,A
ORL	31h,#11000000b	;aktywacja MUTE i SEARCH MODE (tryb auto)
SJMP	main21
main20:
MOV	31h,21h		;skopiowanie bajtu spod adresu 21h do 31h (znaleziona stacja PLL13...PLL8)
ORL	31h,#11000000b	;aktywacja MUTE i SEARCH MODE (tryb auto)
MOV	32h,22h		;skopiowanie bajtu spod adresu 22h do 32h (znaleziona stacja PLL7...PLL0)
main21:
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
SETB	F0		;forsowanie
main22:
AJMP	main1
main18:
JNB	DOWN,main11	;przycisk S1(DOWN) musi zostac zwolniony zeby przejsc dalej
SJMP	main9
main8:
CLR	F0		;brak forsowania
MOV	R7,#150
ACALL	delay_ms
JNB	ACC.7,main22	;oczekiwanie na flage READY
main9:
MOV	31h,21h		;skopiowanie bajtu spod adresu 21h do 31h (znaleziona stacja PLL13...PLL8)
ANL	31h,#00111111b	;deaktywacja MUTE i SEARCH MODE
MOV	32h,22h		;skopiowanie bajtu spod adresu 22h do 32h (znaleziona stacja PLL7...PLL0)
ANL	33h,#11111001b	;deaktywacja MUTE LEFT i MUTE RIGHT
ACALL	write_regs
MOV	R7,#250
ACALL	delay_ms
ACALL	read_regs
ACALL	disp
MOV	A,#00001101b	;wlaczenie migania kursora
ACALL	write_inst
AJMP	main

; HD44780
init_HD44780:		;inicjalizacja LCD
CLR	EN
CLR	RS
MOV	R7,#150
ACALL	delay_ms

MOV     P1,#30h
ACALL	strobe
MOV	R7,#5
ACALL	delay_ms

ACALL	strobe
MOV	R7,#1
ACALL	delay_ms

MOV     A,#28h		;magistrala 4-bit, dwa wiersze, matryca 5x8
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
MOV     A,#08h		;wylaczenie wyswietlacza, kursora i migania
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
MOV     A,#01h		;kasowanie wyswietlacza
ACALL   write_inst
MOV	R7,#2
ACALL	delay_ms
MOV     A,#06h		;konfiguracja przesuwania kursora
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
MOV     A,#0Ch		;zalaczenie wyswietlacza
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
RET

clear:			;kasowanie wyswietlacza znakowego
MOV     A,#01h
ACALL   write_inst
MOV	R7,#2
ACALL	delay_ms
RET

home:			;kursor na poczatek
MOV     A,#02h
ACALL   write_inst
MOV	R7,#2
ACALL	delay_ms
RET

write_char:		;wyswietlenie znaku
ACALL   write_data
MOV	R7,#5
ACALL	delay_10us
RET

write_text:		;wyswietlenie tekstu
CLR     A
MOVC    A,@A+DPTR
JNZ     write_text1
        RET
write_text1:
ACALL   write_char
INC     DPTR
SJMP    write_text

write_inst:		;zapis instrukcji
PUSH	ACC
ANL	A,#0F0h		;maska starszego polbajtu
MOV	P1,A
ACALL	strobe
POP	ACC
SWAP	A
ANL	A,#0F0h		;maska mlodszego polbajtu
MOV	P1,A
ACALL	strobe
RET

write_data:		;zapis danych
PUSH	ACC
ANL	A,#0F0h		;maska starszego polbajtu
MOV	P1,A
SETB	RS
ACALL	strobe
POP	ACC
SWAP	A
ANL	A,#0F0h		;maska mlodszego polbajtu
MOV	P1,A
SETB	RS
ACALL	strobe
RET

strobe:			;strobowanie ukladu
SETB	EN
CLR	EN
RET

; TEA5767
init_TEA5767:		;inicjalizacja / wstepna konfiguracja radia FM
MOV	31h,#29h	;patrz specyfikacja
MOV	32h,#9Eh	;patrz specyfikacja
MOV	33h,#11100000b	;patrz specyfikacja
MOV	34h,#00011110b	;patrz specyfikacja
MOV	35h,#00000000b	;patrz specyfikacja
ACALL	write_regs
MOV	R7,#30
ACALL	delay_ms
RET

read_regs:		;odczyt 5 rejestrow (TEA5767)
ACALL	start
MOV	A,#11000001b
ACALL	write
ACALL	read_ack
MOV	R0,#21h		;poczatkowy adres RAM
MOV	R4,#5
read_regs1:
ACALL	read
MOV	@R0,A		;zapis do RAM
CJNE	R4,#1,read_regs2
ACALL	write_noack
SJMP	read_regs3
read_regs2:
ACALL	write_ack
INC	R0
DJNZ	R4,read_regs1
read_regs3:
ACALL	stop
RET

write_regs:		;zapis 5 rejestrow (TEA5767)
ACALL	start
MOV	A,#11000000b
ACALL	write
ACALL	read_ack
MOV	R0,#31h		;poczatkowy adres RAM
MOV	R4,#5
write_regs1:
MOV	A,@R0		;odczyt z RAM
ACALL	write
ACALL	read_ack
INC	R0
DJNZ	R4,write_regs1
ACALL	stop
RET

disp:			;wyswietlenie informacji na LCD
MOV	A,#'C'
ACALL	write_char
MOV	A,#'H'
ACALL	write_char
MOV	A,20h		;nr programu
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	R4,#4
disp7:
MOV	A,#' '
ACALL	write_char
DJNZ	R4,disp7
MOV	R0,22h		;PLL7...PLL0
MOV	A,21h		;PLL13...PLL8
ANL	A,#00111111b
MOV	R1,A
MOV	R2,#16h
MOV	R3,#20h		;staly wspolczynnik (mnozenie przez 8214)
ACALL	MNOZENIE_2_2
MOV	R4,#10h		
MOV	R5,#27h		;dzielenie przez 10000
ACALL	UDIV32
MOV	R4,#0E8h
MOV	R5,#03h		;dzielenie przez 1000
ACALL	UDIV32
CJNE	R0,#10,disp5	;spr czy liczba trzycyfrowa (przed przecinkiem)
MOV	A,#'1'
ACALL	write_char
MOV	A,#'0'
ACALL	write_char
SJMP	disp6
disp5:
MOV	A,#' '
ACALL	write_char
MOV	A,R0
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
disp6:
MOV	A,R4
MOV	R0,A
MOV	A,R5
MOV	R1,A
MOV	R4,#64h		;dzielenie przez 100
MOV	R5,#0
ACALL	UDIV32
MOV	A,R0
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	A,#'.'
ACALL	write_char
MOV	A,R4
MOV	B,#10
DIV	AB
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	DPTR,#freq
ACALL	write_text
MOV     A,#0C0h		;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
MOV	A,#5Ch		;symbol anteny
ACALL	write_char
MOV	A,24h
ANL	A,#0F0h
SWAP	A		;sila / poziom sygnalu (0 = 0% do 15 = 100%)
MOV	B,#7		;rozdzielczosc = 7%
MUL	AB
PUSH	ACC
CLR	C
SUBB	A,#101		;sp czy poza zakresem (> 100%)
JC	disp8
POP	ACC
MOV	A,#100
PUSH	ACC
disp8:
POP	ACC
MOV	B,#100
DIV	AB
MOV	R4,#0
JZ	disp9
MOV	A,#'1'
ACALL	write_char
MOV	A,#'0'
ACALL	write_char
MOV	A,#'0'
ACALL	write_char
SJMP	disp10
disp9:
MOV	A,B
MOV	B,#10
DIV	AB
INC	R4
JZ	disp11
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
DEC	R4
disp11:
MOV	A,B
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
INC	R4
disp10:
MOV	A,#'%'
ACALL	write_char
MOV	A,R4
ADD	A,#5
MOV	R4,A
disp3:
MOV	A,#' '
ACALL	write_char
DJNZ	R4,disp3
MOV	A,23h
JB	ACC.7,disp1	;spr czy odebrane stereo
MOV	R4,#6
disp4:
MOV	A,#' '
ACALL	write_char
DJNZ	R4,disp4
SJMP	disp2
disp1:
MOV	DPTR,#stereo
ACALL	write_text
disp2:
ACALL	home
RET

; AT24C04
init_AT24C04:		;zapis w eeprom domyslnego programu nr 1 (adres 00h) oraz domyslnej czestotliwosci 87,5 MHz dla pieciu programow (adres od 01h do 0Ah)
ACALL	start
MOV	A,#10100000b
ACALL	write
ACALL	read_ack
MOV	A,#00h
ACALL	write
ACALL	read_ack
MOV	A,#01h
ACALL	write
ACALL	read_ack
MOV	R4,#5
init:
MOV	A,#29h
ACALL	write
ACALL	read_ack
MOV	A,#9Eh
ACALL	write
ACALL	read_ack
DJNZ	R4,init
ACALL	stop
RET

read_mem:		;odczyt dwoch bajtow z eeprom i zapisanie ich w RAM
ACALL	start
MOV	A,#10100000b
ACALL	write
ACALL	read_ack
MOV	A,20h		;aktualny nr programu w RAM
MOV	B,#2
MUL	AB
DEC 	A
ACALL	write
ACALL	read_ack
NOP
NOP
ACALL	start
MOV	A,#10100001b
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_ack
MOV	31h,A		;PLL13...PLL8
ACALL	read
ACALL	write_noack
MOV	32h,A		;PLL7...PLL0
ACALL	stop
RET

write_mem:		;zapis dwoch bajtow w eeprom
ACALL	start
MOV	A,#10100000b
ACALL	write
ACALL	read_ack
MOV	A,20h
MOV	B,#2
MUL	AB
DEC 	A
ACALL	write
ACALL	read_ack
MOV	A,21h		;PLL13...PLL8
ANL	A,#00111111b
ACALL	write
ACALL	read_ack
MOV	A,22h		;PLL7...PLL0
ACALL	write
ACALL	read_ack
ACALL	stop
RET

write_prog:		;zapis aktualnego nr programu w eeprom (adres 00h)
ACALL	start
MOV	A,#10100000b
ACALL	write
ACALL	read_ack
MOV	A,#00h
ACALL	write
ACALL	read_ack
MOV	A,20h		;aktualny nr programu w RAM
ACALL	write
ACALL	read_ack
ACALL	stop
RET
			;obsluga i2c
start:			;start
CLR	SCL
SETB	SDA
SETB	SCL
CLR	SDA
RET

stop:			;stop
CLR	SCL
CLR	SDA
SETB	SCL
SETB	SDA
RET

write_ack:		;wyslanie potwierdzenia
CLR	SCL
CLR	SDA
SETB	SCL
RET

write_noack:		;wyslanie braku potwierdzenia
CLR	SCL
SETB	SDA
SETB	SCL
RET

read_ack:		;odczyt potwierdzenia
CLR	SCL
SETB	SCL
MOV	C,SDA
RET

write:			;zapis bajtu
MOV	R5,#8
write1:
CLR	SCL
RLC	A
MOV	SDA,C
SETB	SCL
DJNZ	R5,write1
RET

read:			;odczyt bajtu
MOV	R5,#8
read1:
CLR	SCL
SETB	SDA
SETB	SCL
MOV	C,SDA
RLC	A
DJNZ	R5,read1
RET

; DELAY LOOPS
delay_ms:		;petla opozniajaca w ms
MOV     R6,#229
delay_ms1:
NOP
NOP
DJNZ    R6,delay_ms1
NOP
NOP
DJNZ    R7,delay_ms
RET

delay_10us:		;petla opozniajaca w ~10us (9,765us)
MOV     R6,#3
delay_10us1:
DJNZ    R6,delay_10us1
DJNZ    R7,delay_10us
RET

;====================================================================
; MNOZENIE_2_2  mno¿enie 2bajty x 2bajty bez znaku
;
; wejœcie:    	R1, R0 = mno¿na (x) (R0 m³odszy bajt)
;           	R3, R2 = mno¿nik (y) (R2 m³odszy bajt)
;
; wyjœcie:   R3, R2, R1, R0 =wynik mno¿enia (R3 najstarszy bajt)
;
; zmienia:   ACC, C
;====================================================================
MNOZENIE_2_2:
	MOV	A,R0
	MOV	B,R2
	MUL	AB	; mno¿enie xL x yL
	PUSH	ACC	; wynik na stos (low byte)
	PUSH	B	; wynik na stos (high byte)
	MOV	A,R0
	MOV	B,R3
	MUL	AB	; mno¿enie xL x yH
	POP	00H
	ADD	A,R0
	MOV	R0,A
	CLR	A
	ADDC	A,B
	MOV	DPL,A
	MOV	A,R2
	MOV	B,R1
	MUL	AB	; mno¿enie xH x yL
	ADD	A,R0
	MOV	R0,A
	MOV	A,DPL
	ADDC	A,B
	MOV	DPL,A
	CLR	A
	ADDC	A,#0
	PUSH	ACC	; zachowaj poœrednie przeniesienie
	MOV	A,R3
	MOV	B,R1
	MUL	AB	; mno¿enie xH x yH
	ADD	A,DPL
	MOV	R2,A
	POP	ACC	; pobierz przeniesienie
	ADDC	A,B
	MOV	R3,A
	MOV	R1,00H
	POP	00H	; retrieve result low byte
	RET			

;==================================================================== 
; subroutine UDIV32 
; 32-Bit / 16-Bit to 32-Bit Quotient & Remainder Unsigned Divide 
; 
; input: r3, r2, r1, r0 = Dividend X 
; r5, r4 = Divisor Y 
; 
; output: r3, r2, r1, r0 = quotient Q of division Q = X / Y 
; r7, r6, r5, r4 = remainder 
;; 
; alters: acc, flags 
;==================================================================== 

UDIV32:
push 08 ; Save Register Bank 1 
push 09 
push 0AH 
push 0BH 
push 0CH 
push 0DH 
push 0EH 
push 0FH 
push dpl 
push dph 
push B 
setb RS0 ; Select Register Bank 1 
mov r7, #0 ; clear partial remainder 
mov r6, #0 
mov r5, #0 
mov r4, #0 
mov B, #32 ; set loop count 

div_lp32:
clr RS0 ; Select Register Bank 0 
clr C ; clear carry flag 
mov a, r0 ; shift the highest bit of the 
rlc a ; dividend into... 
mov r0, a 
mov a, r1 
rlc a 
mov r1, a 
mov a, r2 
rlc a 
mov r2, a 
mov a, r3 
rlc a 
mov r3, a 
setb RS0 ; Select Register Bank 1 
mov a, r4 ; ... the lowest bit of the 
rlc a ; partial remainder 
mov r4, a 
mov a, r5 
rlc a 
mov r5, a 
mov a, r6 
rlc a 
mov r6, a 
mov a, r7 
rlc a 
mov r7, a 
mov a, r4 ; trial subtract divisor from 
clr C ; partial remainder 
subb a, 04 
mov dpl, a 
mov a, r5 
subb a, 05 
mov dph, a 
mov a, r6 
subb a, #0 
mov 06, a 
mov a, r7 
subb a, #0 
mov 07, a 
cpl C ; complement external borrow 
jnc div_321 ; update partial remainder if 
; borrow 
mov r7, 07 ; update partial remainder 
mov r6, 06 
mov r5, dph 
mov r4, dpl 
div_321:
mov a, r0 ; shift result bit into partial 
rlc a ; quotient 
mov r0, a 
mov a, r1 
rlc a 
mov r1, a 
mov a, r2 
rlc a 
mov r2, a 
mov a, r3 
rlc a 
mov r3, a 
djnz B, div_lp32 

mov 07, r7 ; put remainder, saved before the 
mov 06, r6 ; last subtraction, in bank 0 
mov 05, r5 
mov 04, r4 
mov 03, r3 ; put quotient in bank 0 
mov 02, r2 
mov 01, r1 
mov 00, r0 
clr RS0 
pop B 
pop dph 
pop dpl 
pop 0FH ; Retrieve Register Bank 1 
pop 0EH 
pop 0DH 
pop 0CH 
pop 0BH 
pop 0AH 
pop 09 
pop 08 
ret

freq:
DB	' MHz',0

stereo:
DB	'stereo',0

END