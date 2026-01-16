; program demonstracyjny obslugujacy klawiature PC (PS/2) z wyswietlaniem na alfanumerycznym LCD (16x2)

; polaczenia na plycie AVT-2500:
; podpiac gniazdo PS/2 do CON9 (VCC, CLK -> SCL, DATA -> SDA, GND)
; dodac dwa rezystory 4k7 na zlaczu "9", miedzy VCC i SCL, miedzy VCC i SDA
; wykonac zworke przy zlaczu "9" od SDA do P3.1
; wykonac zworke przy zlaczu "9" od SCL do P3.2
; wykonac zworki od P1.4...P1.7 do D4...D7
; wykonac zworke od P1.2 do RS
; wykonac zworke od P1.3 do EN
; wykonac zworke od P3.0 do RW (bezposrednio na plytce z wyswietlaczem, pin RW nalezy wyciagnac na zewnatrz LCD zeby nie byl wpiety na stale do masy na plycie AVT-2500)

RS	BIT	P1.2
EN	BIT	P1.3
RW	BIT	P3.0
DAT	BIT	P3.1

SJMP	30h

ORG	03h			;obsluga przerwania zewnetrznego INT0
ACALL	read_bit
RETI

ORG	30h
ACALL	init
MOV	IE,#10000001b		;zezwolenie na przerwanie z zewnatrz (INT0)
MOV	TCON,#00000001b		;przerwanie na opadajace zbocze
MOV	R0,#0			;licznik bitow (1-11)
MOV	R1,#0			;jesli R1 = 0 -> make code, jesli R1 = F0h -> brake code
MOV	R2,#0			;jesli R2 = 0 -> bez SHIFT, jesli R2 = 80h -> z SHIFT
MOV	R3,#0			;jesli R3 = 0 -> podstawowa grupa klawiszy, jesli R3 = E0h -> rozszerzona grupa klawiszy
MOV	R4,#0FFh		;aktualna pozycja kursora po wcisnieciu ENTER (przed wykonaniem akcji po ENTER)

main:
CJNE	R0,#11,main		;spr czy ostatni bit (11) zostal odebrany
MOV	R0,#0
CJNE	A,#0F0h,main2		;spr czy puszczony klawisz (brake code)
MOV	R1,A
SJMP	main

main2:
CJNE	R1,#0F0h,main3		;spr czy poprzedni scancode = F0h
MOV	R1,#0
MOV	R3,#0
CJNE	A,#12h,main14		;spr czy zostal puszczony lewy SHIFT
MOV	R2,#0
SJMP	main15
main14:
CJNE	A,#59h,main15		;spr czy zostal puszczony prawy SHIFT
MOV	R2,#0
main15:
SJMP	main

main3:
CJNE	A,#76h,main4		;spr czy zostal wcisniety ESC
ACALL	clear
SJMP	main

main4:
CJNE	A,#66h,main5		;spr czy zostal wcisniety BACKSPACE
ACALL	read_inst
CJNE	A,#40h,main7		;spr czy kursor na pozycji 1 w drugim wierszu
MOV	A,R4
ANL	A,#0F0h
JNZ	main28
MOV	A,R4
SETB	ACC.7
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
MOV	R4,#0FFh
SJMP	main
main28:
MOV	A,#90h
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
MOV	A,#10h
SJMP	main8
main7:
CJNE	A,#00h,main8		;spr czy kursor na pozycji 1 w pierwszym wierszu
SJMP	main
main8:
MOV	B,R4
CJNE	A,B,main30		;spr czy poruszajac sie strzalkami (przed wcisnieciem BACKSPACE) kursor znalazl sie na pozycji zapamietanego ENTER'a 
DEC	R4
main30:
DEC	ACC			;cofniecie adresu DDRAM o jedna pozycje
SETB	ACC.7
PUSH	ACC
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
MOV	A,#" "			;skasowanie znaku na biezacej pozycji
ACALL	write_data
MOV	R7,#5
ACALL	delay_10us
POP	ACC			;przywrocenie poprzedniej pozycji (cofniecie adresu DDRAM o jedna pozycje)
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
SJMP	main

main5:
CJNE	A,#5Ah,main9		;spr czy zostal wcisniety ENTER
ACALL	read_inst
PUSH	ACC
ANL	A,#0F0h
JNZ	main29
POP	ACC
MOV	R4,A
MOV     A,#0C0h			;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#5
ACALL	delay_10us
AJMP	main
main29:
POP	ACC
ANL	A,#0Fh
MOV	R4,A
ACALL	scroll
AJMP	main

main9:
CJNE	A,#12h,main11		;spr czy zostal wcisniety lewy SHIFT
SJMP	main13
main11:
CJNE	A,#59h,main12		;spr czy zostal wcisniety prawy SHIFT
main13:
MOV	R2,#80h
AJMP	main

main12:
CJNE	A,#0E0h,main16		;spr czy zostal wcisniety lub puszczony klawisz z rozszerzonej grupy
MOV	R3,A
AJMP	main
main16:
CJNE	R3,#0E0h,main6		;spr czy poprzedni scancode = E0h
MOV	R3,#0

CJNE	A,#6Ch,main18		;spr czy zostal wcisniety HOME
ACALL	home
AJMP	main

main18:
CJNE	A,#6Bh,main19		;spr czy zostala wcisnieta strzalka w lewo
ACALL	read_inst
DEC	A
CJNE	A,#3Fh,main22
MOV	A,#0Fh			;przejscie kursora z pierwszej pozycji w drugim wierszu na ostatnia pozycje w pierwszym wierszu
SJMP	main24
main22:
CJNE	A,#0FFh,main24		;spr czy kursor na pierwszej pozycji w pierwszym wierszu
SJMP	main1
main24:
SETB	ACC.7
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
SJMP	main1

main19:
CJNE	A,#72h,main20		;spr czy zostala wcisnieta strzalka w dol
ACALL	read_inst
SETB	ACC.6			;zabezpieczenie przed wyjsciem kursora poza "okno" wyswietlania na LCD
SETB	ACC.7
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
SJMP	main1

main20:
CJNE	A,#74h,main21		;spr czy zostala wcisnieta strzalka w prawo
ACALL	read_inst
CJNE	A,#50h,main26
SJMP	main1
main26:
INC	A
CJNE	A,#10h,main23
MOV	A,#40h			;przejscie kursora z ostatniej pozycji w pierwszym wierszu na pierwsza pozycje w drugim wierszu
SJMP	main25
main23:
CJNE	A,#50h,main25		;spr czy kursor na ostatniej pozycji w drugim wierszu
SJMP	main1
main25:
SETB	ACC.7
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
SJMP	main1

main21:
CJNE	A,#75h,main1		;spr czy zostala wcisnieta strzalka w gore
ACALL	read_inst
CLR	ACC.6			;zabezpieczenie przed wyjsciem kursora poza "okno" wyswietlania na LCD
CJNE	A,#10h,main27		;specyficzna sytuacja gdy DDRAM adres mialby sie zmienic z 50h na 10h
SJMP	main1
main27:
SETB	ACC.7
ACALL	write_inst
MOV	R7,#5
ACALL	delay_10us
SJMP	main1

main6:
ADD	A,R2
MOV	DPTR,#scancode		;pozostale klawisze (make code) + konwersja na ASCII
MOVC	A,@A+DPTR
CJNE	A,#00h,main10
SJMP	main1
main10:
ACALL	write_char

ACALL	read_inst
CJNE	A,#10h,main17		;spr czy kursor na pozycji 17 w pierwszym wierszu
MOV     A,#0C0h			;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#5
ACALL	delay_10us
SJMP	main1
main17:
CJNE	A,#50h,main1		;spr czy kursor na pozycji 17 w drugim wierszu
ACALL	scroll

main1:
AJMP	main

; PS/2
read_bit:			;odczyt bitu
MOV	C,DAT
MOV	F0,C
INC	R0

CJNE	R0,#1,read_bit2		;spr czy bit nr 1 (bit startu)
JB	F0,error
SJMP	read_bit1

read_bit2:
CJNE	R0,#10,read_bit3	;spr czy bit nr 10 (bit parzystosci)
SJMP	read_bit1

read_bit3:
CJNE	R0,#11,read_bit4	;spr czy bit nr 11 (bit stopu)
JNB	F0,error
SJMP	read_bit1

read_bit4:			;bity od 2 do 9 (8 bitow danych)
MOV	C,F0
RRC	A

read_bit1:
RET

; ERROR
error:
ACALL	clear
MOV	DPTR,#err
ACALL	write_text
SJMP	$			;zatrzymanie programu

; HD44780
write_inst:		;zapis instrukcji
PUSH	ACC
ANL	A,#0F0h		;maska starszego polbajtu
MOV	P1,A
CLR	RW
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
CLR	RW
ACALL	strobe
POP	ACC
SWAP	A
ANL	A,#0F0h		;maska mlodszego polbajtu
MOV	P1,A
SETB	RS
ACALL	strobe
RET

read_inst:		;odczyt stanu
MOV     P1,#0F0h
SETB    RW
SETB    EN
MOV     A,P1
CLR     EN
ANL	A,#0F0h		;maska starszego polbajtu
MOV	B,A
SETB    EN
MOV     A,P1
CLR     EN
ANL	A,#0F0h		;maska mlodszego polbajtu
SWAP	A
ORL	A,B
CLR	ACC.7
RET

read_data:		;odczyt danych
MOV     P1,#0F4h	;RS=1
SETB    RW
SETB    EN
MOV     A,P1
CLR     EN
ANL	A,#0F0h		;maska starszego polbajtu
MOV	B,A
SETB    EN
MOV     A,P1
CLR     EN
ANL	A,#0F0h		;maska mlodszego polbajtu
SWAP	A
ORL	A,B
RET

strobe:			;strobowanie ukladu
SETB	EN
CLR	EN
RET

init:			;inicjalizacja LCD
CLR	EN
CLR	RS
CLR	RW
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
MOV     A,#0Fh		;zalaczenie wyswietlacza, kursora i migania
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

scroll:
MOV     A,#0C0h			;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#5
ACALL	delay_10us

MOV	R5,#16
scroll1:			;16 znakow odczytanych z drugiej linii przepisane do pamieci (na stos) + czyszczenie drugiej linii spacjami
ACALL	read_data
MOV	R7,#5
ACALL	delay_10us
PUSH	ACC
DJNZ	R5,scroll1

MOV     A,#0C0h			;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#5
ACALL	delay_10us

MOV	R5,#16
scroll3:
MOV	A,#" "
ACALL	write_char
DJNZ	R5,scroll3

MOV	R5,#16
scroll2:			;16 znakow odczytanych z pamieci (ze stosu) przepisane do pierwszej linii
MOV	A,R5
DEC	A
SETB	ACC.7
ACALL   write_inst
MOV	R7,#5
ACALL	delay_10us
POP	ACC
ACALL	write_char
DJNZ	R5,scroll2

MOV	A,#0C0h			;kursor na poczatek drugiej linii
ACALL   write_inst
MOV	R7,#5
ACALL	delay_10us
RET

err:
DB	'ERROR',0

scancode:
;	ASCII	SCANCODE	KLAWISZ	(bez SHIFT)
DB	00h	;00h		brak
DB	00h	;01h		F9
DB	00h	;02h		brak
DB	00h	;03h		F5
DB	00h	;04h		F3
DB	00h	;05h		F1
DB	00h	;06h		F2
DB	00h	;07h		F12
DB	00h	;08h		brak
DB	00h	;09h		F10
DB	00h	;0Ah		F8
DB	00h	;0Bh		F6
DB	00h	;0Ch		F4
DB	00h	;0Dh		TAB
DB	00h	;0Eh		`
DB	00h	;0Fh		brak
DB	00h	;10h		brak
DB	00h	;11h		lewy ALT
DB	00h	;12h		lewy SHIFT
DB	00h	;13h		brak
DB	00h	;14h		lewy CTRL
DB	71h	;15h		q
DB	31h	;16h		1
DB	00h	;17h		brak
DB	00h	;18h		brak
DB	00h	;19h		brak
DB	7Ah	;1Ah		z
DB	73h	;1Bh		s
DB	61h	;1Ch		a
DB	77h	;1Dh		w
DB	32h	;1Eh		2
DB	00h	;1Fh		brak
DB	00h	;20h		brak
DB	63h	;21h		c
DB	78h	;22h		x
DB	64h	;23h		d
DB	65h	;24h		e
DB	34h	;25h		4
DB	33h	;26h		3
DB	00h	;27h		brak
DB	00h	;28h		brak
DB	20h	;29h		SPACE
DB	76h	;2Ah		v
DB	66h	;2Bh		f
DB	74h	;2Ch		t
DB	72h	;2Dh		r
DB	35h	;2Eh		5
DB	00h	;2Fh		brak
DB	00h	;30h		brak
DB	6Eh	;31h		n
DB	62h	;32h		b
DB	68h	;33h		h
DB	67h	;34h		g
DB	79h	;35h		y
DB	36h	;36h		6
DB	00h	;37h		brak
DB	00h	;38h		brak
DB	00h	;39h		brak
DB	6Dh	;3Ah		m
DB	6Ah	;3Bh		j
DB	75h	;3Ch		u
DB	37h	;3Dh		7
DB	38h	;3Eh		8
DB	00h	;3Fh		brak
DB	00h	;40h		brak
DB	2Ch	;41h		,
DB	6Bh	;42h		k
DB	69h	;43h		i
DB	6Fh	;44h		o
DB	30h	;45h		0
DB	39h	;46h		9
DB	00h	;47h		brak
DB	00h	;48h		brak
DB	2Eh	;49h		.
DB	2Fh	;4Ah		/
DB	6Ch	;4Bh		l
DB	3Bh	;4Ch		;
DB	70h	;4Dh		p
DB	2Dh	;4Eh		-
DB	00h	;4Fh		brak
DB	00h	;50h		brak
DB	00h	;51h		brak
DB	60h	;52h		'
DB	00h	;53h		brak
DB	5Bh	;54h		[
DB	3Dh	;55h		=
DB	00h	;56h		brak
DB	00h	;57h		brak
DB	00h	;58h		CAPS
DB	00h	;59h		prawy SHIFT
DB	00h	;5Ah		ENTER
DB	5Dh	;5Bh		]
DB	00h	;5Ch		brak
DB	5Ch	;5Dh		\
DB	00h	;5Eh		brak
DB	00h	;5Fh		brak
DB	00h	;60h		brak
DB	00h	;61h		brak
DB	00h	;62h		brak
DB	00h	;63h		brak
DB	00h	;64h		brak
DB	00h	;65h		brak
DB	00h	;66h		BACKSPACE
DB	00h	;67h		brak
DB	00h	;68h		brak
DB	00h	;69h		KP 1
DB	00h	;6Ah		brak
DB	00h	;6Bh		KP 4
DB	00h	;6Ch		KP 7
DB	00h	;6Dh		brak
DB	00h	;6Eh		brak
DB	00h	;6Fh		brak
DB	00h	;70h		KP 0
DB	00h	;71h		KP .
DB	00h	;72h		KP 2
DB	00h	;73h		KP 5
DB	00h	;74h		KP 6
DB	00h	;75h		KP 8
DB	00h	;76h		ESC
DB	00h	;77h		NUM
DB	00h	;78h		F11
DB	00h	;79h		KP +
DB	00h	;7Ah		KP 3
DB	00h	;7Bh		KP -
DB	00h	;7Ch		KP *
DB	00h	;7Dh		KP 9
DB	00h	;7Eh		SCROLL
DB	00h	;7Fh		brak

;	ASCII	SCANCODE	KLAWISZ	(z SHIFT)
DB	00h	;00h		brak
DB	00h	;01h		F9
DB	00h	;02h		brak
DB	00h	;03h		F5
DB	00h	;04h		F3
DB	00h	;05h		F1
DB	00h	;06h		F2
DB	00h	;07h		F12
DB	00h	;08h		brak
DB	00h	;09h		F10
DB	00h	;0Ah		F8
DB	00h	;0Bh		F6
DB	00h	;0Ch		F4
DB	00h	;0Dh		TAB
DB	00h	;0Eh		~
DB	00h	;0Fh		brak
DB	00h	;10h		brak
DB	00h	;11h		lewy ALT
DB	00h	;12h		lewy SHIFT
DB	00h	;13h		brak
DB	00h	;14h		lewy CTRL
DB	51h	;15h		Q
DB	21h	;16h		!
DB	00h	;17h		brak
DB	00h	;18h		brak
DB	00h	;19h		brak
DB	5Ah	;1Ah		Z
DB	53h	;1Bh		S
DB	41h	;1Ch		A
DB	57h	;1Dh		W
DB	40h	;1Eh		@
DB	00h	;1Fh		brak
DB	00h	;20h		brak
DB	43h	;21h		C
DB	58h	;22h		X
DB	44h	;23h		D
DB	45h	;24h		E
DB	24h	;25h		$
DB	23h	;26h		#
DB	00h	;27h		brak
DB	00h	;28h		brak
DB	20h	;29h		SPACE
DB	56h	;2Ah		V
DB	46h	;2Bh		F
DB	54h	;2Ch		T
DB	52h	;2Dh		R
DB	25h	;2Eh		%
DB	00h	;2Fh		brak
DB	00h	;30h		brak
DB	4Eh	;31h		N
DB	42h	;32h		B
DB	48h	;33h		H
DB	47h	;34h		G
DB	59h	;35h		Y
DB	5Eh	;36h		^
DB	00h	;37h		brak
DB	00h	;38h		brak
DB	00h	;39h		brak
DB	4Dh	;3Ah		M
DB	4Ah	;3Bh		J
DB	55h	;3Ch		U
DB	26h	;3Dh		&
DB	2Ah	;3Eh		*
DB	00h	;3Fh		brak
DB	00h	;40h		brak
DB	3Ch	;41h		<
DB	4Bh	;42h		K
DB	49h	;43h		I
DB	4Fh	;44h		O
DB	29h	;45h		)
DB	28h	;46h		(
DB	00h	;47h		brak
DB	00h	;48h		brak
DB	3Eh	;49h		>
DB	3Fh	;4Ah		?
DB	4Ch	;4Bh		L
DB	3Ah	;4Ch		:
DB	50h	;4Dh		P
DB	5Fh	;4Eh		_
DB	00h	;4Fh		brak
DB	00h	;50h		brak
DB	00h	;51h		brak
DB	22h	;52h		"
DB	00h	;53h		brak
DB	7Bh	;54h		{
DB	2Bh	;55h		+
DB	00h	;56h		brak
DB	00h	;57h		brak
DB	00h	;58h		CAPS
DB	00h	;59h		prawy SHIFT
DB	00h	;5Ah		ENTER
DB	7Dh	;5Bh		}
DB	00h	;5Ch		brak
DB	7Ch	;5Dh		|
DB	00h	;5Eh		brak
DB	00h	;5Fh		brak
DB	00h	;60h		brak
DB	00h	;61h		brak
DB	00h	;62h		brak
DB	00h	;63h		brak
DB	00h	;64h		brak
DB	00h	;65h		brak
DB	00h	;66h		BACKSPACE
DB	00h	;67h		brak
DB	00h	;68h		brak
DB	00h	;69h		KP 1
DB	00h	;6Ah		brak
DB	00h	;6Bh		KP 4
DB	00h	;6Ch		KP 7
DB	00h	;6Dh		brak
DB	00h	;6Eh		brak
DB	00h	;6Fh		brak
DB	00h	;70h		KP 0
DB	00h	;71h		KP .
DB	00h	;72h		KP 2
DB	00h	;73h		KP 5
DB	00h	;74h		KP 6
DB	00h	;75h		KP 8
DB	00h	;76h		ESC
DB	00h	;77h		NUM
DB	00h	;78h		F11
DB	00h	;79h		KP +
DB	00h	;7Ah		KP 3
DB	00h	;7Bh		KP -
DB	00h	;7Ch		KP *
DB	00h	;7Dh		KP 9
DB	00h	;7Eh		SCROLL
DB	00h	;7Fh		brak

END