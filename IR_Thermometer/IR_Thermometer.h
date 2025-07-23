#define _INPUT 0
#define _OUTPUT 1

/*** ATmega328 ***/
#define SDA 4 // Serial Data on port C pin 4
#define SCL 5 // Serial Clock on port C pin 5

unsigned char key; // input key on keypad
float Tamb, Tobj; // ambient and object temperatures
static volatile unsigned char *_PINC = (volatile unsigned char *)0x26; // Port C Input Pins Address
static volatile unsigned char *_DDRC = (volatile unsigned char *)0x27; // Port C Data Direction Register
static volatile unsigned char *_PORTC = (volatile unsigned char *)0x28; // Port C Data Register

#ifdef __cplusplus
 extern "C" {
#endif

void init_port();
float read_temp(unsigned char cmd_code);

#ifdef __cplusplus
}
#endif
