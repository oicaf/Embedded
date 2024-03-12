/*** I/O PINS ***/
#define SDA 4 // SDA on port C, pin 4 (PC4)
#define SCL 5 // SCL on port C, pin 5 (PC5)
#define RST 2 // RST on port D, pin 2 (PD2)

/*** REGISTER 0x02 ***/
#define SEEK 8
#define SEEKUP 9

/*** REGISTER 0x03 ***/
#define TUNE 15

/*** REGISTER 0x04 ***/
#define DE 11
#define RDS 12

/*** REGISTER 0x05 ***/
#define SPACE 4

/*** REGISTER 0x0A ***/
#define STC 14
#define RDSR 15

#define _INPUT 0
#define _OUTPUT 1

/*** VARIABLES AND FUNCTIONS DECLARATION ***/
unsigned char key; // input key on serial monitor

#ifdef __cplusplus
 extern "C" {
#endif
void sda_dir(unsigned char dir);
void sbit(unsigned char pin);
void cbit(unsigned char pin);
unsigned char read_sda();
void start();
void stp();
void ack();
void nack();
unsigned char read_byte();
void write_byte(unsigned char data);
void clr_eeprom();
void read_eeprom(unsigned char fav);
void write_eeprom();
void read_registers();
void write_registers();
void radio_init();
void set_channel(unsigned char _key);
void seek_channel(unsigned char _key);
void set_volume(unsigned char vol);
char *read_PS();
char *read_RT();
void display_info();
#ifdef __cplusplus
}
#endif
