#define _INPUT 0
#define _OUTPUT 1

#define INST 0
#define DATA 1

/*** HARDWIRED PINS ***/
#define SDA 4 // SDA on port C pin 4 (PC4)
#define SCL 5 // SCL on port C pin 5 (PC5)
#define RST 2 // RST on port D pin 2 (PD2)
#define INT 3 // INT1 on port D pin 3 (PD3)
#define RS 0 // RS on port B pin 0 (PB0)
#define EN 1 // EN on port B pin 1 (PB1)

/*** REGISTER 0x02 ***/
#define SEEK 8
#define SEEKUP 9

/*** REGISTER 0x03 ***/
#define TUNE 15

/*** REGISTER 0x04 ***/
#define GPIO2 2
#define DE 11
#define RDS 12
#define RDSIEN 15

/*** REGISTER 0x05 ***/
#define SPACE 4

/*** REGISTER 0x0A ***/
#define STC 14
#define RDSR 15

/*** VARIABLES AND FUNCTIONS DECLARATION ***/
unsigned char key; // input key on serial monitor

#ifdef __cplusplus
 extern "C" {
#endif

void sbit(volatile unsigned char *reg, unsigned char bit);
void cbit(volatile unsigned char *reg, unsigned char bit);
void _sbit(unsigned char pin);
void dir_sda(unsigned char dir);
unsigned char read_sda();
void start();
void stp();
void ack();
void nack();
unsigned char read_byte();
void write_byte(unsigned char data);
void init_interrupt();
void clr_eeprom();
void read_eeprom(unsigned char favourite);
void write_eeprom();
void read_registers();
void write_registers();
void init_radio();
void set_channel(unsigned char key);
void seek_channel(unsigned char key);
void set_volume(unsigned char vol);
void strobe();
void write_display(unsigned char mode, unsigned char data);
void init_display();
void write_char(unsigned char data);
void write_text(char *text);
void display_info();

#ifdef __cplusplus
}
#endif
