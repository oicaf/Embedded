; sterownik HVAC oparty na regulatorze z histereza +/- 0,5^C
; ustawianie temperatury przyciskami S1 (zmniejszanie) i S3 (zwiekszanie)
; pomiar temperatury z dwoch czujnikow, wewnetrznego i zewnetrznego (DS18B20)
; wyswietlanie na wyswietlaczu mono / graficznym LCD 128x64 (ST7920-0B)
; dioda LD1 (czerwona) -> grzanie, dioda LD5 (zielona) -> chlodzenie

; polaczenia na plycie AVT-2500:
; od P1.0 do LD1
; od P1.1 do LD5
; od P1.2 do RS (CS*)
; od P1.3 do EN (SCLK*)
; od 1WIRE do P3.1
; od S1 do P3.2
; od S3 do P3.3
; podpiac dwa czujniki DS18B20 do CON9 (VCC, 1WIRE, GND)

; polaczenia od wyswietlacza graficznego LCD do plyty AVT-2500:
; sygnaly ktore sa 1:1 z LCD 16x2 wyprowadzone sa na gotowym zlaczu pasujacym do gniazda dla wyswietlaczy
; od pinu 5 (R/W) do P3.0 (SID*)
; od pinu 15 (PSB) do GND
; od pinu 19 (BLA) do VCC
; od pinu 20 (BLK) do GND

HEAT	BIT	P1.0	;LD1
COOL	BIT	P1.1	;LD5
CS	BIT	P1.2
SCLK	BIT	P1.3
SID	BIT	P3.0
TEMP	BIT	P3.1

SJMP	30h

ORG	03h		;obsluga przerwania zewnetrznego INT0
CLR	IE.7
ACALL	down
ACALL	disp_set
SETB	IE.7
RETI

ORG	13h		;obsluga przerwania zewnetrznego INT1
CLR	IE.7
ACALL	up
ACALL	disp_set
SETB	IE.7
RETI

ORG	30h
SETB	CS
MOV	IE,#05h		;zezwolenie na przerwania z zewnatrz (INT0 i INT1)
MOV	TCON,#05h	;oba przerwania na opadajace zbocze
MOV	TH0,#22		;domyslna temperatura nastawna (czesc calkowita 22^C)
MOV	TL0,#0		;domyslna temperatura nastawna (czesc po przecinku ,0^C)
MOV	20h,#0		;0 - tryb norm, 1 - tryb grzania, 2 - tryb chlodzenia
ACALL	init

; odczyt z czujnika temp unikalnego 64-bitowego kodu / nr ID (do 1-wire moze byc w tym czasie wpiety tylko jeden czujnik)
; wyswietlenie numeru na LCD w kodzie hex poczawszy od lewej strony (LSB -> MSB)
; uzycie tylko w przypadku gdy np. nastepuje wymiana czujnika temp gdzie konieczne jest zaprogramowanie w ponizszym kodzie nowego czujnika temp

;ACALL	rst
;MOV	A,#33h		;read ROM
;ACALL	write_cmd
;MOV	B,#8
;tmp:
;ACALL	read_data
;PUSH	ACC
;ANL	A,#0F0h
;SWAP	A
;ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
;ACALL	write_char
;POP	ACC
;ANL	A,#0Fh
;ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
;ACALL	write_char
;DJNZ	B,tmp
;SJMP	$

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
ACALL	clear_g
MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

; DOMEK
MOV	DPTR,#house	;mapa bitowa domku
MOV	R2,#0
MOV	R3,#4
MOV	R5,#32
loop1:
MOV	A,#80h
ADD	A,R2		;ustawienie adresu pionowego od 0 do 31
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R3		;ustawienie adresu poziomego od 4 do 7
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	R4,#4
loop2:
CLR	A
MOVC	A,@A+DPTR	;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
INC	DPTR
CLR	A
MOVC	A,@A+DPTR	;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
INC	DPTR
DJNZ	R4,loop2
INC	R2
MOV	R3,#4
DJNZ	R5,loop1

MOV	R2,#0
MOV	R3,#12
MOV	R5,#8
loop3:
MOV	A,#80h
ADD	A,R2		;ustawienie adresu pionowego od 0 do 7
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R3		;ustawienie adresu poziomego od 12 do 15
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	R4,#4
loop4:
CLR	A
MOVC	A,@A+DPTR	;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
INC	DPTR
CLR	A
MOVC	A,@A+DPTR	;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
INC	DPTR
DJNZ	R4,loop4
INC	R2
MOV	R3,#12
DJNZ	R5,loop3
MOV     A,#22h		;magistrala 4-bit, podstawowy zestaw instrukcji, wyswietlacz graficzny wlaczony
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
ACALL	disp_set

; PROGRAM GLOWNY
main:
CLR	IE.7		;dezaktywacja przerwan na czas wyswietlania temp zewn i wewn
MOV	A,#90h		;przejscie do wiersza 2 i kolumny 3 (HCGROM)
ACALL	write_inst
MOV	R7,#10
ACALL	delay_10us

; TEMPERATURA ZEWN.
ACALL	rst
MOV	A,#55h		;komenda dobrania ROM
ACALL	write_cmd
MOV	B,#8
MOV	DPTR,#temp_ext
main21:
CLR	A
MOVC	A,@A+DPTR	;wyslanie do wybranego czujnika unikalnego 64-bitowego kodu (ID)
ACALL	write_cmd
INC	DPTR
DJNZ	B,main21
MOV	A,#44h		;komenda konwersji temperatury
ACALL	write_cmd
main1:
JNB	TEMP,main1	;odczekanie na zakonczenie konwersji temperatury
ACALL	rst
MOV	A,#55h		;komenda dobrania ROM
ACALL	write_cmd
MOV	B,#8
MOV	DPTR,#temp_ext
main22:
CLR	A
MOVC	A,@A+DPTR	;wyslanie do wybranego czujnika unikalnego 64-bitowego kodu (ID)
ACALL	write_cmd
INC	DPTR
DJNZ	B,main22
MOV	A,#0BEh		;komenda odczytu brudnopisu
ACALL	write_cmd
ACALL	read_data
MOV	DPL,A
ACALL	read_data
MOV	DPH,A
MOV	C,ACC.7
MOV	F0,C		;znak w F0 (0 - wynik dodatni, 1 - wynik ujemny)
JNB	F0,main2	;jesli wynik ujemny to transformacja liczby ujemnej
MOV	A,DPL
CPL	A
ADD	A,#1
MOV	DPL,A
MOV	A,DPH
CPL	A
ADDC	A,#0
MOV	DPH,A
main2:
SWAP	A
XCH	A,B		;w B cztery pierwsze bity zajmuja czesciowy wynik pomiaru (czesc calkowita)
MOV	A,DPL
ANL	A,#0F0h
SWAP	A		;w A cztery ostatnie bity zajmuja czesciowy wynik pomiaru (czesc calkowita)
ADD	A,B		;suma A + B daje wynik (czesc calkowita)
MOV	B,#10
DIV	AB		;calosc z dzielenia przez 10 w ACC, reszta w B
PUSH	B
PUSH	ACC
JNZ	main3		;spr czy wynik jest jednocyfrowy i jesli tak to zamiast zera na poczatku wstawiana jest spacja
MOV	A,#' '
ACALL	write_char
POP	ACC		;zrzut ze stosu zeby wyczyscic / zamknac pierwsza cyfre
POP	ACC		;zrzut ze stosu drugiej cyfry
JNZ	main4		;spr czy druga cyfra jest zerem
MOV	A,DPL
ANL	A,#0Eh
JNZ	main28		;spr czy wynik po przecinku (tylko pierwsza cyfra) jest zerem
MOV	A,#' '
ACALL	write_char
MOV	A,#' '
ACALL	write_char
MOV	A,#' '
ACALL	write_char
MOV	A,#'0'
ACALL	write_char
SJMP	main29
main28:
JB	F0,main27
MOV	A,#' '		;znak '+' nie jest wyswietlany
ACALL	write_char
SJMP	main33
main27:
MOV	A,#'-'
ACALL	write_char
main33:
CLR	A
SJMP	main5
main4:
PUSH	ACC		;jesli druga cyfra nie jest zerem to musi wrocic na stos
MOV	A,#' '		;znak '+' jest domyslny i nie jest wyswietlany
JNB	F0,main6	;spr czy wynik pomiaru dodatni czy ujemny
MOV	A,#'-'
main6:
ACALL	write_char
SJMP	main7
main3:
MOV	A,#' '		;znak '+' jest domyslny i nie jest wyswietlany
JNB	F0,main8	;spr czy wynik pomiaru dodatni czy ujemny
MOV	A,#'-'
main8:
ACALL	write_char
POP	ACC
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
main7:
POP	ACC
main5:
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	A,#','
ACALL	write_char
MOV	A,DPL
ANL	A,#0Fh		;wyodrebnienie pierwszej cyfry po przecinku (0/1*6 + 0/1*12 + 0/1*25 + 0/1*50 = wynik/10 -> czesc calkowita z dzielenia)
RRC	A
PUSH	ACC
CLR	A
MOV	ACC.0,C
MOV	B,#6
MUL	AB
XCH	A,R5
POP	ACC
RRC	A
PUSH	ACC
CLR	A
MOV	ACC.0,C
MOV	B,#12
MUL	AB
ADD	A,R5
XCH	A,R5
POP	ACC
RRC	A
PUSH	ACC
CLR	A
MOV	ACC.0,C
MOV	B,#25
MUL	AB
ADD	A,R5
XCH	A,R5
POP	ACC
RRC	A
CLR	A
MOV	ACC.0,C
MOV	B,#50
MUL	AB
ADD	A,R5
MOV	B,#10
DIV	AB
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
main29:
MOV     DPTR,#deg_cels
ACALL	write_text
MOV	A,#' '
ACALL	write_char

; TEMPERATURA WEWN.
ACALL	rst
MOV	A,#55h		;komenda dobrania ROM
ACALL	write_cmd
MOV	B,#8
MOV	DPTR,#temp_int
main19:
CLR	A
MOVC	A,@A+DPTR	;wyslanie do wybranego czujnika unikalnego 64-bitowego kodu (ID)
ACALL	write_cmd
INC	DPTR
DJNZ	B,main19
MOV	A,#44h		;komenda konwersji temperatury
ACALL	write_cmd
main9:
JNB	TEMP,main9	;odczekanie na zakonczenie konwersji temperatury
ACALL	rst
MOV	A,#55h		;komenda dobrania ROM
ACALL	write_cmd
MOV	B,#8
MOV	DPTR,#temp_int
main20:
CLR	A
MOVC	A,@A+DPTR	;wyslanie do wybranego czujnika unikalnego 64-bitowego kodu (ID)
ACALL	write_cmd
INC	DPTR
DJNZ	B,main20
MOV	A,#0BEh		;komenda odczytu brudnopisu
ACALL	write_cmd
ACALL	read_data
MOV	DPL,A
ACALL	read_data
MOV	DPH,A
MOV	C,ACC.7
MOV	F0,C		;znak w F0 (0 - wynik dodatni, 1 - wynik ujemny)
JNB	F0,main10	;jesli wynik ujemny to transformacja liczby ujemnej
MOV	A,DPL
CPL	A
ADD	A,#1
MOV	DPL,A
MOV	A,DPH
CPL	A
ADDC	A,#0
MOV	DPH,A
main10:
SWAP	A
XCH	A,B		;w B cztery pierwsze bity zajmuja czesciowy wynik pomiaru (czesc calkowita)
MOV	A,DPL
ANL	A,#0F0h
SWAP	A		;w A cztery ostatnie bity zajmuja czesciowy wynik pomiaru (czesc calkowita)
ADD	A,B		;suma A + B daje wynik (czesc calkowita)
MOV	TH1,A
MOV	B,#10
DIV	AB		;calosc z dzielenia przez 10 w ACC, reszta w B
PUSH	B
PUSH	ACC
JNZ	main11		;spr czy wynik jest jednocyfrowy i jesli tak to zamiast zera na poczatku wstawiana jest spacja
MOV	A,#' '
ACALL	write_char
POP	ACC		;zrzut ze stosu zeby wyczyscic / zamknac pierwsza cyfre
POP	ACC		;zrzut ze stosu drugiej cyfry
JNZ	main12		;spr czy druga cyfra jest zerem
MOV	A,DPL
ANL	A,#0Eh
JNZ	main31		;spr czy wynik po przecinku (tylko pierwsza cyfra) jest zerem
MOV	A,#' '
ACALL	write_char
MOV	A,#' '
ACALL	write_char
MOV	A,#' '
ACALL	write_char
MOV	A,#'0'
ACALL	write_char
SJMP	main32
main31:
JB	F0,main30
MOV	A,#' '		;znak '+' nie jest wyswietlany
ACALL	write_char
SJMP	main34
main30:
MOV	A,#'-'
ACALL	write_char
main34:
CLR	A
SJMP	main13
main12:
PUSH	ACC		;jesli druga cyfra nie jest zerem to musi wrocic na stos
MOV	A,#' '		;znak '+' jest domyslny i nie jest wyswietlany
JNB	F0,main14	;spr czy wynik pomiaru dodatni czy ujemny
MOV	A,#'-'
main14:
ACALL	write_char
SJMP	main15
main11:
MOV	A,#' '		;znak '+' jest domyslny i nie jest wyswietlany
JNB	F0,main16	;spr czy wynik pomiaru dodatni czy ujemny
MOV	A,#'-'
main16:
ACALL	write_char
POP	ACC
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
main15:
POP	ACC
main13:
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	A,DPL
ANL	A,#0Fh		;wyodrebnienie pierwszej cyfry po przecinku (0/1*6 + 0/1*12 + 0/1*25 + 0/1*50 = wynik/10 -> czesc calkowita z dzielenia)
RRC	A
PUSH	ACC
CLR	A
MOV	ACC.0,C
MOV	B,#6
MUL	AB
XCH	A,R5
POP	ACC
RRC	A
PUSH	ACC
CLR	A
MOV	ACC.0,C
MOV	B,#12
MUL	AB
ADD	A,R5
XCH	A,R5
POP	ACC
RRC	A
PUSH	ACC
CLR	A
MOV	ACC.0,C
MOV	B,#25
MUL	AB
ADD	A,R5
XCH	A,R5
POP	ACC
RRC	A
CLR	A
MOV	ACC.0,C
MOV	B,#50
MUL	AB
ADD	A,R5
XCH	A,R5
MOV	A,#','
ACALL	write_char
XCH	A,R5
MOV	B,#10
DIV	AB
MOV	TL1,A
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
main32:
MOV     DPTR,#deg_cels
ACALL	write_text
MOV	A,#' '
ACALL	write_char
SETB	IE.7		;aktywacja przerwan

; REGULATOR
JNB	F0,main35	;jesli temp wewn na minusie to grzanie do momentu osiagniecia conajmniej 0^C
CLR	HEAT		;wlaczenie grzania
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#1		;tryb grzania
AJMP	main36
main35:
MOV	A,TH0
CLR	C
SUBB	A,TH1
JZ	main37		;spr czy roznica temp zadanej i wewn wynosi zero (tylko czesc calkowita przed przecinkiem)
JC	main38		;spr czy roznica temp zadanej i wewn jest dodatnia to grzanie (tylko czesc calkowita przed przecinkiem)
CJNE	A,#1,main41	;pr czy roznica temp zadanej i wewn jest rowna 1 (tylko czesc calkowita przed przecinkiem)
MOV	A,TL1
CLR	C
SUBB	A,TL0
CLR	C
SUBB	A,#6
JNC	main25		;jesli roznica temp wewn i zadanej >=6 (histereza) = grzanie
CLR	HEAT		;wlaczenie grzania
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#1		;tryb grzania
SJMP	main36
main25:
MOV	A,20h
CJNE	A,#2,main36	;spr czy tryb chlodzenia
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#0		;tryb norm
SJMP	main36
main41:
CLR	HEAT		;wlaczenie grzania
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#1		;tryb grzania
SJMP	main36
main38:
CLR	COOL		;wlaczenie chlodzenia
SETB	HEAT		;wylaczenie grzania
MOV	20h,#2		;tryb chlodzenia
SJMP	main36
main37:
MOV	A,TL0
CLR	C
SUBB	A,TL1
JC	main39		;spr roznicy temp zadanej i wewn (tylko czesc po przecinku)
JNZ	main40		;spr czy roznica temp zadanej minus wewn nie jest zerem (tylko czesc po przecinku)
SETB	HEAT		;wylaczenie grzania
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#0		;tryb norm
SJMP	main36
main40:
CLR	C
SUBB	A,#5
JC	main24		;jesli roznica temp zadanej i wewn >=5 (histereza) = grzanie
CLR	HEAT		;wlaczenie grzania
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#1		;tryb grzania
SJMP	main36
main24:
MOV	A,20h
CJNE	A,#2,main36	;spr czy tryb chlodzenia
SETB	COOL		;wylaczenie chlodzenia
MOV	20h,#0		;tryb norm
SJMP	main36
main39:
CPL	A
INC	A
CLR	C
SUBB	A,#5
JC	main23		;jesli roznica temp zadanej i wewn >=5 (histereza) = chlodzenie
CLR	COOL		;wlaczenie chlodzenia
SETB	HEAT		;wylaczenie grzania
MOV	20h,#2		;tryb chlodzenia
SJMP	main36
main23:
MOV	A,20h
CJNE	A,#1,main36	;spr czy tryb grzania
SETB	HEAT		;wylaczenie grzania
MOV	20h,#0		;tryb norm
main36:
MOV	R5,#4
main26:
MOV	R7,#250
ACALL	delay_ms
DJNZ	R5,main26
AJMP	main

; ST7920
write_inst:		;zapis instrukcji
MOV	R7,#5
write_inst1:
CLR	SCLK
SETB	SID
SETB	SCLK
DJNZ	R7,write_inst1
MOV	R7,#3
write_inst6:
CLR	SCLK
CLR	SID
SETB	SCLK
DJNZ	R7,write_inst6
MOV	R7,#4
write_inst2:
CLR	SCLK
RLC	A
MOV	SID,C
SETB	SCLK
DJNZ	R7,write_inst2
MOV	R7,#4
write_inst3:
CLR	SCLK
CLR	SID
SETB	SCLK
DJNZ	R7,write_inst3
MOV	R7,#4
write_inst4:
CLR	SCLK
RLC	A
MOV	SID,C
SETB	SCLK
DJNZ	R7,write_inst4
MOV	R7,#4
write_inst5:
CLR	SCLK
CLR	SID
SETB	SCLK
DJNZ	R7,write_inst5
CLR	SCLK
RET

write_data:		;zapis danych
MOV	R7,#5
write_data1:
CLR	SCLK
SETB	SID
SETB	SCLK
DJNZ	R7,write_data1
CLR	SCLK
CLR	SID
SETB	SCLK
CLR	SCLK
SETB	SID
SETB	SCLK
CLR	SCLK
CLR	SID
SETB	SCLK
MOV	R7,#4
write_data2:
CLR	SCLK
RLC	A
MOV	SID,C
SETB	SCLK
DJNZ	R7,write_data2
MOV	R7,#4
write_data3:
CLR	SCLK
CLR	SID
SETB	SCLK
DJNZ	R7,write_data3
MOV	R7,#4
write_data4:
CLR	SCLK
RLC	A
MOV	SID,C
SETB	SCLK
DJNZ	R7,write_data4
MOV	R7,#4
write_data5:
CLR	SCLK
CLR	SID
SETB	SCLK
DJNZ	R7,write_data5
CLR	SCLK
RET

init:			;inicjalizacja LCD
MOV	R7,#100
ACALL	delay_ms
MOV     A,#20h		;magistrala 4-bit, podstawowy zestaw instrukcji
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
MOV	R7,#10
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

clear_g:		;kasowanie wyswietlacza graficznego
MOV	R5,#32
clear_g1:
MOV	A,#7Fh		;ustawienie adresu pionowego (Y=31 do 0)
ADD	A,R5
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego (X=0)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	R4,#16
clear_g2:
MOV	A,#00h		;zgaszenie 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#00h		;zgaszenie 8 kolejnych pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R4,clear_g2
DJNZ	R5,clear_g1
RET

; DS18B20
rst:			;sekwencja inicjalizacji (reset)
CLR	TEMP
MOV	R7,#50
ACALL	delay_10us
SETB	TEMP
rst1:
JB	TEMP,rst1
MOV	R7,#50
ACALL	delay_10us
RET

write_cmd:		;zapis komendy ROM / funkcji
CLR	C
MOV	R5,#8
write_cmd1:
CLR	TEMP
NOP
NOP
NOP
NOP
RRC	A
MOV	TEMP,C
MOV	R7,#6
ACALL	delay_10us
SETB	TEMP
DJNZ	R5,write_cmd1
RET

read_data:		;odczyt danych z czujnika
MOV	R5,#8
read_data1:
CLR	TEMP
MOV	R4,#5
SETB	TEMP
read_data3:
DJNZ	R4,read_data3
MOV	C,TEMP
RRC	A
MOV	R7,#6
ACALL	delay_10us
read_data2:
JNB	TEMP,read_data2
DJNZ	R5,read_data1
RET

; PROCEDURY DLA PRZERWAN
down:			;zmniejszanie zadanej temperatury
MOV	R7,#250
ACALL	delay_ms
MOV	A,TL0
CLR	C
SUBB	A,#5		;skok o -0,5^C
JNC	down1
CPL	A
INC	A
down1:
MOV	TL0,A
CJNE	A,#5,down2
DEC	TH0
down2:
MOV	A,TH0
CJNE	A,#9,down3	;prog min to +10^C
MOV	TH0,#10
MOV	TL0,#0
down3:
RET

up:			;zwiekszanie zadanej temperatury
MOV	R7,#250
ACALL	delay_ms
MOV	A,TL0
ADD	A,#5		;skok o +0,5^C
MOV	TL0,A
CJNE	A,#10,up1
MOV	TL0,#0
SJMP	up2
up1:
MOV	A,TH0
CJNE	A,#39,up3	;prog max to +39^C
MOV	TH0,#39
MOV	TL0,#0
SJMP	up3
up2:
INC	TH0
up3:
RET

disp_set:		;wyswietlanie zadanej temperatury
MOV	A,#99h		;przejscie do wiersza 4 i kolumny 5 (HCGROM)
ACALL	write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#'-'
ACALL	write_char
MOV	A,#19h
ACALL	write_char
MOV	A,#' '
ACALL	write_char
MOV	A,TH0
MOV	B,#10
DIV	AB		;calosc z dzielenia przez 10 w ACC, reszta w B
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	A,B
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV	A,#','
ACALL	write_char
MOV	A,TL0
ADD	A,#30h		;wg tabeli ASCII cyfry od 0 do 9 to 30h + (0-9)h
ACALL	write_char
MOV     DPTR,#deg_cels
ACALL	write_text
MOV	A,#' '
ACALL	write_char
MOV	A,#18h
ACALL	write_char
MOV	A,#'+'
ACALL	write_char
RET

; PETLE OPOZNIAJACE
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

; STALE
house:
DB	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB	00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
DB	00h, 00h, 00h, 01h, 80h, 3eh, 00h, 00h
DB	00h, 00h, 00h, 06h, 60h, 22h, 00h, 00h
DB	00h, 00h, 00h, 18h, 18h, 22h, 00h, 00h
DB	00h, 00h, 00h, 60h, 06h, 22h, 00h, 00h
DB	00h, 00h, 01h, 80h, 01h,0a2h, 00h, 00h
DB	00h, 00h, 06h, 00h, 00h, 62h, 00h, 00h
DB	00h, 00h, 18h, 00h, 00h, 1ah, 00h, 00h
DB	00h, 00h, 60h, 00h, 00h, 06h, 00h, 00h
DB	00h, 01h, 80h, 00h, 00h, 01h, 80h, 00h
DB	00h, 06h, 00h, 00h, 00h, 00h, 60h, 00h
DB	00h, 18h, 00h, 00h, 00h, 00h, 18h, 00h
DB	00h, 60h, 00h, 00h, 00h, 00h, 06h, 00h
DB	01h, 80h, 00h, 00h, 00h, 00h, 01h, 80h
DB	06h, 00h, 00h, 00h, 00h, 00h, 00h, 60h
DB	1Ch, 00h, 00h, 00h, 00h, 00h, 00h, 38h
DB	64h, 00h, 00h, 00h, 00h, 00h, 00h, 26h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	04h, 00h, 00h, 00h, 00h, 00h, 00h, 20h
DB	07h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh, 0e0h
    
deg_cels:
DB	'^C',0

temp_int:		;kod / nr ID czujnika temp wewnetrznej
DB	28h,0FFh,64h,0Eh,71h,3Dh,5Bh,48h

temp_ext:		;kod / nr ID czujnika temp zewnetrznej
DB	28h,0CFh,0A4h,1Ch,59h,20h,01h,0C9h

END