; odczyt daty (rok, miesiac, dzien, dzien tygodnia) z zegara czasu rzeczywistego PCF8583 (po i2c) i wyswietlenie na LCD (pierwszy wiersz)
; odczyt czasu (godzina, minuta, sekunda) z zegara czasu rzeczywistego PCF8353 (po i2c) oraz temperatury z cyfrowego czujnika DS18B20 (po 1-wire) i wyswietlenie na LCD (drugi wiersz)
; edycja / ustawianie daty i czasu za pomoca przyciskow S1(SET), S2(DOWN) i S3(UP)
; ponizej przyklad / formatka:
;
;	2004-01-01___THU
;	12:00______+22^C
;
; wersja B:
; - tryb edycji sygnalizuje migajacy kursor w miejscu gdzie dokonywana jest zmiana / modyfikacja
; - brak wyswietlanych sekund (brak mozliwosci ustawiania / zerowania), migajacy dwukropek sygnalizuje sekundy, w trybie edycji dwukropek wyswietlany jest na stale
; - dzien tygodnia wyliczany automatycznie na podstawie wzoru w zaleznosci od aktualnego roku, miesiaca i dnia
; ----------------------------
; wykonac zworke od S1 do P3.0
; wykonac zworke od S2 do P3.1
; wykonac zworke od S3 do P3.2
; podpiac czujnik DS18B20 do CON9 (VCC, 1WIRE, GND)
; wykonac zworke od 1WIRE do P3.4
; wykonac zworki od P1.4...P1.7 do D4...D7, od P1.2 do RS, od P1.3 do EN, od D0...D3 do GND
; rozlaczyc zworki JP2 i JP3
; dodac dwa rezystory 4k7 na zlaczu "9", miedzy VCC i SCL, miedzy VCC i SDA
; wykonac zworke przy zlaczu "9" od SDA do P3.5
; wykonac zworke przy zlaczu "9" od SCL do P3.7

RS	BIT	P1.2
EN	BIT	P1.3

SETUP	BIT	P3.0
DOWN	BIT	P3.1
UP	BIT	P3.2
DQ	BIT	P3.4
SDA	BIT	P3.5
SCL	BIT	P3.7

SLA_WR	EQU	10100010b
SLA_RD	EQU	10100011b

MOV	R3,#0
MOV	R4,#4
MOV	R5,#0

ACALL	init

main:			;program glowny
JB	SETUP,norm	;spr czy zostal wcisniety S1 (SETUP)
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
CJNE	R5,#0,edit	;R5=0 tryb norm, R5>0 tryb edycji, R5=6 przejscie z trybu edycji do trybu norm
ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#00h		;sterowanie / stan
ACALL	write
ACALL	read_ack
MOV	A,#80h		;zliczanie wstrzymane + wyzerowany dzielnik
ACALL	write
ACALL	read_ack
ACALL	stop
edit:
JNB	SETUP,edit	;przycisk musi zostac zwolniony zeby przejsc dalej
INC	R5
CJNE	R5,#6,norm
ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#00h		;sterowanie / stan
ACALL	write
ACALL	read_ack
MOV	A,#00h		;zliczanie wznowione
ACALL	write
ACALL	read_ack
ACALL	stop
MOV	R5,#0
norm:
;*********************** DATA ***************************
MOV	A,#'2'
ACALL	write_char
MOV	A,#'0'
ACALL	write_char

ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#05h		;lata / dni
ACALL	write
ACALL	read_ack
ACALL	start
MOV	A,#SLA_RD
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_noack
ACALL	stop

MOV	B,A
MOV	TH0,A
ANL	A,#0C0h		;maska na lata
RL	A
RL	A
PUSH	B
MOV	B,R3
CJNE	A,B,year_diff
SJMP	year_nzero
year_diff:
JNZ	year_nzero
INC	R4		;w R4 wielokrotnosc liczby 4 (0,4,8,12,16...), zwiekszane przy kazdym przejsciu z 3 na 0 (co 4 lata)
INC	R4
INC	R4
INC	R4
CJNE	R4,#100,year_nzero
MOV	R4,#4
year_nzero:
MOV	R3,A		;w R3 aktualny odczyt roku (tylko od 0 do 3 lat) do porownania przy nast. odczycie zeby wylapac przeniesienie / przeskok z 3 na 0 
POP	B

CJNE	R5,#1,norm10	;jesli R5=1 to edycja lat

PUSH	ACC
MOV	A,P3
ANL	A,#06h
CJNE	A,#0,norm15
POP	ACC
SJMP	norm10

norm15:
POP	ACC
JB	UP,norm12	;spr czy zostal wcisniety S3 (UP)
INC	A
CJNE	A,#4,norm11	;spr czy nastapilo przejscie z 3 na 4
MOV	A,#0
INC	R4		;w R4 wielokrotnosc liczby 4 (0,4,8,12,16...), zwiekszane przy kazdym przejsciu z 3 na 0 (co 4 lata)
INC	R4
INC	R4
INC	R4
CJNE	R4,#100,norm11
MOV	R4,#4
norm11:
MOV	R3,A		;w R3 aktualny odczyt roku (tylko od 0 do 3 lat) do porownania przy nast. odczycie zeby wylapac przeniesienie / przeskok z 3 na 0 
SJMP	norm13

norm12:
JB	DOWN,norm10	;spr czy zostal wcisniety S2 (DOWN)
DEC	A
CJNE	A,#255,norm14	;spr czy nastapilo przejscie z 0 na 255 (-1)
MOV	A,#3
DEC	R4		;w R4 wielokrotnosc liczby 4 (96,0,4,8,12,16...), zmniejszane przy kazdym przejsciu z 0 na 3 (co 4 lata)
DEC	R4
DEC	R4
DEC	R4
CJNE	R4,#0,norm14
MOV	R4,#96
norm14:
MOV	R3,A		;w R3 aktualny odczyt roku (tylko od 0 do 3 lat) do porownania przy nast. odczycie zeby wylapac przeniesienie / przeskok z 3 na 0

norm13:
PUSH	ACC
ANL	B,#3Fh		;przywrocenie dni
RR	A
RR	A
ADD	A,B
MOV	TH0,A
ACALL	days_ok
MOV	A,TH0
PUSH	ACC
ACALL	start		;przy kazdej zmianie na nowa wartosc nastepuje autosave
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#05h		;lata / dni
ACALL	write
ACALL	read_ack
POP	ACC
ACALL	write
ACALL	read_ack
ACALL	stop
POP	ACC

norm10:
ADD	A,R4
MOV	B,#10
DIV	AB		;calosc z dzielenia przez 10 w ACC, reszta w B
PUSH	B
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
CJNE	R5,#1,norm1	;jesli R5=1 to edycja lat
MOV     A,#0Eh		;zalaczenie kursora
ACALL   write_inst
MOV	R7,#120
ACALL	delay_ms
MOV     A,#0Ch		;wylaczenie kursora
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
norm1:
POP	ACC
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char

MOV	A,#'-'
ACALL	write_char

ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#06h		;dni tygodnia / miesiace
ACALL	write
ACALL	read_ack
ACALL	start
MOV	A,#SLA_RD
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_noack
ACALL	stop

MOV	TL1,A

MOV	B,A
ANL	A,#1Fh		;maska na miesiace
MOV	TL0,A

CJNE	R5,#2,norm20	;jesli R5=2 to edycja miesiecy

PUSH	ACC
MOV	A,P3
ANL	A,#06h
CJNE	A,#0,norm23
POP	ACC
SJMP	norm20

norm23:
POP	ACC
JB	UP,norm24	;spr czy zostal wcisniety S3 (UP)
INC	A
CJNE	A,#0Ah,norm21	;spr czy nastapilo przejscie z 09h na 0Ah
MOV	A,#10h		;9 -> 10
SJMP	norm22
norm21:
CJNE	A,#13h,norm22	;spr czy nastapilo przejscie z 12h na 13h
MOV	A,#01h		;12 -> 01
SJMP	norm22

norm24:
JB	DOWN,norm20	;spr czy zostal wcisniety S2 (DOWN)
DEC	A
CJNE	A,#0Fh,norm25	;spr czy nastapilo przejscie z 10h na 0Fh
MOV	A,#09h		;10 -> 9
SJMP	norm22
norm25:
CJNE	A,#00h,norm22	;spr czy nastapilo przejscie z 01h na 00h
MOV	A,#12h		;01 -> 12

norm22:
MOV	TL0,A
ACALL	days_ok
MOV	A,TL0

PUSH	ACC
ANL	B,#0E0h		;przywrocenie dni tygodnia
ADD	A,B
PUSH	ACC
MOV	TL1,A
ACALL	start		;przy kazdej zmianie na nowa wartosc nastepuje autosave
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#06h		;dni tygodnia / miesiace
ACALL	write
ACALL	read_ack
POP	ACC
ACALL	write
ACALL	read_ack
ACALL	stop
POP	ACC

norm20:
PUSH	ACC
ANL	A,#10h		;maska na dziesiatki miesiecy (0 lub 1)
SWAP	A
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
CJNE	R5,#2,norm2	;jesli R5=2 to edycja miesiecy
MOV     A,#0Eh		;zalaczenie kursora
ACALL   write_inst
MOV	R7,#120
ACALL	delay_ms
MOV     A,#0Ch		;wylaczenie kursora
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
norm2:
POP	ACC
ANL	A,#0Fh		;maska na jednostki miesiecy w BCD (0-9)
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char

MOV	A,#'-'
ACALL	write_char

MOV	A,TH0		;lata / dni
MOV	B,A
ANL	A,#3Fh		;maska na dni

CJNE	R5,#3,norm300	;jesli R5=3 to edycja dni

PUSH	ACC
MOV	A,P3
ANL	A,#06h
CJNE	A,#0,norm35
POP	ACC
norm300:
AJMP	norm30

norm35:
POP	ACC
JB	UP,norm36	;spr czy zostal wcisniety S3 (UP)
INC	A
MOV	R0,TL0
CJNE	A,#29h,norm302
CJNE	R0,#02h,norm308
CJNE	R3,#0,norm301
SJMP	norm308
norm302:
CJNE	A,#2Ah,norm303
CJNE	R0,#02h,norm308
SJMP	norm301
norm303:
CJNE	A,#31h,norm308
CJNE	R0,#04h,norm305
SJMP	norm301
norm305:
CJNE	R0,#06h,norm306
SJMP	norm301
norm306:
CJNE	R0,#09h,norm307
SJMP	norm301
norm307:
CJNE	R0,#11h,norm308
SJMP	norm301

norm308:
CJNE	A,#0Ah,norm31	;spr czy nastapilo przejscie z 09h na 0Ah
MOV	A,#10h		;9 -> 10
SJMP	norm34
norm31:
CJNE	A,#1Ah,norm32	;spr czy nastapilo przejscie z 19h na 1Ah
MOV	A,#20h		;19 -> 20
SJMP	norm34
norm32:
CJNE	A,#2Ah,norm33	;spr czy nastapilo przejscie z 29h na 2Ah
MOV	A,#30h		;29 -> 30
SJMP	norm34
norm33:
CJNE	A,#32h,norm34	;spr czy nastapilo przejscie z 31h na 32h
norm301:
MOV	A,#01h		;31 -> 01
SJMP	norm34

norm36:
JB	DOWN,norm30	;spr czy zostal wcisniety S2 (DOWN)
DEC	A
MOV	R0,TL0
CJNE	A,#00h,norm309
CJNE	R0,#04h,norm310
MOV	A,#30h
SJMP	norm34
norm310:
CJNE	R0,#06h,norm311
MOV	A,#30h
SJMP	norm34
norm311:
CJNE	R0,#09h,norm312
MOV	A,#30h
SJMP	norm34
norm312:
CJNE	R0,#11h,norm313
MOV	A,#30h
SJMP	norm34
norm313:
CJNE	R0,#02h,norm39
CJNE	R3,#0,norm314
MOV	A,#29h
SJMP	norm34
norm314:
MOV	A,#28h
SJMP	norm34

norm309:
CJNE	A,#0Fh,norm37	;spr czy nastapilo przejscie z 10h na 0Fh
MOV	A,#09h		;10 -> 9
SJMP	norm34
norm37:
CJNE	A,#1Fh,norm38	;spr czy nastapilo przejscie z 20h na 1Fh
MOV	A,#19h		;20 -> 19
SJMP	norm34
norm38:
CJNE	A,#2Fh,norm39	;spr czy nastapilo przejscie z 30h na 2Fh
MOV	A,#29h		;30 -> 29
SJMP	norm34
norm39:
CJNE	A,#00h,norm34	;spr czy nastapilo przejscie z 01h na 00h
MOV	A,#31h		;01 -> 31

norm34:
PUSH	ACC
ANL	B,#0C0h		;przywrocenie lat
ADD	A,B
MOV	TH0,A
PUSH	ACC
ACALL	start		;przy kazdej zmianie na nowa wartosc nastepuje autosave
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#05h		;lata / dni
ACALL	write
ACALL	read_ack
POP	ACC
ACALL	write
ACALL	read_ack
ACALL	stop
POP	ACC

norm30:
PUSH	ACC
ANL	A,#30h		;maska na dziesiatki dni (0-3)
SWAP	A
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
CJNE	R5,#3,norm3	;jesli R5=3 to edycja dni
MOV     A,#0Eh		;zalaczenie kursora
ACALL   write_inst
MOV	R7,#120
ACALL	delay_ms
MOV     A,#0Ch		;wylaczenie kursora
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
norm3:
POP	ACC
ANL	A,#0Fh		;maska na jednostki dni w BCD (0-9)
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char

MOV	DPTR,#SPACES
ACALL	write_text

MOV	A,R3
ADD	A,R4
DEC	A
MOV	R0,A
MOV	B,#4
DIV	AB
ADD	A,R0
MOV	B,#7
DIV	AB
MOV	R0,B		;w R0 dzien tygodnia dla 1 stycznia danego roku

MOV	A,TL0		;w DPTR ilosc dni roku ktore minely dla podanego miesiaca
CJNE	A,#01h,weekday
MOV	DPTR,#0
SJMP	weekday11
weekday:
CJNE	A,#02h,weekday1
MOV	DPTR,#31
SJMP	weekday11
weekday1:
CJNE	A,#03h,weekday2
MOV	DPTR,#59
SJMP	weekday11
weekday2:
CJNE	A,#04h,weekday3
MOV	DPTR,#90
SJMP	weekday11
weekday3:
CJNE	A,#05h,weekday4
MOV	DPTR,#120
SJMP	weekday11
weekday4:
CJNE	A,#06h,weekday5
MOV	DPTR,#151
SJMP	weekday11
weekday5:
CJNE	A,#07h,weekday6
MOV	DPTR,#181
SJMP	weekday11
weekday6:
CJNE	A,#08h,weekday7
MOV	DPTR,#212
SJMP	weekday11
weekday7:
CJNE	A,#09h,weekday8
MOV	DPTR,#243
SJMP	weekday11
weekday8:
CJNE	A,#10h,weekday9
MOV	DPTR,#273
SJMP	weekday11
weekday9:
CJNE	A,#11h,weekday10
MOV	DPTR,#304
SJMP	weekday11
weekday10:
MOV	DPTR,#334

weekday11:
MOV	A,TH0		;lata / dni
ANL	A,#30h		;maska na starszy polbajt dni
SWAP	A
MOV	B,#10
MUL	AB
XCH	A,B
MOV	A,TH0		;lata / dni
ANL	A,#0Fh		;maska na mlodszy polbajt dni
ADD	A,B		;w ACC dni binarnie po konwersji z BCD na BIN (starszy polbajt mnozony przez 10 i dodany do mlodszego)
CLR	C
ADDC	A,DPL
JNC	weekday12
INC	DPH
weekday12:
MOV	DPL,A		;w DPTR dzien roku (liczba dni, ktore minely dla podanego miesiaca odczytane z tabeli powyzej + dzien miesiaca)

MOV	A,TL0
CJNE	R3,#0,weekday13
CJNE	A,#01h,weekday14
SJMP	weekday13
weekday14:
CJNE	A,#02h,weekday15
SJMP	weekday13
weekday15:
INC	DPTR		;dzien roku nalezy zwiekszyc o 1 jezeli podany miesiac jest po lutym oraz podany rok jest przestepny

weekday13:
MOV	A,R0
JZ	weekday18
weekday16:
INC	DPTR
DJNZ	R0,weekday16

weekday18:
CLR	C
MOV	A,DPL
SUBB	A,#1
JNC	weekday17
DEC	DPH
weekday17:
MOV	DPL,A

SETB	RS0
SETB	RS1
MOV	R2,DPH
MOV	R3,DPL
MOV	R4,#0
MOV	R5,#7
ACALL	dzielenie16_16
MOV	A,R1
CLR	RS0
CLR	RS1

norm40:
CJNE	A,#0,tue
MOV     DPTR,#MONDAY
ACALL	write_text
SJMP	main1

tue:
CJNE	A,#1,wed
MOV     DPTR,#TUESDAY
ACALL	write_text
SJMP	main1

wed:
CJNE	A,#2,thu
MOV     DPTR,#WEDNESDAY
ACALL	write_text
SJMP	main1

thu:
CJNE	A,#3,fri
MOV     DPTR,#THURSDAY
ACALL	write_text
SJMP	main1

fri:
CJNE	A,#4,sat
MOV     DPTR,#FRIDAY
ACALL	write_text
SJMP	main1

sat:
CJNE	A,#5,sun
MOV     DPTR,#SATURDAY
ACALL	write_text
SJMP	main1

sun:
MOV     DPTR,#SUNDAY
ACALL	write_text

main1:
MOV     A,#0C0h		;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms

;*********************** CZAS *******************************
ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#04h		;godziny
ACALL	write
ACALL	read_ack
ACALL	start
MOV	A,#SLA_RD
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_noack
ACALL	stop

MOV	B,A
ANL	A,#3Fh		;maska na godziny

CJNE	R5,#4,norm50	;jesli R5=5 to edycja godzin

PUSH	ACC
MOV	A,P3
ANL	A,#06h
CJNE	A,#0,norm54
POP	ACC
SJMP	norm50

norm54:
POP	ACC
JB	UP,norm55	;spr czy zostal wcisniety S3 (UP)
INC	A
CJNE	A,#0Ah,norm51	;spr czy nastapilo przejscie z 09h na 0Ah
MOV	A,#10h		;9 -> 10
SJMP	norm53
norm51:
CJNE	A,#1Ah,norm52	;spr czy nastapilo przejscie z 19h na 1Ah
MOV	A,#20h		;19 -> 20
SJMP	norm53
norm52:
CJNE	A,#24h,norm53	;spr czy nastapilo przejscie z 23h na 24h
MOV	A,#00h		;23 -> 00
SJMP	norm53

norm55:
JB	DOWN,norm50	;spr czy zostal wcisniety S2 (DOWN)
DEC	A
CJNE	A,#0Fh,norm56	;spr czy nastapilo przejscie z 10h na 0Fh
MOV	A,#09h		;10 -> 9
SJMP	norm53
norm56:
CJNE	A,#1Fh,norm57	;spr czy nastapilo przejscie z 20h na 1Fh
MOV	A,#19h		;20 -> 19
SJMP	norm53
norm57:
CJNE	A,#255,norm53	;spr czy nastapilo przejscie z 00h na FFh
MOV	A,#23h		;00 -> 23

norm53:
PUSH	ACC
ANL	B,#0C0h		;przywrocenie dwoch ostatnich bitow (format)
ADD	A,B
PUSH	ACC
ACALL	start		;przy kazdej zmianie na nowa wartosc nastepuje autosave
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#04h		;godziny
ACALL	write
ACALL	read_ack
POP	ACC
ACALL	write
ACALL	read_ack
ACALL	stop
POP	ACC

norm50:
PUSH	ACC
ANL	A,#30h		;maska na dziesiatki godzin (0-2)
SWAP	A
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
CJNE	R5,#4,norm5	;jesli R5=5 to edycja godzin
MOV     A,#0Eh		;zalaczenie kursora
ACALL   write_inst
MOV	R7,#120
ACALL	delay_ms
MOV	A,#0Ch		;wylaczenie kursora
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
norm5:
POP	ACC
ANL	A,#0Fh		;maska na jednostki godzin w BCD (0-9)
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char

CJNE	R5,#0,sec
ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#01h		;setne sekundy
ACALL	write
ACALL	read_ack
ACALL	start
MOV	A,#SLA_RD
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_noack
ACALL	stop

JNB	ACC.7,sec
MOV	A,#' '
ACALL	write_char
SJMP	sec1
sec:
MOV	A,#':'
ACALL	write_char
sec1:

ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#03h		;minuty
ACALL	write
ACALL	read_ack
ACALL	start
MOV	A,#SLA_RD
ACALL	write
ACALL	read_ack
ACALL	read
ACALL	write_noack
ACALL	stop

MOV	B,A
ANL	A,#7Fh		;maska na minuty

CJNE	R5,#5,norm69	;jesli R5=6 to edycja minut

PUSH	ACC
MOV	A,P3
ANL	A,#06h
CJNE	A,#0,norm67
POP	ACC
norm69:
SJMP	norm60

norm67:
POP	ACC
JB	UP,norm68	;spr czy zostal wcisniety S3 (UP)
INC	A
CJNE	A,#0Ah,norm61	;spr czy nastapilo przejscie z 09h na 0Ah
MOV	A,#10h		;9 -> 10
SJMP	norm66
norm61:
CJNE	A,#1Ah,norm62	;spr czy nastapilo przejscie z 19H na 1Ah
MOV	A,#20h		;19 -> 20
SJMP	norm66
norm62:
CJNE	A,#2Ah,norm63	;spr czy nastapilo przejscie z 29h na 2Ah
MOV	A,#30h		;29 -> 30
SJMP	norm66
norm63:
CJNE	A,#3Ah,norm64	;spr czy nastapilo przejscie z 39h na 3Ah
MOV	A,#40h		;39 -> 40
SJMP	norm66
norm64:
CJNE	A,#4Ah,norm65	;spr czy nastapilo przejscie z 49h na 4Ah
MOV	A,#50h		;49 -> 50
SJMP	norm66
norm65:
CJNE	A,#5Ah,norm66	;spr czy nastapilo przejscie z 59h na 5Ah
MOV	A,#00h
SJMP	norm66

norm68:
JB	DOWN,norm60	;spr czy zostal wcisniety S2 (DOWN)
DEC	A
CJNE	A,#0Fh,norm610	;spr czy nastapilo przejscie z 10h na 0Fh
MOV	A,#09h		;10 -> 9
SJMP	norm66
norm610:
CJNE	A,#1Fh,norm620	;spr czy nastapilo przejscie z 20H na 1Fh
MOV	A,#19h		;20 -> 19
SJMP	norm66
norm620:
CJNE	A,#2Fh,norm630	;spr czy nastapilo przejscie z 30h na 2Fh
MOV	A,#29h		;30 -> 29
SJMP	norm66
norm630:
CJNE	A,#3Fh,norm640	;spr czy nastapilo przejscie z 40h na 3Fh
MOV	A,#39h		;40 -> 39
SJMP	norm66
norm640:
CJNE	A,#4Fh,norm650	;spr czy nastapilo przejscie z 50h na 4Fh
MOV	A,#49h		;50 -> 49
SJMP	norm66
norm650:
CJNE	A,#0FFh,norm66	;spr czy nastapilo przejscie z 00h na FFh
MOV	A,#59h		;0 -> 59

norm66:
PUSH	ACC
ANL	B,#80h		;przywrocenie ostatniego bitu (format)
ADD	A,B
PUSH	ACC
ACALL	start		;przy kazdej zmianie na nowa wartosc nastepuje autosave
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#03h		;minuty
ACALL	write
ACALL	read_ack
POP	ACC
ACALL	write
ACALL	read_ack
ACALL	stop
POP	ACC

norm60:
PUSH	ACC
ANL	A,#70h		;maska na dziesiatki minut (0-5)
SWAP	A
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
CJNE	R5,#5,norm6	;jesli R5=6 to edycja minut
MOV     A,#0Eh		;zalaczenie kursora
ACALL   write_inst
MOV	R7,#120
ACALL	delay_ms
MOV     A,#0Ch		;wylaczenie kursora
ACALL   write_inst
MOV	R7,#1
ACALL	delay_ms
norm6:
POP	ACC
ANL	A,#0Fh		;maska na jednostki minut w BCD (0-9)
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char

MOV	DPTR,#SPACES
ACALL	write_text
MOV	DPTR,#SPACES
ACALL	write_text

;*********************** TEMPERATURA ************************
ACALL	rst
MOV	A,#0CCh		;komenda pominiecia ROM
ACALL	write_cmd
MOV	A,#44h		;komenda konwersji temperatury
ACALL	write_cmd

main2:
JNB	DQ,main2	;odczekanie na zakonczenie konwersji temperatury

ACALL	rst
MOV	A,#0CCh		;komenda pominiecia ROM
ACALL	write_cmd
MOV	A,#0BEh		;komenda odczytu scratchpad'a
ACALL	write_cmd

ACALL	read_data
ANL	A,#0F0h
SWAP	A
XCH	A,B		;w B cztery pierwsze bity zajmuja czesciowy wynik pomiaru

ACALL	read_data
ANL	A,#0Fh
SWAP	A		;w A cztery ostatnie bity zajmuja czesciowy wynik pomiaru
ADD	A,B		;suma A + B daje calkowity wynik gotowy do wyswietlenia
CLR	F0		;bit pomocniczy do przechowania znaku z pomiaru, 0 - temp dodatnia, 1 - temp ujemna
JNB	ACC.7,posit	;spr znaku na ostatnim bicie, 0 - wynik dodatni, 1 - wynik ujemny
SETB	F0
CPL	A		;transformacja liczby ujemnej (negacja + 1) z zachowaniem znaku w F0
INC	A
posit:
MOV	B,#10
DIV	AB		;calosc z dzielenia przez 10 w ACC, reszta w B

PUSH	B
PUSH	ACC

JNZ	two_digit	;spr czy wynik jest jednocyfrowy i jesli tak to zamiast zera na poczatku wstawiana jest spacja
MOV	A,#' '
ACALL	write_char
POP	ACC		;zrzut ze stosu zeby wyczyscic / zamknac pierwsza cyfre
POP	ACC		;zrzut ze stosu drugiej cyfry
JNZ	not_zero	;spr czy druga cyfra jest zerem
PUSH	ACC
MOV	A,#' '
ACALL	write_char
POP	ACC
SJMP	zero
not_zero:
PUSH	ACC		;jesli druga cyfra nie jest zerem to musi wrocic na stos
MOV	A,#'+'		;znak '+' jest domyslny
JNB	F0,plus		;spr czy wynik pomiaru dodatni czy ujemny
MOV	A,#'-'
plus:
ACALL	write_char
SJMP	one_digit
two_digit:
MOV	A,#'+'		;znak '+' jest domyslny
JNB	F0,plus1	;spr czy wynik pomiaru dodatni czy ujemny
MOV	A,#'-'
plus1:
ACALL	write_char
POP	ACC
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
one_digit:
POP	ACC
zero:
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV     DPTR,#DEG_CELS
ACALL	write_text

ACALL	home

AJMP	main

;*********************** PROCEDURY ****************************

;------------------------i2c----------------------------------
start:			;start
CLR	SCL
SETB	SDA
SETB	SCL
NOP
NOP
NOP
NOP
NOP
CLR	SDA
NOP
NOP
NOP
RET

stop:			;stop
CLR	SCL
CLR	SDA
NOP
NOP
NOP
NOP
SETB	SCL
NOP
NOP
NOP
NOP
NOP
SETB	SDA
RET

write_noack:		;wyslanie braku potwierdzenia
CLR	SCL
SETB	SDA
NOP
NOP
NOP
NOP
SETB	SCL
NOP
NOP
NOP
RET

read_ack:		;odczyt potwierdzenia
CLR	SCL
NOP
NOP
NOP
NOP
NOP
SETB	SCL
MOV	C,SDA
NOP
NOP
RET

write:			;zapis bajtu
MOV	R0,#8
write1:
CLR	SCL
RLC	A
MOV	SDA,C
NOP
NOP
SETB	SCL
NOP
DJNZ	R0,write1
RET

read:			;odczyt bajtu
MOV	R0,#8
read1:
CLR	SCL
NOP
NOP
NOP
NOP
NOP
SETB	SCL
MOV	C,SDA
RLC	A
DJNZ	R0,read1
RET

;------------------------HD44780-----------------------------
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

init:			;inicjalizacja LCD
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

ACALL	strobe
MOV	R7,#1
ACALL	delay_ms

MOV     P1,#20h
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
MOV     A,#0Ch		;zalaczenie wyswietlacza i kursora
ACALL   write_inst
MOV	R7,#1
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
MOV	R7,#1
ACALL	delay_ms
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

;------------------------1-wire---------------------------
rst:			;sekwencja inicjalizacji (reset)
CLR	DQ
MOV	R0,#50
ACALL	delay_10us
SETB	DQ
rst1:
JB	DQ,rst1
MOV	R0,#50
ACALL	delay_10us
RET

write_cmd:		;zapis komendy ROM / funkcji
CLR	C
MOV	R2,#8
write_cmd1:
CLR	DQ
NOP
NOP
NOP
NOP
RRC	A
MOV	DQ,C
MOV	R0,#6
ACALL	delay_10us
SETB	DQ
DJNZ	R2,write_cmd1
RET

read_data:		;odczyt danych z czujnika
MOV	R2,#8
read_data1:
CLR	DQ
MOV	R0,#5
SETB	DQ
read_data3:
DJNZ	R0,read_data3
MOV	C,DQ
RRC	A
MOV	R0,#6
ACALL	delay_10us
read_data2:
JNB	DQ,read_data2
DJNZ	R2,read_data1
RET

delay_10us:		;petla opozniajaca w ~10us (9,765us)
MOV     R1,#3
delay_10us1:
DJNZ    R1,delay_10us1
DJNZ    R0,delay_10us
RET

;---------------------autokorekta dni----------------------
days_ok:
PUSH	TH0		;w TH0 aktualne lata / dni (format RTC)
MOV	A,TL0		;w TL0 aktualny miesiac (BCD)

ANL	TH0,#3Fh	;maska na dni
MOV	R0,TH0		;dni w R0

POP	TH0
PUSH	TH0
ANL	TH0,#0C0h	;maska na lata
MOV	R1,TH0		;lata w R1 (na dwoch najstarszych bitach)

CJNE	R0,#31h,days_ok7
CJNE	A,#02h,days_ok2
CJNE	R1,#0,days_ok10
MOV	TH0,#29h
SJMP	days_ok6
days_ok10:
MOV	TH0,#28h
SJMP	days_ok6
days_ok2:
CJNE	A,#04h,days_ok3
MOV	TH0,#30h
SJMP	days_ok6
days_ok3:
CJNE	A,#06h,days_ok4
MOV	TH0,#30h
SJMP	days_ok6
days_ok4:
CJNE	A,#09h,days_ok5
MOV	TH0,#30h
SJMP	days_ok6
days_ok5:
CJNE	A,#11h,days_ok1
MOV	TH0,#30h
SJMP	days_ok6

days_ok7:
CJNE	R0,#30h,days_ok8
CJNE	A,#02h,days_ok1
CJNE	R1,#0,days_ok9
MOV	TH0,#29h
SJMP	days_ok6
days_ok9:
MOV	TH0,#28h
SJMP	days_ok6

days_ok8:
CJNE	R0,#29h,days_ok1
CJNE	A,#02h,days_ok1
MOV	A,R1
JZ	days_ok1
MOV	TH0,#28h

days_ok6:		;zapis skorygowanej wartosci dni
ACALL	start
MOV	A,#SLA_WR
ACALL	write
ACALL	read_ack
MOV	A,#05h		;lata / dni
ACALL	write
ACALL	read_ack
POP	ACC		;zrzut TH0 ze stosu
ANL	A,#0C0h		;maska na lata
ADD	A,TH0
PUSH	ACC		;korekta stosu + zachowanie na stosie skorygowanych / zmienionych dni
ACALL	write
ACALL	read_ack
ACALL	stop

days_ok1:
POP	TH0
RET

;---------------------dzielenie16_16----------------------
dzielenie16_16: ;dzielenie 16 bitow przez 16 bitow
;we: r2 - H dzielna
; r3 - L dzielna
; r4 - H dzielnik
; r5 - L dzielnik
;wy: r2 - H czesc calkowita
; r3 - L czesc calkowita
; r0 - H reszta
; r1 - L reszta
;zmienia: acc, psw, r7

;algorytm:
; Hi:=0
; Lo:=dzielna
; wy:=0
; repit 16 razy
; {
; shift_left_32bit (Hi,Lo)
; if Hi>=dzielnik
; {wy:=2*wy+1; Hi:=Hi-dzielnik}
; else
; wy:=wy*2
; }

mov r0,#0
mov r1,#0
mov r7,#16

dziel1: clr c ;przesuniecie w lewo r0,r1,r2,r3
mov a,r3 ;i tym samym pomnozenie wy*2 (wy=r2,r3)
rlc a
mov r3,a
mov a,r2
rlc a
mov r2,a
mov a,r1
rlc a
mov r1,a
mov a,r0
rlc a
mov r0,a

;czy Hi>=dzielnik (R0,R1>=r4,r5)
mov a,r1
subb a,r5
mov a,r0
subb a,r4
jc dziel2

mov a,r3 ;wy:=wy+1
orl a,#00000001b
mov r3,a

clr c ;Hi:=Hi-dzielnik (R0,R1:=R0,R1-R4,R5)
mov a,r1
subb a,r5
mov r1,a
mov a,r0
subb a,r4
mov r0,a

dziel2: djnz r7,dziel1

ret

;------------------------stale---------------------------
DEG_CELS:
DB	0DFh,'C',0

MONDAY:
DB	'MON',0

TUESDAY:
DB	'TUE',0

WEDNESDAY:
DB	'WED',0

THURSDAY:
DB	'THU',0

FRIDAY:
DB	'FRI',0

SATURDAY:
DB	'SAT',0

SUNDAY:
DB	'SUN',0

SPACES:
DB	'   ',0

END