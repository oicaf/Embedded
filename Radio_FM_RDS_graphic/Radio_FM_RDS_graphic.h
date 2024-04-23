#define _INPUT 0
#define _OUTPUT 1
#define INST 0
#define DATA 1

/*** ATmega328 ***/
#define SDA 4 // I2C Serial Data on port C pin 4
#define SCL 5 // I2C Serial Clock on port C pin 5
#define RST 2 // Si4703 Reset on port D pin 2
#define INT 3 // Si4703 Interrupt on port D pin 3 (INT1)
#define UP 4 // Keypad A button on port D pin 4
#define RIGHT 5 // Keypad B button on port D pin 5
#define DOWN 6 // Keypad C button on port D pin 6
#define LEFT 7 // Keypad D button on port D pin 7
#define MOSI 3 // SPI Master Output Slave Input on port B pin 3
#define SCK 5 // SPI Serial Clock on port B pin 5
#define _ISC11 3 // Interrupt Sense Control 1 bit 1
#define _INT1 1 // External Interrupt Request 1 Enable
#define _EEPE 1 // EEPROM Write Enable
#define _EEMPE 2 // EEPROM Master Write Enable
#define _EERE 0 // EEPROM Read Enable
#define _WGM01 1 // Waveform Generation Mode
#define _OCIE0A 1 // Timer/Counter0 Output Compare Match A Interrupt Enable
#define _CS00 0 // Clock Select
#define _CS01 1 // Clock Select

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

const unsigned char RSSI_0[] = {0x00,0x00,0x00,0x00,0x00,0x0e,0x00,0x0a,0x00,0x0a,0x00,0xea,0x00,0xaa,0x00,0xaa,0x0e,0xaa,0x0a,0xaa,0x0a,0xaa,0xea,0xaa,0xaa,0xaa,0xee,0xee,0x00,0x00,0x00,0x00};
const unsigned char RSSI_1[] = {0x00,0x00,0x00,0x00,0x00,0x0e,0x00,0x0a,0x00,0x0a,0x00,0xea,0x00,0xaa,0x00,0xaa,0x0e,0xaa,0x0a,0xaa,0x0a,0xaa,0xea,0xaa,0xea,0xaa,0xee,0xee,0x00,0x00,0x00,0x00};
const unsigned char RSSI_2[] = {0x00,0x00,0x00,0x00,0x00,0x0e,0x00,0x0a,0x00,0x0a,0x00,0xea,0x00,0xaa,0x00,0xaa,0x0e,0xaa,0x0e,0xaa,0x0e,0xaa,0xee,0xaa,0xee,0xaa,0xee,0xee,0x00,0x00,0x00,0x00};
const unsigned char RSSI_3[] = {0x00,0x00,0x00,0x00,0x00,0x0e,0x00,0x0a,0x00,0x0a,0x00,0xea,0x00,0xea,0x00,0xea,0x0e,0xea,0x0e,0xea,0x0e,0xea,0xee,0xea,0xee,0xea,0xee,0xee,0x00,0x00,0x00,0x00};
const unsigned char RSSI_4[] = {0x00,0x00,0x00,0x00,0x00,0x0e,0x00,0x0e,0x00,0x0e,0x00,0xee,0x00,0xee,0x00,0xee,0x0e,0xee,0x0e,0xee,0x0e,0xee,0xee,0xee,0xee,0xee,0xee,0xee,0x00,0x00,0x00,0x00};
const unsigned char VOL_0[] = {0x00,0x00,0x00,0x00,0x01,0x00,0x03,0x00,0x07,0x00,0x0f,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0x0f,0x00,0x07,0x00,0x03,0x00,0x01,0x00,0x00,0x00,0x00,0x00};
const unsigned char VOL_1[] = {0x00,0x00,0x00,0x00,0x01,0x00,0x03,0x00,0x07,0x00,0x0f,0x00,0xff,0x40,0xff,0x20,0xff,0x20,0xff,0x40,0x0f,0x00,0x07,0x00,0x03,0x00,0x01,0x00,0x00,0x00,0x00,0x00};
const unsigned char VOL_2[] = {0x00,0x00,0x00,0x00,0x01,0x00,0x03,0x00,0x07,0x20,0x0f,0x10,0xff,0x48,0xff,0x28,0xff,0x28,0xff,0x48,0x0f,0x10,0x07,0x20,0x03,0x00,0x01,0x00,0x00,0x00,0x00,0x00};
const unsigned char VOL_3[] = {0x00,0x00,0x00,0x00,0x01,0x10,0x03,0x08,0x07,0x24,0x0f,0x12,0xff,0x4a,0xff,0x2a,0xff,0x2a,0xff,0x4a,0x0f,0x12,0x07,0x24,0x03,0x08,0x01,0x10,0x00,0x00,0x00,0x00};  

unsigned char key; // input key on keypad
unsigned char favourite; // favourite station number
unsigned char A_B; // RT message change indicator (A/B bit)
unsigned char RT_changed; // RT message content change indicator
unsigned char radiotext[65]; // array (buffer) for RDS radiotext (max 64 chars + NULL char '\0')
static char RT_offset = 0; // RDS radiotext offset for display window
static unsigned char volume = 1; // volume level (min)
static unsigned char RT_new = 0; // new RT message content ready
static unsigned char sync_index = 0; // synchronization index for RDS radiotext
static unsigned char RDS_PS[9] = "        "; // array for RDS Program Service text (max 8 chars + NULL char '\0')
static unsigned char RDS_RT[65] = "                                                                "; // array for RDS radiotext (max 64 chars + NULL char '\0')
static unsigned char RT_window[17] = "                "; // radiotext window (max 16 chars + NULL char '\0')
unsigned short int registers[16]; // 16 x 16-bit Si4703 registers
static unsigned long int start_time = 0; // timestamp for counting milliseconds
static volatile unsigned long int milliseconds = 0; // milliseconds counter

static volatile unsigned char *_DDRB = (volatile unsigned char *)0x24; // Port B Data Direction Register
static volatile unsigned char *_PORTB = (volatile unsigned char *)0x25; // Port B Data Register
static volatile unsigned char *_PINC = (volatile unsigned char *)0x26; // Port C Input Pins Address
static volatile unsigned char *_DDRC = (volatile unsigned char *)0x27; // Port C Data Direction Register
static volatile unsigned char *_PORTC = (volatile unsigned char *)0x28; // Port C Data Register
static volatile unsigned char *_PIND = (volatile unsigned char *)0x29; // Port D Input Pins Address
static volatile unsigned char *_DDRD = (volatile unsigned char *)0x2A; // Port D Data Direction Register
static volatile unsigned char *_PORTD = (volatile unsigned char *)0x2B; // Port D Data Register
static volatile unsigned char *_EIMSK = (volatile unsigned char *)0x3D; // External Interrupt Mask Register
static volatile unsigned char *_EECR = (volatile unsigned char *)0x3F; // EEPROM Control Register
static volatile unsigned char *_EEDR = (volatile unsigned char *)0x40; // EEPROM Data Register
static volatile unsigned char *_EEARL = (volatile unsigned char *)0x41; // EEPROM Address Register (Low)
static volatile unsigned char *_EEARH = (volatile unsigned char *)0x42; // EEPROM Address Register (High)
static volatile unsigned char *_TCCR0A = (volatile unsigned char *)0x44; // Timer/Counter Control Register A
static volatile unsigned char *_TCCR0B = (volatile unsigned char *)0x45; // Timer/Counter Control Register B
static volatile unsigned char *_OCR0A = (volatile unsigned char *)0x47; // Output Compare Register A
static volatile unsigned char *_SREG = (volatile unsigned char *)0x5F; // Status Register
static volatile unsigned char *_PCICR = (volatile unsigned char *)0x68; // Pin Change Interrupt Control Register
static volatile unsigned char *_EICRA = (volatile unsigned char *)0x69; // External Interrupt Control Register A
static volatile unsigned char *_PCMSK2 = (volatile unsigned char *)0x6D; // Pin Change Mask Register 2
static volatile unsigned char *_TIMSK0 = (volatile unsigned char *)0x6E; // Timer/Counter Interrupt Mask Register

#ifdef __cplusplus
 extern "C" {
#endif

void init_interrupt();
void clr_eeprom();
void init_radio();
void set_channel(unsigned char key);
void seek_channel(unsigned char key);
void set_volume(unsigned char vol);
void init_display();
void display_info();
void init_keypad();

#ifdef __cplusplus
}
#endif
