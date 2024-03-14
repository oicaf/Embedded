#define _INPUT 0
#define _OUTPUT 1
#define INST 0
#define DATA 1

/*** ATmega328 ***/
#define SDA 4 // I2C Serial Data on port C pin 4
#define SCL 5 // I2C Serial Clock on port C pin 5
#define RST 2 // Reset on port D pin 2
#define INT 3 // INTerrupt (INT1) on port D pin 3
#define RS 0 // LCD Register Select on port B pin 0
#define EN 1 // LCD ENable on port B pin 1
#define _ISC11 3 // Interrupt Sense Control 1 bit 1
#define _INT1 1 // External Interrupt Request 1 Enable
#define _EEPE 1 // EEPROM Write Enable
#define _EEMPE 2 // EEPROM Master Write Enable
#define _EERE 0 // EEPROM Read Enable

/*** Si4703 REGISTERS ***/
/* 0x02 */
#define SEEK 8 // Seek
#define SEEKUP 9 // Seek Direction
/* 0x03 */
#define TUNE 15 // Tune
/* 0x04 */
#define GPIO2 2 // General Purpose I/O 2
#define DE 11 // De-emphasis
#define RDS 12 // RDS Enable
#define RDSIEN 15 // RDS Interrupt Enable
/* 0x05 */
#define SPACE 4 // Channel Spacing
/* 0x0A */
#define STC 14 // Seek/Tune Complete
#define RDSR 15 // RDS Ready

/*** VARIABLES AND FUNCTIONS DECLARATION ***/
static volatile unsigned char *_DDRB = (volatile unsigned char *)0x24; // Port B Data Direction Register
static volatile unsigned char *_PORTB = (volatile unsigned char *)0x25; // Port B Data Register
static volatile unsigned char *_PINC = (volatile unsigned char *)0x26; // Port C Input Pins Address
static volatile unsigned char *_DDRC = (volatile unsigned char *)0x27; // Port C Data Direction Register
static volatile unsigned char *_PORTC = (volatile unsigned char *)0x28; // Port C Data Register
static volatile unsigned char *_DDRD = (volatile unsigned char *)0x2A; // Port D Data Direction Register
static volatile unsigned char *_PORTD = (volatile unsigned char *)0x2B; // Port D Data Register
static volatile unsigned char *_EIMSK = (volatile unsigned char *)0x3D; // External Interrupt Mask Register
static volatile unsigned char *_EECR = (volatile unsigned char *)0x3F; // EEPROM Control Register
static volatile unsigned char *_EEDR = (volatile unsigned char *)0x40; // EEPROM Data Register
static volatile unsigned char *_EEARL = (volatile unsigned char *)0x41; // EEPROM Address Register (Low)
static volatile unsigned char *_EEARH = (volatile unsigned char *)0x42; // EEPROM Address Register (High)
static volatile unsigned char *_SREG = (volatile unsigned char *)0x5F; // Status Register
static volatile unsigned char *_EICRA = (volatile unsigned char *)0x69; // External Interrupt Control Register A

unsigned char key; // input key on serial monitor
unsigned short int registers[16]; // 16 x 16-bit device registers
static char RDS_PS[9] = "        "; // array for RDS Program Service text (max 8 chars + NULL char '\0')

#ifdef __cplusplus
 extern "C" {
#endif

/*** BIT OPERATIONS ***/
void sbit(volatile unsigned char *reg, unsigned char bit); // set bit in register
void cbit(volatile unsigned char *reg, unsigned char bit); // clear bit in register
void _sbit(unsigned char pin); // set bit on port C
void dir_sda(unsigned char dir); // set SDA direction
unsigned char read_sda(); // read bit on SDA

/*** I2C (TWI) ***/
void start(); // start bit
void stp(); // stop bit
void ack(); // acknowledgment bit
void nack(); // no acknowledgment bit
unsigned char read_byte(); // read 8-bits
void write_byte(unsigned char data); // write 8-bits

/*** ATmega328 ***/
void init_interrupt(); // interrupt configuration
void clr_eeprom(); // eeprom clean out from 0x08 up to 0x00 addresses
void read_eeprom(unsigned char favourite); // read data from eeprom, address at current favourite
void write_eeprom(); // write data into eeprom, address at current favourite

/*** Si4703 ***/
void read_registers(); // read all (16) registers from device
void write_registers(); // device registers (6) update
void init_radio(); // Si4703 initialization
void set_channel(unsigned char key); // tune into selected channel / frequency
void seek_channel(unsigned char key);
void set_volume(unsigned char vol);

/*** 2x16 LCD DISPLAY (HD44780) ***/
void strobe(); // device strobe
void write_display(unsigned char mode, unsigned char data); // write instruction or data to display
void init_display(); // display initialization
void write_char(unsigned char data); // display char
void write_text(char *text); // display text
void display_info(); // information display

#ifdef __cplusplus
}
#endif
