#include <string.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "Radio_FM_RDS_lcd.h"

char RDS_PS[9] = "        "; // array for RDS Program Service text (max 8 chars + NULL char '\0')
unsigned short int registers[16]; // 16 x 16-bit device registers


/*** BIT OPERATIONS ***/

void sbit(volatile unsigned char *reg, unsigned char bit) // set bit in register
{
  *reg |= (1 << bit);
}

void cbit(volatile unsigned char *reg, unsigned char bit) // clear bit in register
{
  *reg &= ~(1 << bit);
}

void _sbit(unsigned char pin) // set bit on port C
{
  /* if _sbit is replaced in the code below in a few places by sbit(&PORTC, pin) then functionality behaves strange, don't know the reason */
  PORTC |= (1 << pin);
}

void dir_sda(unsigned char dir) // set SDA direction
{
  if (dir == 0)
    DDRC &= ~(1 << SDA); // SDA as input
  else if (dir == 1)
    DDRC |= (1 << SDA); // SDA as output
}

unsigned char read_sda() // read bit on SDA
{
  unsigned char data = PINC; // read byte
  data &= (1 << SDA); // mask on SDA
  return (data != 0) ? 1 : 0;
}

/*** I2C (TWI) ***/

void start() // start bit
{
  _sbit(SDA);
  _sbit(SCL);
  cbit(&PORTC, SDA);
  cbit(&PORTC, SCL);
}

void stp() // stop bit
{
  cbit(&PORTC, SDA);
  _sbit(SCL);
  _sbit(SDA);
}

void ack() // acknowledgment bit
{
  cbit(&PORTC, SDA);
  _sbit(SCL);
  cbit(&PORTC, SCL);
}

void nack() // no acknowledgment bit
{
  _sbit(SDA);
  _sbit(SCL);
  cbit(&PORTC, SCL);
}

unsigned char read_byte() // read 8-bits
{
  unsigned char i, data = 0;

  dir_sda(_INPUT);
  for (i = 0; i <= 7; i++)
  {
    _sbit(SCL);
    if (read_sda())
      data |= 1;
    if (i < 7)
      data <<= 1;
    cbit(&PORTC, SCL);
  }
  dir_sda(_OUTPUT);
  
  return data;
}

void write_byte(unsigned char data) // write 8-bits
{
  unsigned char i;
  
  for (i = 0; i <= 7; i++)
  {
    if ((data & 0x80) == 0)
    {
      cbit(&PORTC, SDA);
    }
    else
    {
      _sbit(SDA);
    }
    _sbit(SCL);
    cbit(&PORTC, SCL);
    data <<= 1;
  }
  
  dir_sda(_INPUT);
  _sbit(SCL);
  cbit(&PORTC, SCL);
  dir_sda(_OUTPUT);
}

/*** ATmega328 ***/

void init_interrupt() // interrupt configuration
{
  cbit(&DDRD, INT); // INT as input
  sbit(&PORTD, INT); // pull-up on INT
  sbit(&EICRA, ISC11); // falling edge on INT1 generates an interrupt request
  sbit(&EIMSK, INT1); // external interrupt request 1 enable
  sbit(&SREG, 7); // enable global interrupts
}

void clr_eeprom() // eeprom clean out from 0x08 up to 0x00 addresses
{
  for (char i = 8; i >= 0; i--)
  {
    while (EECR & (1 << EEPE)); // wait for completion of previous write
    EEARH = 0; // eeprom address register (high byte)
    EEARL = i; // eeprom address register (low byte)
    EEDR = 0; // eeprom data register
    sbit(&EECR, EEMPE);
    sbit(&EECR, EEPE); // start eeprom writing
  }
}

void read_eeprom(unsigned char favourite) // read data from eeprom, address at current favourite
{
  while (EECR & (1 << EEPE)); // wait for completion of previous write
  EEARH = 0; // eeprom address register (high byte)
  EEARL = favourite - 1; // eeprom address register (low byte)
  sbit(&EECR, EERE); // start eeprom reading
  registers[0x03] |= EEDR; // mask on new channel (eeprom data register)
}

void write_eeprom() // write data into eeprom, address at current favourite
{
  while (EECR & (1 << EEPE)); // wait for completion of previous write
  EEDR = registers[0x0B] & 0x00FF; // eeprom data register, mask on channel, only 8 bits is sufficient
  sbit(&EECR, EEMPE);
  sbit(&EECR, EEPE); // start eeprom writing
}

/*** Si4703 ***/

void read_registers() // read all (16) registers from device
{
  unsigned char i, reg;
  
  start();
  write_byte(0x21); // device address + read bit
  reg = 0x0A; // reading starts at 0Ah register
  for (i = 0; i <= 15; i++)
  {
    registers[reg] = read_byte(); // upper byte
    ack();
    registers[reg] <<= 8;
    registers[reg] &= 0xFF00;
    registers[reg] |= read_byte(); // lower byte
    if (i == 15)
      nack();
    else
      ack();
    reg++;
    if (reg == 16)
      reg = 0x00;
  }
  stp();
}

void write_registers() // device registers (6) update
{
  unsigned char reg, data;
  
  start();
  write_byte(0x20); // device address + write bit
  for (reg = 0x02; reg <= 0x07; reg++) // writing starts at 02h register
  {
    data = registers[reg] >> 8; // upper byte
    write_byte(data);
    data = registers[reg] & 0x00FF; // lower byte
    write_byte(data);
  }
  stp();
}

void init_radio() // Si4703 initialization
{
  sbit(&DDRC, SDA); // SDA as output
  sbit(&DDRC, SCL); // SCL as output
  sbit(&DDRD, RST); // RST as output

  _sbit(SCL);
  cbit(&PORTC, SDA);
  cbit(&PORTD, RST);
  _delay_ms(1);
  sbit(&PORTD, RST);
  _delay_ms(1);
 
  read_registers();
  registers[0x07] = 0x8100; // enable oscillator
  write_registers();
  _delay_ms(500);

  read_registers();
  registers[0x02] = 0x4001; // enable IC
  registers[0x04] |= (1 << RDSIEN) | (1 << RDS) | (1 << DE) | (1 << GPIO2); // enable RDS interrupt, enable RDS, 50us de-emphasis used in Europe, STC/RDS interrupt on GPIO2
  registers[0x05] |= (1 << SPACE); // 100kHz channel spacing for Europe
  write_registers();
  _delay_ms(110);
}

void set_channel(unsigned char key) // tune into selected channel / frequency
{        
  strcpy(RDS_PS, "        "); // Program Service text clean out when favourite station selected

  read_registers();
  registers[0x03] &= 0xFE00; // clean out channel bits
  read_eeprom(key - 0x30);
  registers[0x03] |= (1 << TUNE); // tune enable
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) != 0) // wait until seek/tune operation completed
      break;
  }
  
  read_registers();
  registers[0x03] &= ~(1 << TUNE); // tune disable
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) == 0) // wait until seek/tune flag cleared
      break;
  }
}

void seek_channel(unsigned char key)
{
  strcpy(RDS_PS, "        "); // Program Service text clean out when favourite station selected

  read_registers();
  if (key == 'u')
    registers[0x02] |= (1 << SEEKUP); // seek up direction
  if (key == 'd')
    registers[0x02] &= ~(1 << SEEKUP); // seek down direction
  registers[0x02] |= (1 << SEEK); // seek enable
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) != 0) // wait until seek/tune operation completed
      break;
    display_info();
  }
  
  read_registers();
  registers[0x02] &= ~(1 << SEEK); // seek disable
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) == 0) // wait until seek/tune flag cleared
      break;
  }

  read_registers();
  write_eeprom();
}

void set_volume(unsigned char vol)
{
  read_registers();
  registers[0x05] &= 0xFFF0; // clear VOLUME bits
  registers[0x05] |= vol; // set new volume
  write_registers();
}

ISR(INT1_vect) // Interrupt Service Routine from INT1 (RDS Program Service text decode)
{
  char c_SREG = SREG; // store Status REGister
  unsigned char PS_index; // RDS received char index
  unsigned char rx_char; // RDS received char
  
  if (registers[0x0D] >> 12 == 0) // group type code 0A/0B (Program Service)
  {
    PS_index = registers[0x0D] & 0x03; // mask on received char index

    rx_char = registers[0x0F] >> 8; // first char received
    if (rx_char < ' ' || rx_char > '}') // correction of any inappropriate characters
      rx_char = ' ';
    RDS_PS[PS_index * 2 + 0] = rx_char;
    
    rx_char = registers[0x0F]; // second char received
    if (rx_char < ' ' || rx_char > '}') // correction of any inappropriate characters
      rx_char = ' ';    
    RDS_PS[PS_index * 2 + 1] = rx_char;
  }
  SREG = c_SREG; // restore Status REGister
}

/*** 2x16 LCD DISPLAY (HD44780) ***/

void strobe() // device strobe
{
  sbit(&PORTB, EN);
  cbit(&PORTB, EN);
}

void write_display(unsigned char mode, unsigned char data)
{
  if (mode == 0) // instruction register
    cbit(&PORTB, RS);
  if (mode == 1) // data register
    sbit(&PORTB, RS);

  PORTD &= 0x0F; // clear four upper bits on port D
  PORTD |= (data & 0xF0); // mask on the upper nibble
  strobe();
  PORTD &= 0x0F; // clear four upper bits on port D
  PORTD |= ((data << 4) & 0xF0); // mask on the lower nibble
  strobe();
}

void init_display() // LCD initialization
{
  sbit(&DDRB, RS); // RS as output
  sbit(&DDRB, EN); // EN as output
  DDRD |= 0xF0; // D4...D7 as output
  
  cbit(&PORTB, EN);
  cbit(&PORTB, RS);
  _delay_ms(150);

  PORTD &= 0x0F; // clear four upper bits on port D
  PORTD |= 0x30;
  strobe();
  _delay_ms(5);

  strobe();
  _delay_ms(1);

  write_display(INST, 0x28); // 4-bit bus, 2 lines, 5x8 dots format
  _delay_ms(1);
  write_display(INST, 0x08); // display, cursor and blinking OFF
  _delay_ms(1);
  write_display(INST, 0x01); // clear display
  _delay_ms(2);
  write_display(INST, 0x06); // cursor moving direction
  _delay_ms(1);
  write_display(INST, 0x0C); // display ON
  _delay_ms(1);
}

void write_char(unsigned char data) // char display
{
  write_display(DATA, data);
  _delay_ms(1);
}

void write_text(char *text) // text display
{
  unsigned char i = 0;

  while (text[i] != '\0')
  {
    write_char(text[i]);
    i++;
  }
}

void display_info() // information display
{
  unsigned short int frequency; // channel / station frequency

  read_registers();

  write_text("FM:");
  write_char(EEARL + 1 + 0x30); // favourite nr
  
  write_text("   ");

  frequency = (registers[0x0B] & 0x03FF) + 875; // frequency according to device manufacturer formula
  if (frequency < 1000)
  {
    write_char(' '); // first digit
    write_char((frequency / 100) + 0x30); // second digit
  }
  else
    write_text("10"); // first and second digit
  frequency %= 100;
  write_char((frequency / 10) + 0x30); // third digit
  write_char('.'); // comma
  write_char((frequency % 10) + 0x30); // fourth digit
  write_text(" MHz");

  write_display(INST, 0xC0); // move cursor to the starting position of next/second row
  _delay_ms(1);

  write_text(RDS_PS); // RDS Program Service text

  write_text("  ");

  write_text("VOL:");
  write_char(((registers[0x05] & 0x000F) / 10) + 0x30); // first digit
  write_char(((registers[0x05] & 0x000F) % 10) + 0x30); // second digit

  write_display(INST, 0x02); // move cursor to home position (starting position of first row)
  _delay_ms(2);
}
