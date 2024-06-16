; program demonstracyjny prezentujacy mozliwosci monochromatycznego wyswietlacza graficznego LCD 128x64 opartego na kontrolerze ST7920-0B
; wcisniecie S1 przelacza kolejno prezentacje

; polaczenia na plycie AVT-2500:
; wykonac zworke od P1.2 do RS (CS*)
; wykonac zworke od P1.3 do EN (SCLK*)
; wykonac zworke od S1 do P3.0

; polaczenia od wyswietlacza graficznego LCD do plyty AVT-2500:
; sygnaly ktore sa 1:1 z LCD 16x2 wyprowadzone sa na gotowym zlaczu pasujacym do gniazda dla wyswietlaczy
; wypiac przewod z pinu 5 (R/W) na zlaczu po stronie AVT-2500 i wpiac go do P3.3 (SID*)
; wykonac zworke od pinu 15 (PSB) do GND
; wykonac zworke od pinu 19 (BLA) do VCC oraz od pinu 20 (BLK) do GND

CS	BIT	P1.2
SCLK	BIT	P1.3
S1	BIT	P3.0
SID	BIT	P3.3

SETB	CS
ACALL	init

; TRYB ZNAKOWY
MOV	B,#01h
MOV	R0,#16
loop:
MOV	A,B		;znaki podstawowe (HCGROM 16x8)
ACALL	write_char
INC	B
DJNZ	R0,loop

MOV	A,#90h		;przejscie na poczatek drugiego wiersza
ACALL	write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	B,#11h
MOV	R0,#16
loop1:
MOV	A,B		;znaki podstawowe (HCGROM 16x8)
ACALL	write_char
INC	B
DJNZ	R0,loop1

MOV	A,#88h		;przejscie na poczatek trzeciego wiersza
ACALL	write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	DPTR,#chars	;znaki rozszerzone (CGROM 16x16)
ACALL	write_text

MOV	A,#98h		;przejscie na poczatek czwartego wiersza
ACALL	write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	DPTR,#chars1	;znaki rozszerzone (CGROM 16x16)
ACALL	write_text

key1:
JB	S1,key1
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key2:
JNB	S1,key2		;przycisk musi zostac zwolniony zeby przejsc dalej

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV     A,#04h		;odwrocenie pierwszej i trzeciej linii
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

key3:
JB	S1,key3
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key4:
JNB	S1,key4		;przycisk musi zostac zwolniony zeby przejsc dalej

MOV     A,#03h		;zezwolenie na przewijanie w pionie
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R0,#64
MOV	B,#01h
loop2:
MOV     A,#40h
ADD	A,B		;adres przewijania pionowego
ACALL   write_inst
MOV	R7,#100
ACALL	delay_ms
INC	B
DJNZ	R0,loop2

key5:
JB	S1,key5
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key6:
JNB	S1,key6		;przycisk musi zostac zwolniony zeby przejsc dalej

MOV     A,#20h		;magistrala 4-bit, podstawowy zestaw instrukcji
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

ACALL	clear

; TRYB GRAFICZNY
MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

ACALL	clear_g

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

; WZOR 1
MOV	R2,#00h
MOV	R3,#2
loop6:
MOV	B,#00h
MOV	R0,#16
loop3:
MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 31, wiersze parzyste)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R2		;ustawienie adresu poziomego (X=0 lub 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop4:
MOV	A,#01010101b	;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#01010101b	;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R1,loop4

MOV	R7,#100
ACALL	delay_ms

INC	B

MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 31, wiersze nieparzyste)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R2		;ustawienie adresu poziomego (X=0 lub 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop5:
MOV	A,#10101010b	;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#10101010b	;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R1,loop5

MOV	R7,#100
ACALL	delay_ms

INC	B
DJNZ	R0,loop3

MOV	R2,#08h
DJNZ	R3,loop6

key9:
JB	S1,key9
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key10:
JNB	S1,key10	;przycisk musi zostac zwolniony zeby przejsc dalej

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

; WZOR 2
MOV	R2,#00h
MOV	R3,#2
loop11:
MOV	B,#00h
MOV	R0,#8
MOV	R4,#2
loop7:
MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 31, wiersze parami)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R2		;ustawienie adresu poziomego (X=0 lub 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop8:
MOV	A,#00110011b	;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#00110011b	;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R1,loop8
INC	B
DJNZ	R4,loop7

MOV	R4,#2
loop10:
MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 31, wiersze parami)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R2		;ustawienie adresu poziomego (X=0 lub 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop9:
MOV	A,#11001100b	;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#11001100b	;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R1,loop9
INC	B
DJNZ	R4,loop10

MOV	R4,#2
DJNZ	R0,loop7

MOV	R2,#08h
DJNZ	R3,loop11

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

key11:
JB	S1,key11
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key12:
JNB	S1,key12	;przycisk musi zostac zwolniony zeby przejsc dalej

ACALL	clear_g

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

; TRYB ZNAKOWY + GRAFICZNY (MIX)
MOV     A,#20h		;magistrala 4-bit, podstawowy zestaw instrukcji, wyswietlacz graficzny wylaczony
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	A,#83h		;przejscie do wiersza 1, kolumna 7 (HCGROM)
ACALL	write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	DPTR,#demo	;demo tekst
ACALL	write_text

key13:
JB	S1,key13
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key14:
JNB	S1,key14	;przycisk musi zostac zwolniony zeby przejsc dalej

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

; WZOR 3
MOV	B,#00h
MOV	R0,#8
loop12:
MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego (X=0)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop13:
MOV	A,#0FFh		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#0FFh		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
DJNZ	R1,loop13
INC	B
DJNZ	R0,loop12

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

key15:
JB	S1,key15
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key16:
JNB	S1,key16	;przycisk musi zostac zwolniony zeby przejsc dalej

ACALL	clear_g

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylacznie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV     A,#20h		;magistrala 4-bit, podstawowy zestaw instrukcji
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

ACALL	clear

; OBRAZ (VOLVO LOGO)
MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylacznie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R2,#00h
MOV	R3,#2
MOV	DPTR,#volvo_logo
loop16:
MOV	B,#00h
MOV	R0,#32
loop14:
MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 31)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R2		;ustawienie adresu poziomego (X=0 lub 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop15:
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
DJNZ	R1,loop15

MOV	R7,#100
ACALL	delay_ms

INC	B
DJNZ	R0,loop14

MOV	R2,#08h
DJNZ	R3,loop16

key23:
JB	S1,key23
MOV	R7,#20
ACALL	delay_ms	;po wcisnieciu przycisku opoznienie 20ms ze wzgledu na drgania stykow
key24:
JNB	S1,key24	;przycisk musi zostac zwolniony zeby przejsc dalej

MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylacznie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R2,#00h
MOV	R3,#2
MOV	DPTR,#volvo_logo
loop19:
MOV	B,#00h
MOV	R0,#32
loop17:
MOV	A,#80h
ADD	A,B		;ustawienie adresu pionowego (Y=0 do 31)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R2		;ustawienie adresu poziomego (X=0 lub 8)
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	R1,#8
loop18:
CLR	A
MOVC	A,@A+DPTR	;pierwsze 8 pixeli
CPL	A
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
INC	DPTR
CLR	A
MOVC	A,@A+DPTR	;kolejne 8 pixeli
CPL	A
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
INC	DPTR
DJNZ	R1,loop18

INC	B
DJNZ	R0,loop17

MOV	R2,#08h
DJNZ	R3,loop19

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

SJMP	$

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
chars:
DB	0A1h,0C0h,0A1h,0C6h,0A1h,0CCh,0A1h,0D3h,0A1h,0E1h,0A1h,0E6h,0A1h,0EDh,0A1h,0FCh,0

chars1:
DB	0A7h,0C0h,0A7h,0C1h,0A9h,0B0h,0A9h,0B4h,0A9h,0B8h,0A9h,0BCh,0A9h,0D0h,0B0h,0C0h,0

demo:
DB	'DEMO',0

volvo_logo:
DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,07fh,080h,000h,07fh,0ffh,0ffh,0ffh
DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h,00fh,080h,000h,07fh,0ffh,0ffh,0ffh
DB	0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0c0h,000h,000h,003h,0e0h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0f0h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h,038h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h,000h,000h,018h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h,000h,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h,000h,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0c0h,000h,03fh,0feh,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,080h,001h,0ffh,0ffh,0c0h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,000h,007h,0ffh,0ffh,0f0h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0feh,000h,01fh,0ffh,0ffh,0fch,000h,008h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0fch,000h,03fh,0ffh,0ffh,0feh,000h,018h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0f8h,000h,0ffh,0ffh,0ffh,0ffh,000h,01ch,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0f8h,001h,0ffh,0ffh,0ffh,0ffh,080h,00eh,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0f0h,003h,0ffh,0ffh,0ffh,0ffh,0c0h,006h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0e0h,007h,0ffh,0ffh,0ffh,0ffh,0e0h,007h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0e0h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,003h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0c0h,00fh,0ffh,0ffh,0ffh,0ffh,0f8h,003h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0c0h,01fh,0ffh,0ffh,0ffh,0ffh,0fch,001h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,080h,01fh,0ffh,0ffh,0ffh,0ffh,0fch,001h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,080h,03fh,0ffh,0ffh,0ffh,0ffh,0feh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,080h,03fh,0ffh,0ffh,0ffh,0ffh,0feh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h,000h,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,07ch,0f3h,0c7h,0cfh,0ceh,038h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,038h,066h,073h,087h,08ch,0eeh,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,03ch,04eh,033h,083h,08dh,0c7h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,01ch,0ceh,03bh,083h,0c9h,0c7h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,00eh,08eh,033h,089h,0d9h,0c7h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,00fh,086h,073h,098h,0f0h,0eeh,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,007h,003h,0c7h,0f8h,0e0h,03ch,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h,000h,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,000h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,080h,03fh,0ffh,0ffh,0ffh,0ffh,0feh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,080h,03fh,0ffh,0ffh,0ffh,0ffh,0feh,000h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,080h,01fh,0ffh,0ffh,0ffh,0ffh,0fch,001h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0c0h,01fh,0ffh,0ffh,0ffh,0ffh,0fch,001h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0c0h,00fh,0ffh,0ffh,0ffh,0ffh,0f8h,003h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0e0h,00fh,0ffh,0ffh,0ffh,0ffh,0f0h,003h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0e0h,007h,0ffh,0ffh,0ffh,0ffh,0e0h,007h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0f0h,003h,0ffh,0ffh,0ffh,0ffh,0c0h,007h,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0f8h,001h,0ffh,0ffh,0ffh,0ffh,080h,00fh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0f8h,000h,0ffh,0ffh,0ffh,0ffh,000h,01fh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0fch,000h,03fh,0ffh,0ffh,0feh,000h,01fh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0feh,000h,01fh,0ffh,0ffh,0fch,000h,03fh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,000h,007h,0ffh,0ffh,0f0h,000h,07fh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,080h,001h,0ffh,0ffh,0c0h,000h,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0c0h,000h,03fh,0feh,000h,001h,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0e0h,000h,000h,000h,000h,003h,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,000h,000h,000h,000h,007h,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h,000h,000h,01fh,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,000h,000h,03fh,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0c0h,000h,000h,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
DB      0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,000h,000h,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh
    
END