; program demonstracyjny prezentujacy prosta animacje na monochromatycznym wyswietlaczu graficznym LCD 128x64 opartym na kontrolerze ST7920-0B

; polaczenia na plycie AVT-2500:
; wykonac zworke od P1.2 do RS (CS*)
; wykonac zworke od P1.3 do EN (SCLK*)

; polaczenia od wyswietlacza graficznego LCD do plyty AVT-2500:
; sygnaly ktore sa 1:1 z LCD 16x2 wyprowadzone sa na gotowym zlaczu pasujacym do gniazda dla wyswietlaczy
; wykonac zworke od pinu 5 (R/W) do P3.3 (SID*)
; wykonac zworke od pinu 15 (PSB) do GND
; wykonac zworke od pinu 19 (BLA) do VCC oraz od pinu 20 (BLK) do GND

CS	BIT	P1.2
SCLK	BIT	P1.3
SID	BIT	P3.3

SETB	CS
ACALL	init

main:
MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

ACALL	clear_g

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

; ANIMACJA 1
MOV	R0,#0
MOV	R1,#0
MOV	R5,#2
loop1:
MOV	DPTR,#1000000000000000b
MOV	R4,#16
loop:
MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 0 do 31
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R0		;ustawienie adresu poziomego od 0 do 15
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

MOV	R7,#100
ACALL	delay_ms

MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 0 do 31
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R0		;ustawienie adresu poziomego od 0 do 15
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	A,#0		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#0		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us

INC	R1
CLR	C
MOV	A,DPH
RRC	A
MOV	DPH,A
MOV	A,DPL
RRC	A
MOV	DPL,A

DJNZ	R4,loop
INC	R0
DJNZ	R5,loop1

MOV	R1,#31
MOV	R5,#2
loop3:
MOV	DPTR,#1000000000000000b
MOV	R4,#16
loop2:
MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 31 do 0
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R0		;ustawienie adresu poziomego od 0 do 15
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

MOV	R7,#100
ACALL	delay_ms

MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 31 do 0
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R0		;ustawienie adresu poziomego od 0 do 15
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	A,#0		;pierwsze 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us
MOV	A,#0		;kolejne 8 pixeli
ACALL	write_data
MOV	R7,#10
ACALL	delay_10us

DEC	R1
CLR	C
MOV	A,DPH
RRC	A
MOV	DPH,A
MOV	A,DPL
RRC	A
MOV	DPL,A

DJNZ	R4,loop2
INC	R0
DJNZ	R5,loop3

MOV	R1,#0
MOV	R5,#2
CJNE	R0,#16,main1
SJMP	main2
main1:
AJMP	loop1

; ANIMACJA 2
main2:
MOV	R0,#0
MOV	R1,#0
MOV	R5,#2
loop4:
MOV	DPTR,#1000000000000000b
MOV	R4,#16
loop5:
MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 0 do 31
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R0		;ustawienie adresu poziomego od 0 do 15
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

MOV	R7,#100
ACALL	delay_ms

INC	R1
CLR	C
MOV	A,DPH
RRC	A
MOV	DPH,A
MOV	A,DPL
RRC	A
MOV	DPL,A

DJNZ	R4,loop5
INC	R0
DJNZ	R5,loop4

MOV	R1,#31
MOV	R5,#2
loop7:
MOV	DPTR,#1000000000000000b
MOV	R4,#16
loop6:
MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 31 do 0
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h
ADD	A,R0		;ustawienie adresu poziomego od 0 do 15
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

MOV	R7,#100
ACALL	delay_ms

DEC	R1
CLR	C
MOV	A,DPH
RRC	A
MOV	DPH,A
MOV	A,DPL
RRC	A
MOV	DPL,A

DJNZ	R4,loop6
INC	R0
DJNZ	R5,loop7

MOV	R1,#0
MOV	R5,#2
CJNE	R0,#16,main3
SJMP	main4
main3:
AJMP	loop4

main4:
; ANIMACJA 3
MOV     A,#24h		;magistrala 4-bit, rozszerzony zestaw instrukcji, wylaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

ACALL	clear_g

MOV     A,#26h		;magistrala 4-bit, rozszerzony zestaw instrukcji, zalaczenie wyswietlacza graficznego
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

MOV	DPTR,#seconds
MOV	R5,#16
loop9:
MOV	R1,#0
MOV	R4,#16
loop8:
MOV	A,#80h
ADD	A,R1		;ustawienie adresu pionowego od 0 do 15
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us
MOV	A,#80h		;ustawienie adresu poziomego = 0
ACALL   write_inst
MOV	R7,#10
ACALL	delay_10us

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

INC	R1
DJNZ	R4,loop8

MOV	R0,#4
loop10:
MOV	R7,#250
ACALL	delay_ms
DJNZ	R0,loop10

DJNZ	R5,loop9

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

seconds:
DB	080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,003h
DB	080h,000h,080h,000h,040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,080h,000h,080h,000h,080h,000h,080h,000h,080h,003h
DB	080h,000h,080h,000h,020h,000h,020h,000h,020h,000h,020h,000h,020h,000h,020h,000h,040h,000h,040h,000h,040h,000h,040h,000h,040h,000h,080h,000h,080h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,010h,000h,010h,000h,010h,000h,010h,000h,020h,000h,020h,000h,020h,000h,020h,000h,040h,000h,040h,000h,040h,000h,080h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,004h,000h,008h,000h,008h,000h,008h,000h,010h,000h,010h,000h,010h,000h,020h,000h,020h,000h,040h,000h,040h,000h,040h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,002h,000h,004h,000h,004h,000h,008h,000h,008h,000h,010h,000h,010h,000h,020h,000h,020h,000h,040h,000h,040h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,001h,000h,002h,000h,004h,000h,004h,000h,008h,000h,010h,000h,010h,000h,020h,000h,040h,000h,040h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,001h,000h,002h,000h,004h,000h,008h,000h,010h,000h,010h,000h,020h,000h,040h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,040h,000h,080h,001h,000h,006h,000h,008h,000h,010h,000h,020h,000h,040h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,020h,000h,040h,000h,080h,003h,000h,006h,000h,008h,000h,030h,000h,040h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,010h,000h,020h,000h,0C0h,001h,000h,006h,000h,018h,000h,060h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,008h,000h,030h,000h,0C0h,003h,000h,00Ch,000h,070h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,018h,000h,0E0h,007h,000h,078h,000h,080h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,01Ch,001h,0E0h,03Eh,000h,0C0h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,0FCh,0F8h,003h
DB	080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0FFh,0FFh

END