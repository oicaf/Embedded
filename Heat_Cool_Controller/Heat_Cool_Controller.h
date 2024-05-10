#define INST 0 // instruction to LCD
#define DATA 1 // data to LCD

#define RIGHT 2 // Keypad B button on port D pin 2
#define LEFT 3 // Keypad D button on port D pin 3
#define DQ 4 // 1-Wire Serial Data on port D pin 4
#define MOSI 3 // SPI Master Output Slave Input on port B pin 3
#define SCK 5 // SPI Serial Clock on port B pin 5
#define _ISC01 1 // Interrupt Sense Control 0 bit 1
#define _ISC11 3 // Interrupt Sense Control 1 bit 1
#define _INT0 0 // External Interrupt Request 0 Enable
#define _INT1 1 // External Interrupt Request 1 Enable

static volatile unsigned char *_DDRB = (volatile unsigned char *)0x24; // Port B Data Direction Register
static volatile unsigned char *_PORTB = (volatile unsigned char *)0x25; // Port B Data Register
static volatile unsigned char *_PIND = (volatile unsigned char *)0x29; // Port D Input Pins Address
static volatile unsigned char *_DDRD = (volatile unsigned char *)0x2A; // Port D Data Direction Register
static volatile unsigned char *_PORTD = (volatile unsigned char *)0x2B; // Port D Data Register
static volatile unsigned char *_EIMSK = (volatile unsigned char *)0x3D; // External Interrupt Mask Register
static volatile unsigned char *_SREG = (volatile unsigned char *)0x5F; // Status Register
static volatile unsigned char *_EICRA = (volatile unsigned char *)0x69; // External Interrupt Control Register A

#ifdef __cplusplus
 extern "C" {
#endif

void init_display();
void write_background();
void init_interrupt();
short int temperature();
unsigned char regulator(unsigned char mode, short int temp);

#ifdef __cplusplus
}
#endif
