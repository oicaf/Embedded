; program demonstracyjny obslugujacy myszke PC (PS/2) z wyswietlaniem na monochromatycznym wyswietlaczu graficznym LCD 128x64 opartym na kontrolerze ST7920-0B

; polaczenia na plycie AVT-2500:
; podpiac gniazdo PS/2 do CON9 (VCC, CLK -> SCL, DATA -> SDA, GND)
; dodac dwa rezystory 4k7 na zlaczu "9", miedzy VCC i SCL, miedzy VCC i SDA
; wykonac zworke przy zlaczu "9" od SDA do P3.1
; wykonac zworke przy zlaczu "9" od SCL do P3.2
; wykonac zworke od P1.2 do RS (CS*)
; wykonac zworke od P1.3 do EN (SCLK*)

; polaczenia od wyswietlacza graficznego LCD do plyty AVT-2500:
; sygnaly ktore sa 1:1 z LCD 16x2 wyprowadzone sa na gotowym zlaczu pasujacym do gniazda dla wyswietlaczy
; wykonac zworke od pinu 5 (R/W) do P3.3 (SID*)
; wykonac zworke od pinu 15 (PSB) do GND
; wykonac zworke od pinu 19 (BLA) do VCC oraz od pinu 20 (BLK) do GND

CS	BIT	P1.2
SCLK	BIT	P1.3
DAT	BIT	P3.1
CLK	BIT	P3.2
SID	BIT	P3.3
RW	BIT	PSW.1	;RW = 0 (zapis do myszki), RW = 1 (odczyt z myszki)

SJMP	30h

ORG	03h		;obsluga przerwania zewnetrznego INT0
JNB	RW,write
ACALL	read_bit
SJMP	int0_end
write:
ACALL	write_bit
int0_end:
RETI

ORG	30h
SETB	CS
SETB	RW
MOV	IE,#81h		;zezwolenie na przerwanie z zewnatrz (INT0)
MOV	TCON,#01h	;przerwanie na opadajace zbocze
MOV	R4,#0		;licznik bitow (1-11)
ACALL	init

MOV	DPTR,#mouse_init
ACALL	write_text
self:
CJNE	R4,#11,self	;spr czy ostatni bit (11) zostal odebrany
MOV	R4,#0
CJNE	A,#0AAh,self1	;spr czy self-test OK (pierwszy bajt) lub spr mouse ID (drugi bajt)
SJMP	self
self1:
CJNE	A,#0FCh,self2	;spr czy self-test NOK
MOV	DPTR,#mouse_nok
ACALL	write_text
SJMP	$		;zatrzymanie programu
self2:
CJNE	A,#00h,self3	;spr czy mouse ID = 00h
MOV	DPTR,#mouse_ok
ACALL	write_text
MOV	R5,#8
self4:
MOV	R7,#250
ACALL	delay_ms
DJNZ	R5,self4
SJMP	self5
self3:
MOV	DPTR,#mouse_nok
ACALL	write_text
SJMP	$		;zatrzymanie programu
self5:

ACALL	clear
MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
ACALL	clear_g
MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R0,#3Fh
CLR	A
ram:			;wyczyszczenie (00h) wewn RAM (pamiec ekranu) w obszarze od 20h do 3Fh
MOV	@R0,A
CJNE	R0,#20h,ram1
SJMP	ram2
ram1:
DJNZ	R0,ram
ram2:

MOV	R0,#8		;wartosc poczatkowa kursora w pionie Y (srodek pola 16x16)
MOV	DPTR,#0100h	;wartosc poczatkowa kursora w poziomie X (srodek pola 16x16)
MOV	A,#80h
ADD	A,R0		;ustawienie adresu pionowego = 8
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego = 0 (pierwsze 16 pixeli od lewej)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,DPH		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,DPL		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us

dat_rep:		;wyslanie komendy Enable Data Reporting
CLR	RW
MOV	A,#0F4h		;zezwolenie na wysylanie pakietow danych (Enable Data Reporting)
CLR	CLK
MOV	R7,#10
ACALL	delay_10us
CLR	DAT
SETB	CLK
dat_rep1:
CJNE	R4,#12,dat_rep1	;spr czy ostatni bit zostal przetworzony
MOV	R4,#0
SETB	RW
dat_rep2:
CJNE	R4,#11,dat_rep2	;spr czy ostatni bit (11) zostal odebrany
MOV	R4,#0
CJNE	A,#0FAh,dat_rep3	;spr potwierdzenia przyjecia wczesniejszej komendy przez myszke (Acknowledge)
SJMP	main
dat_rep3:
AJMP	error

main:
CJNE	R4,#11,main	;spr czy ostatni bit (11) zostal odebrany
MOV	R4,#0
MOV	R1,A		;pierwszy bajt w R1 (status)
main1:
CJNE	R4,#11,main1	;spr czy ostatni bit (11) zostal odebrany
MOV	R4,#0
MOV	R2,A		;drugi bajt w R2 (przesuniecie w poziomie X)
main2:
CJNE	R4,#11,main2	;spr czy ostatni bit (11) zostal odebrany
MOV	R4,#0
MOV	R3,A		;trzeci bajt w R3 (przesuniecie w pionie Y)
			;usuniecie kursora z biezacej pozycji zeby go wyswietlic w nowej pozycji
MOV	A,#80h
ADD	A,R0		;ustawienie adresu pionowego (biezaca pozycja)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego = 0 (pierwsze 16 pixeli od lewej)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#00h		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#00h		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
			;wyswietlenie wartosci spod adresu RAM (pamiec ekranu od 20h do 3Fh) dla biezacej pozycji
MOV	A,#80h		
ADD	A,R0		;ustawienie adresu pionowego (biezaca pozycja)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego = 0 (pierwsze 16 pixeli od lewej)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,R0
ADD	A,#20h
MOV	R0,A
MOV	A,@R0		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,R0
ADD	A,#16
MOV	R0,A
MOV	A,@R0		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,R0
CLR	C
SUBB	A,#30h
MOV	R0,A
			;obrobka ruchu w pionie Y
MOV	A,R3
JZ	main4		;spr czy brak ruchu w pionie
MOV	A,R1
JNB	ACC.5,main3	;spr znaku (czy ujemna wartosc)
MOV	A,R3
CPL	A
INC	A
MOV	R3,A
MOV	A,R0
ADD	A,R3
PUSH	ACC
ANL	A,#0F0h
JNZ	main8		;spr czy kursor poza zakresem
POP	ACC
MOV	R0,A		;nowa pozycja w R0 (przesuniecie w dol)
SJMP	main4
main8:
POP	ACC
MOV	R0,#15		;nowa pozycja w R0 (przesuniecie w dol), max limit zakresu
SJMP	main4
main3:
MOV	A,R0
CLR	C
SUBB	A,R3
PUSH	ACC
JC	main9
POP	ACC
MOV	R0,A		;nowa pozycja w R0 (przesuniecie w gore)
SJMP	main4
main9:
POP	ACC
MOV	R0,#0		;nowa pozycja w R0 (przesuniecie w gore), max limit zakresu

main4:			;obrobka ruchu w poziomie X
MOV	A,R2
JZ	main7		;spr czy brak ruchu w poziomie
CLR	C
MOV	A,R1
JNB	ACC.4,main6	;spr znaku (czy ujemna wartosc)
MOV	A,R2
CPL	A
INC	A
MOV	R2,A
main5:
MOV	A,DPL
RLC	A
MOV	DPL,A
MOV	A,DPH
RLC	A
JNC	main10
MOV	DPTR,#8000h	;nowa pozycja w DPTR (przesuniecie w lewo), max limit zakresu
SJMP	main7
main10:
MOV	DPH,A
DJNZ	R2,main5	;nowa pozycja w DPTR (przesuniecie w lewo)
SJMP	main7
main6:
MOV	A,DPH
RRC	A
MOV	DPH,A
MOV	A,DPL
RRC	A
JNC	main11
MOV	DPTR,#0001h	;nowa pozycja w DPTR (przesuniecie w prawo), max limit zakresu
SJMP	main7
main11:
MOV	DPL,A
DJNZ	R2,main6	;nowa pozycja w DPTR (przesuniecie w prawo)

main7:			;wyswietlenie kursora + wyswietlenie wartosci spod adresu RAM (pamiec ekranu od 20h do 3Fh) dla nowej pozycji
MOV	A,#80h
ADD	A,R0		;ustawienie nowego adresu pionowego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego = 0 (pierwsze 16 pixeli od lewej)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,R0
PUSH	ACC
ADD	A,#20h
MOV	R0,A
MOV	A,@R0
XRL	A,DPH		;kursor zawsze widoczny na tle
PUSH	ACC
MOV	A,R1
MOV	C,ACC.0
ANL	C,ACC.1
JC	main14		;spr czy wcisniety jednoczenie lewy i prawy przycisk myszki
JNB	ACC.0,main12	;spr czy wcisniety lewy przycisk myszki
MOV	A,@R0
ORL	A,DPH
MOV	@R0,A		;nowa pozycja kursora oraz RAMu spowrotem do RAM (pamiec ekranu od 20h do 3Fh) - malowanie
SJMP	main14
main12:
JNB	ACC.1,main14	;spr czy wcisniety prawy przycisk myszki
MOV	A,@R0
XRL	A,DPH
PUSH	ACC
MOV	A,DPH
CPL	A
MOV	B,A
POP	ACC
ANL	A,B
MOV	@R0,A		;nowa pozycja kursora oraz RAMu spowrotem do RAM (pamiec ekranu od 20h do 3Fh) - zmazywanie
main14:
POP	ACC		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,R0
ADD	A,#16
MOV	R0,A
MOV	A,@R0
XRL	A,DPL		;kursor zawsze widoczny na tle
PUSH	ACC
MOV	A,R1
MOV	C,ACC.0
ANL	C,ACC.1
JC	main15		;spr czy wcisniety jednoczenie lewy i prawy przycisk myszki
JNB	ACC.0,main13	;spr czy wcisniety lewy przycisk myszki
MOV	A,@R0
ORL	A,DPL
MOV	@R0,A		;nowa pozycja kursora oraz RAMu spowrotem do RAM (pamiec ekranu od 20h do 3Fh) - malowanie
SJMP	main15
main13:
JNB	ACC.1,main15	;spr czy wcisniety prawy przycisk myszki
MOV	A,@R0
XRL	A,DPL
PUSH	ACC
MOV	A,DPL
CPL	A
MOV	B,A
POP	ACC
ANL	A,B
MOV	@R0,A		;nowa pozycja kursora oraz RAMu spowrotem do RAM (pamiec ekranu od 20h do 3Fh) - zmazywanie
main15:
POP	ACC		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
POP	ACC
MOV	R0,A

AJMP	main

; ERROR
error:
ACALL	clear
MOV	DPTR,#err
ACALL	write_text
SJMP	$		;zatrzymanie programu

; PS/2
read_bit:		;odczyt bitu
MOV	C,DAT
MOV	AC,C
INC	R4
CJNE	R4,#1,read_bit2		;spr czy bit nr 1 (bit startu)
JB	AC,error
SJMP	read_bit1
read_bit2:
CJNE	R4,#10,read_bit3	;spr czy bit nr 10 (bit parzystosci)
SJMP	read_bit1
read_bit3:
CJNE	R4,#11,read_bit4	;spr czy bit nr 11 (bit stopu)
JNB	AC,error
SJMP	read_bit1
read_bit4:		;bity od 2 do 9 (8 bitow danych)
MOV	C,AC
RRC	A
read_bit1:
RET

write_bit:		;zapis bitu
INC	R4
CJNE	R4,#1,write_bit5	;spr czy bit nr 1 (bit startu)
SJMP	write_bit1
write_bit5:
CJNE	R4,#10,write_bit2	;spr czy bit nr 10 (bit parzystosci)
MOV	C,AC
RRC	A
MOV	C,P
CPL	C
MOV	DAT,C
SJMP	write_bit1
write_bit2:
CJNE	R4,#11,write_bit3	;spr czy bit nr 11 (bit stopu)
SETB	DAT
SJMP	write_bit1
write_bit3:
CJNE	R4,#12,write_bit4	;spr czy bit nr 12 (bit potwierdzenia)
JB	DAT,error
SJMP	write_bit1
write_bit4:		;bity od 2 do 9 (8 bitow danych)
MOV	C,AC
RRC	A
MOV	DAT,C
MOV	AC,C
write_bit1:
RET

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
MOV	R0,#16
clear_g2:
MOV	A,#00h		;zgaszenie 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#00h		;zgaszenie 8 kolejnych pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R0,clear_g2
DJNZ	R5,clear_g1
RET

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

err:
DB	'Comm Error',0

mouse_init:
DB	'Mouse Init...',0

mouse_ok:
DB	'OK',0

mouse_nok:
DB	'NOK',0

data_report_ena:
DB	'Data Report Ena',0

END