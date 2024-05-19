#include <stdlib.h>
#include <string.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include "Heat_Cool_Controller.h"

unsigned short int set_temp = 220; // temperature set x 10 (22.0`C as default)


/*** BIT OPERATIONS ***/

void sbit(volatile unsigned char *reg, unsigned char bit) // set bit in register
{
  *reg |= (1 << bit);
}

void cbit(volatile unsigned char *reg, unsigned char bit) // clear bit in register
{
  *reg &= ~(1 << bit);
}

unsigned char rbit(volatile unsigned char *reg, unsigned char bit) // read bit from register
{
  unsigned char data = *reg; // read byte
  data &= (1 << bit); // mask on bit
  return (data != 0) ? 1 : 0;
}

/*** DS18B20 ***/

void reset() // initialization (reset and presence pulses)
{
  sbit(_DDRD, DQ); // DQ as output
  cbit(_PORTD, DQ); // pull 1-Wire bus low
  _delay_us(500);
  sbit(_PORTD, DQ); // pull 1-Wire bus high
  cbit(_DDRD, DQ); // DQ as input
  while (rbit(_PIND, DQ)); // wait for DS18B20 presence pulse (pulling 1-Wire bus low)
  _delay_us(500);
}

void write_byte(unsigned char data) // write ROM or function command
{
  unsigned char i;

  sbit(_DDRD, DQ); // DQ as output
  for (i = 0; i <= 7; i++)
  {
    cbit(_PORTD, DQ); // write time slots are initiated by the master pulling the 1-Wire bus low for at least 1us
    _delay_us(1);

    if ((data & 0x01) == 0) // LSB first
      cbit(_PORTD, DQ);
    else
      sbit(_PORTD, DQ);

    _delay_us(60); // all write time slots must be min 60μs in duration
    sbit(_PORTD, DQ);
    _delay_us(1); // min 1μs recovery time between individual slots
    data >>= 1;
  }
}

unsigned char read_byte() // read ROM or function command
{
  unsigned char i, data = 0;

  for (i = 0; i <= 7; i++)
  {
    sbit(_DDRD, DQ); // DQ as output    
    cbit(_PORTD, DQ); // read time slots are initiated by the master pulling the 1-Wire bus low for at least 1us
    _delay_us(1);
    sbit(_PORTD, DQ);
    _delay_us(5); // needed to stabilize the high level (T(RC))
    cbit(_DDRD, DQ); // DQ as input

    if (rbit(_PIND, DQ))
      data |= 0x80;
    if (i < 7)
      data >>= 1;
            
    _delay_us(60); // all read time slots must be min 60μs in duration
    _delay_us(1); // min 1μs recovery time between individual slots
  }
  return data;
}

short int read_temp(const unsigned char *ROM_code) // read temperature from sensor
{
  unsigned char i, low_byte, high_byte;
  short int temp = 0;
  
  reset(); // reset pulse
  write_byte(0x55); // match ROM command
  for (i = 0; i <= 7; i++)
    write_byte(ROM_code[i]); // DS18B20 ROM code
  write_byte(0x44); // convert temperature command

  cbit(_DDRD, DQ); // DQ as input
  while (!rbit(_PIND, DQ)); // waiting for the temperature conversion is complete
  
  reset(); // reset pulse
  write_byte(0x55); // match ROM command
  for (i = 0; i <= 7; i++)
    write_byte(ROM_code[i]); // DS18B20 ROM code
  write_byte(0xBE); // read scratchpad command

  low_byte = read_byte(); // LS byte
  high_byte = read_byte(); // MS byte
  temp = high_byte << 8 | low_byte;
  if ((high_byte & 0x80) != 0) // negative value 
    temp = ~temp + 1; // conversion to positive value
  temp = ((temp >> 4) * 10) + ((temp & 0x000F) * 10 / 16);
  if ((high_byte & 0x80) != 0) // negative value 
    temp = ~temp + 1; // conversion to negative value

  return temp; // integer temperature value x 10 (ex. 5 means +0.5`C, 101 means +10.1`C, 1250 means +125.0`C, -250 means -25.0`C, -550 means -55.0`C etc.)
}

/*** 128x64 LCD DISPLAY (ST7920-0B) ***/

void write_display(unsigned char mode, unsigned char data) // write instruction or data to display
{
  unsigned char i, j;
  
  sbit(_PORTB, MOSI);
  cbit(_PORTB, SCK);
  for (i = 0; i <= 4; i++) // synchronizing bit string
  {
    sbit(_PORTB, SCK);
    cbit(_PORTB, SCK);
  }
  cbit(_PORTB, MOSI); // write mode
  sbit(_PORTB, SCK);
  cbit(_PORTB, SCK);
  if (mode == DATA) // data register, otherwise instruction register
    sbit(_PORTB, MOSI);
  sbit(_PORTB, SCK);
  cbit(_PORTB, SCK);
  cbit(_PORTB, MOSI);
  sbit(_PORTB, SCK);
  cbit(_PORTB, SCK);
  for (i = 0; i <= 1; i++) // two bytes (4 bits higher data + four zeros and 4 bits lower data + four zeros)
  {
    for (j = 0; j <= 3; j++)
    {
      if ((data & 0x80) == 0)
      {
        cbit(_PORTB, MOSI);
      }
      else
      {
        sbit(_PORTB, MOSI);
      }
      sbit(_PORTB, SCK);
      cbit(_PORTB, SCK);
      data <<= 1;      
    }
    cbit(_PORTB,MOSI);
    for (j = 0; j <= 3; j++)
    {
      sbit(_PORTB, SCK);
      cbit(_PORTB, SCK);      
    }    
  }
}

void init_display() // display initialization
{
  sbit(_DDRB, MOSI); // MOSI as output
  sbit(_DDRB, SCK); // SCK as output
  
  write_display(INST, 0x20); // 4-bit bus, basic instruction
  _delay_us(72);
  write_display(INST, 0x08); // display, cursor and blinking OFF
  _delay_us(72);
  write_display(INST, 0x01); // clear display
  _delay_ms(2);
  write_display(INST, 0x06); // cursor moving direction
  _delay_us(72);
  write_display(INST, 0x0C); // display ON
  _delay_us(72);

  /* clear graphic display */
  write_display(INST, 0x24); // 4-bit bus, extended instruction, graphic display OFF
  _delay_us(72);

  for (unsigned char y = 0; y <= 31; y++) // vertical address range
  {
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x80); // set horizontal address
    _delay_us(72);
    for (unsigned char x = 0; x <= 15; x++) // horizontal address range
    {
      write_display(DATA, 0x00); // first data byte
      _delay_us(72);
      write_display(DATA, 0x00); // second data byte
      _delay_us(72);
    }
  }

  write_display(INST, 0x20); // 4-bit bus, basic instruction
  _delay_us(72);
  write_display(INST, 0x01); // clear display
  _delay_ms(2);
}

void write_char(unsigned char data) // display character
{
  write_display(DATA, data);
  _delay_us(72);
}

void write_text(char *text) // display text
{
  unsigned char i = 0;

  while (text[i] != '\0')
  {
    write_char(text[i]);
    i++;
  }
}

void display_set_temp() // display set temperature
{
  write_char(' ');
  write_char(0x30 + set_temp / 100); // first digit
  write_char(0x30 + (set_temp % 100 / 10)); // second digit
  write_char('.');
  write_char(0x30 + set_temp % 10); // third digit after comma
  write_char('`');
  write_char('C');
  write_char(' ');
}

void write_background() // display house picture + default set temperature
{
  const unsigned char house[] = {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x01, 0x80, 0x3E, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x06, 0x60, 0x22, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x18, 0x18, 0x22, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x60, 0x06, 0x22, 0x00, 0x00,
    0x00, 0x00, 0x01, 0x80, 0x01, 0xA2, 0x00, 0x00,
    0x00, 0x00, 0x06, 0x00, 0x00, 0x62, 0x00, 0x00,
    0x00, 0x00, 0x18, 0x00, 0x00, 0x1A, 0x00, 0x00,
    0x00, 0x00, 0x60, 0x00, 0x00, 0x06, 0x00, 0x00,
    0x00, 0x01, 0x80, 0x00, 0x00, 0x01, 0x80, 0x00,
    0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x60, 0x00,
    0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00,
    0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00,
    0x01, 0x80, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80,
    0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x60,
    0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x38,
    0x64, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x26,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
    0x07, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0
  }; // "house" bitmap

  write_display(INST, 0x26); // 4-bit bus, extended instruction, graphic display ON
  _delay_us(72);

  for (unsigned char y = 0; y <= 31; y++) // vertical address range
  {
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x84); // set horizontal address at 0x04
    _delay_us(72);
    for (unsigned char x = 0; x <= 3; x++) // horizontal address range
    {
      write_display(DATA, house[8 * y + 2 * x]); // first data byte
      _delay_us(72);
      write_display(DATA, house[8 * y + 2 * x + 1]); // second data byte
      _delay_us(72);
    }
  }

  for (unsigned char y = 0; y <= 7; y++) // vertical address range
  {
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x8C); // set horizontal address at 0x0C
    _delay_us(72);
    for (unsigned char x = 0; x <= 3; x++) // horizontal address range
    {
      write_display(DATA, house[256 + (8 * y + 2 * x)]); // first data byte
      _delay_us(72);
      write_display(DATA, house[256 + (8 * y + 2 * x + 1)]); // second data byte
      _delay_us(72);
    }
  }

  write_display(INST, 0x20); // 4-bit bus, basic instruction
  _delay_us(72);

  write_display(INST, 0x99); // move cursor to line 4
  _delay_us(72);
  write_char(' '); // symbol indicating...
  write_char(0x1F); // ...button released
  display_set_temp();
  write_char(0x1E); // symbol indicating...
  write_char(' '); // ...button released
}

void display_temp(short int temp) // display temperature
{
  unsigned char sign; // 0 - positive temperature, 1 - negative temperature
  short int _div = 1000; // divider
  short int _temp;

  if (temp < 0)
  {
    sign = 1;
    _temp = ~temp + 1;
  }
  else
  {
    sign = 0;
    _temp = temp;
  }

  if (_temp == 0)
    write_text("    0");
  else
  {
    if (_temp / _div == 0) // first digit
    {
      if (sign == 1 && _temp / (_div / 10) != 0)
        write_char('-');
      else
        write_char(' ');
    }
    else
      write_char(0x30 + _temp / _div);
  
    _temp %= _div;
    _div /= 10;
    if (_temp / _div == 0 && temp / _div == 0) // second digit
    {
      if (sign == 1)
        write_char('-');
      else
        write_char(' ');
    }
    else
      write_char(0x30 + _temp / _div);
  
    _temp %= _div;
    _div /= 10;
    write_char(0x30 + _temp / _div); // third digit
    write_char('.');
    write_char(0x30 + _temp % _div); // fourth digit
  }
  write_text("`C");
}

void write_icon(unsigned char mode) // display icon depending on the mode
{
  const unsigned char NORM[] = {0x00,0x20,0x00,0x20,0x00,0x20,0x00,0x20,0x00,0x20,0x00,0x20,0x00,0x20,0xFF,0xE0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
  const unsigned char HEAT[] = {0x00,0x00,0x00,0x00,0x08,0x88,0x11,0x10,0x22,0x20,0x22,0x20,0x11,0x10,0x08,0x88,0x04,0x44,0x04,0x44,0x08,0x88,0x11,0x10,0x00,0x00,0x00,0x00,0x7f,0xfe,0x00,0x00};
  const unsigned char COOL[] = {0x00,0x00,0x00,0x80,0x00,0x80,0x08,0x88,0x04,0x90,0x02,0xa0,0x01,0xc0,0x3f,0xfe,0x01,0xc0,0x02,0xa0,0x04,0x90,0x08,0x88,0x00,0x80,0x00,0x80,0x00,0x00,0x00,0x00};

  unsigned char y;
  unsigned char MODE_icon[32]; // auxiliary array for selecting one icon from three available depending on the mode
  
  cbit(_SREG, 7); // disable global interrupts
  
  write_display(INST, 0x26); // 4-bit bus, extended instruction, graphic display ON
  _delay_us(72);
  
  switch (mode)
  {
    case 0: memcpy(MODE_icon, NORM, 32); // normal icon
            break;
    case 1: memcpy(MODE_icon, HEAT, 32); // heating icon
            break;
    case 2: memcpy(MODE_icon, COOL, 32); // cooling icon
            break;
  }

  for (y = 0; y <= 15; y++) // vertical address range
  {
    //write_display(INST, 0x90 + y); // set vertical address
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x9F); // horizontal address at 0x0F
    _delay_us(72);
    write_display(DATA, MODE_icon[2 * y]); // first data byte
    _delay_us(72);
    write_display(DATA, MODE_icon[2 * y + 1]); // second data byte
    _delay_us(72);
  }
  
  write_display(INST, 0x20); // 4-bit bus, basic instruction
  _delay_us(72);

  sbit(_SREG, 7); // enable global interrupts
}

/*** ATmega328 ***/

void init_interrupt() // interrupts configuration
{
  /* INT0 & INT1 setup */
  *_DDRD &= ~((1 << LEFT) | (1 << RIGHT)); // keypad B and D buttons as input
  *_PORTD |= (1 << LEFT) | (1 << RIGHT); // pull-ups on keypad
  *_EICRA |= (1 << _ISC11) | (1 << _ISC01); // falling edge on INT0 and INT1 generates an interrupt request
  *_EIMSK |= (1 << _INT1) | (1 << _INT0); // external interrupt request 0 and 1 enable

  sbit(_SREG, 7); // enable global interrupts
}

ISR(INT0_vect) // Interrupt Service Routine from INT0 (B button)
{
  char c_SREG = *_SREG; // store Status REGister

  set_temp += 5; // increase set temperature by 0.5`C
  if (set_temp > 390)
    set_temp = 390;

  write_display(INST, 0x9A); // move cursor to line 4
  _delay_us(72);
  display_set_temp();
  
  write_char(' '); // symbol indicating...
  write_char(' '); // ...button pressed  
  _delay_ms(300);
  
  write_display(INST, 0x9E);
  _delay_us(72);
  write_char(0x1E); // symbol indicating...
  write_char(' '); // ...button released
  
  *_SREG = c_SREG; // restore Status REGister
}

ISR(INT1_vect) // Interrupt Service Routine from INT1 (D button)
{
  char c_SREG = *_SREG; // store Status REGister

  set_temp -= 5; // decrease set temperature by 0.5`C
  if (set_temp < 100)
    set_temp = 100;
  
  write_display(INST, 0x99); // move cursor to line 4
  _delay_us(72);
  write_char(' '); // symbol indicating...
  write_char(' '); // ...button pressed
  _delay_ms(300);
  
  display_set_temp();
  write_display(INST, 0x99);
  _delay_us(72);
  write_char(' '); // symbol indicating...
  write_char(0x1F); // ...button released
  
  *_SREG = c_SREG; // restore Status REGister
}

short int temperature() // external and internal temperatures operations
{
  const unsigned char ext_code[8] = {0x28,0xCF,0xA4,0x1C,0x59,0x20,0x01,0xC9}; // external temperature sensor ROM code
  const unsigned char int_code[8] = {0x28,0xFF,0x64,0x0E,0x71,0x3D,0x5B,0x48}; // internal temperature sensor ROM code
  short int temp; // temperature from sensor (real value x 10)
  
  cbit(_SREG, 7); // disable global interrupts
  
  write_display(INST, 0x90); // move cursor to line 2
  _delay_us(72);
  
  temp = read_temp(ext_code); // read temperature from external sensor
  display_temp(temp); // display external temperature
  write_char(' ');
  
  temp = read_temp(int_code); // read temperature from internal sensor
  if (temp >= 1000)
      write_text("  HIGH  ");
  else if (temp <= -100)
      write_text("   LOW  ");
  else
  {
    display_temp(temp); // display internal temperature
    write_char(' ');
  }
  
  sbit(_SREG, 7); // enable global interrupts

  return temp;
}

unsigned char regulator(unsigned char mode, short int temp) // hysteresis based regulator
{
  short int temp_diff; // temperature difference between set and measured (internal)
  
  if (temp <= 95)
  {
    if (mode != 1) // not in heating mode
    {
      mode = 1; // activate heating mode
      write_icon(mode); // display heating icon
    }
  }
  else
  {
    temp_diff = set_temp - temp;
    switch (mode)
    {
      case 0: if (abs(temp_diff) >= 5)
              {
                if (temp_diff > 0)
                  mode = 1; // activate heating mode
                else
                  mode = 2; // activate cooling mode
                write_icon(mode); // display icon depending on the mode
              }
              break;
      case 1: if (temp_diff <= 0)
              {
                mode = 0; // activate normal mode
                write_icon(mode); // display normal icon
              }
              break;
      case 2: if (temp_diff >= 0)
              {
                mode = 0; // activate normal mode
                write_icon(mode); // display normal icon
              }
              break;
    }
  }
  return mode;
}

void read_code() // read and display temperature sensor unique code (in HEX)
{
  unsigned char i, code[8];

  reset();  // reset pulse
  write_byte(0x33); // read ROM command
  for (i = 0; i < 8; i++)
    code[i] = read_byte(); // read 64-bit ROM code and store it into the auxiliary array
  for (i = 0; i < 8; i++)
  {
    if ((code[i] >> 4) < 10) // first letter
      write_char(0x30 + (code[i] >> 4));
    else
      write_char(0x37 + (code[i] >> 4));

    if ((code[i] & 0x0F) < 10) // second letter
      write_char(0x30 + (code[i] & 0x0F));
    else
      write_char(0x37 + (code[i] & 0x0F));
  }
  while (1);
}
