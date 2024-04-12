#include <string.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "Radio_FM_RDS_graphic.h"


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
  /* if at least one more _sbit is replaced in the code below by sbit(&PORTC, pin) then functionality starts behaving strange, don't know the reason */
  *_PORTC |= (1 << pin);
}

void dir_sda(unsigned char dir) // set SDA direction
{
  if (dir == 0)
    cbit(_DDRC, SDA); // SDA as input
  else if (dir == 1)
    sbit(_DDRC, SDA); // SDA as output
}

unsigned char read_sda() // read bit on SDA
{
  unsigned char data = *_PINC; // read byte
  data &= (1 << SDA); // mask on SDA
  return (data != 0) ? 1 : 0;
}

/*** I2C (TWI) ***/

void start() // start bit
{
  sbit(_PORTC, SDA);
  sbit(_PORTC, SCL);
  cbit(_PORTC, SDA);
  cbit(_PORTC, SCL);
}

void stp() // stop bit
{
  cbit(_PORTC, SDA);
  sbit(_PORTC, SCL);
  sbit(_PORTC, SDA);
}

void ack() // acknowledgment bit
{
  cbit(_PORTC, SDA);
  sbit(_PORTC, SCL);
  cbit(_PORTC, SCL);
}

void nack() // no acknowledgment bit
{
  sbit(_PORTC, SDA);
  sbit(_PORTC, SCL);
  cbit(_PORTC, SCL);
}

/*** ATmega328 ***/

unsigned long int millis() // returns the number of milliseconds passed since the program started
{
  return milliseconds;
}

void clr_eeprom() // eeprom clean out address from 0x08 down to 0x00
{
  for (char i = 8; i >= 0; i--)
  {
    while (*_EECR & (1 << _EEPE)); // wait for completion of previous write
    *_EEARH = 0; // eeprom address register (high byte)
    *_EEARL = i; // eeprom address register (low byte)
    *_EEDR = 0; // eeprom data register
    sbit(_EECR, _EEMPE);
    sbit(_EECR, _EEPE); // start eeprom writing
  }
}

void read_eeprom(unsigned char fav) // read data from eeprom, address at current favourite
{
  while (*_EECR & (1 << _EEPE)); // wait for completion of previous write
  *_EEARH = 0; // eeprom address register (high byte)
  *_EEARL = fav - 1; // eeprom address register (low byte)
  sbit(_EECR, _EERE); // start eeprom reading
  registers[0x03] |= *_EEDR; // mask on new channel (eeprom data register)
}

void write_eeprom() // write data into eeprom, address at current favourite
{
  while (*_EECR & (1 << _EEPE)); // wait for completion of previous write
  *_EEDR = registers[0x0B] & 0x00FF; // eeprom data register, mask on channel, only 8 bits is sufficient
  sbit(_EECR, _EEMPE);
  sbit(_EECR, _EEPE); // start eeprom writing
}

void init_interrupt() // interrupts configuration
{
  /* INT1 setup */
  cbit(_DDRD, INT); // INT as input
  sbit(_PORTD, INT); // pull-up on INT
  sbit(_EICRA, _ISC11); // falling edge on INT1 generates an interrupt request
  sbit(_EIMSK, _INT1); // external interrupt request 1 enable

  /* TIMER0 setup */
  sbit(_TCCR0A, _WGM01); // CTC mode
  *_OCR0A = 249; // value to reach 1 ms for prescaler 64
  sbit(_TIMSK0, _OCIE0A); // compare match A interrupt enable
  sbit(_TCCR0B, _CS00); // prescaler...
  sbit(_TCCR0B, _CS01); // ...64

  sbit(_SREG, 7); // enable global interrupts
}

ISR(INT1_vect) // Interrupt Service Routine from INT1 (RDS PS and RDS RT decode)
{
  char c_SREG = *_SREG; // store Status REGister

  unsigned char i;
  unsigned char PS_index; // RDS received char index
  unsigned char rx_char; // RDS received char
  unsigned char RT_ready; // RDS radiotext ready
  unsigned char RT_index; // RDS received char index
  
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

  if ((registers[0x0D] >> 11) == 4) // group type code 2A (RadioText)
  {
    RT_ready = 0;
    RT_index = registers[0x0D] & 0x0F; // mask on received char index
    if (RT_index == sync_index) // check if received radiotext index is the same as expected one, if no then frame lost
    {
      radiotext[4 * RT_index + 0] = registers[0x0E] >> 8; // first char
      radiotext[4 * RT_index + 1] = registers[0x0E]; // second char
      radiotext[4 * RT_index + 2] = registers[0x0F] >> 8; // third char
      radiotext[4 * RT_index + 3] = registers[0x0F]; // fourth char

      for (i = 0; i <= 3; i++)
      {
        if (radiotext[RT_index + i] == 0x0A) // correction of LF char received '\n'
          radiotext[RT_index + i] = ' '; // LF = space
        if (radiotext[RT_index + i] == 0x0D) // correction of CR char received '\r'
        {
          RT_ready = 1;
          break;
        }
      }

      if (!RT_ready)
      {
        sync_index++;
        i = 0;
      }

      if (RT_ready || RT_index == 0x0F) // complete radiotext received
      {
        A_B = (registers[0x0D] >> 4) & 0x01;
        if (RT_changed != A_B) // check if received RT message is a copy of previous one
        {
          radiotext[4 * RT_index + i] = '\0'; // NULL char at the end of string
          strcpy(RDS_RT, radiotext);
          RT_changed = A_B; // A/B bit update
          RT_new = 1;
        }
        sync_index = 0; // reset synchronization index
      }
    }
    else
      sync_index = 0; // start buffering radiotext from the beginning due to frame lost
  }
  
  *_SREG = c_SREG; // restore Status REGister
}

ISR(TIMER0_COMPA_vect) // Interrupt Service Routine from TIMER0 ("millis" function)
{
  milliseconds++;
}

/*** Si4703 ***/

unsigned char read_byte()
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
    cbit(_PORTC, SCL);
  }
  dir_sda(_OUTPUT);
  
  return data;
}

void write_byte(unsigned char data)
{
  unsigned char i;
  
  for (i = 0; i <= 7; i++)
  {
    if ((data & 0x80) == 0)
    {
      cbit(_PORTC, SDA);
    }
    else
    {
      _sbit(SDA);
    }
    _sbit(SCL);
    cbit(_PORTC, SCL);
    data <<= 1;
  }
  
  dir_sda(_INPUT);
  _sbit(SCL);
  cbit(_PORTC, SCL);
  dir_sda(_OUTPUT);
}

void read_registers() // read all (16) registers
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

void write_registers() // registers (6) update
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

void init_radio() // radio initialization
{
  sbit(_DDRC, SDA); // SDA as output
  sbit(_DDRC, SCL); // SCL as output
  sbit(_DDRD, RST); // RST as output

  _sbit(SCL);
  cbit(_PORTC, SDA);
  cbit(_PORTD, RST);
  _delay_ms(1);
  sbit(_PORTD, RST);
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

void set_channel(unsigned char fav) // tune into selected channel / frequency
{
  strcpy(RDS_PS, "        "); // Program Service text clean out when favourite station selected
  strcpy(RDS_RT, "                                                                "); // radiotext clean out when favourite station selected
  strcpy(RT_window, "                "); // radiotext window clean out when favourite station selected
  sync_index = 0; // start reading radiotext from the beginning when favourite station selected
  
  read_registers();
  registers[0x03] &= 0xFE00; // clean out channel bits
  read_eeprom(fav);
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
  strcpy(RDS_RT, "                                                                "); // radiotext clean out when favourite station selected
  strcpy(RT_window, "                "); // radiotext window clean out when favourite station selected
  sync_index = 0; // start reading radiotext from the beginning when favourite station selected
  
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

void display_freq() // display frequency
{
  unsigned short int frequency; // channel / station frequency
    
  write_text("  ");
  frequency = (registers[0x0B] & 0x03FF) + 875; // frequency according to device manufacturer formula
  if (frequency < 1000)
  {
    write_text("  "); // first digit
    write_char(0xA3);
    write_char((frequency / 100) + 0xB0); // second digit
  }
  else
  {
    write_char(0xA3);
    write_char(0xB1); // first digit (1)
    write_char(0xA3);
    write_char(0xB0); // second digit (0)            
  }
  frequency %= 100;
  write_char(0xA3);
  write_char((frequency / 10) + 0xB0); // third digit
  write_char(0xA3);
  write_char(0xAE); // (.) character
  write_char(0xA3);
  write_char((frequency % 10) + 0xB0); // fourth digit
  write_text("MHz ");
}

void display_PS() // display RDS Program Service (16x16 dot matrix fonts)
{
  unsigned char i = 0;
  
  while (RDS_PS[i] != '\0')
  {
    write_char(0xA3);
    write_char(RDS_PS[i] - 0x20 + 0xA0);
    i++;
  }
}

void display_RT() // display RDS RadioText (16x8 dot matrix fonts)
{
  unsigned char i;
  
  if (millis() - start_time >= 250) // scrolling speed in milliseconds
  {
    start_time = millis();

    if (RT_offset == 1)
      _delay_ms(500);

    if (RT_new == 1) // if radiotext message has new content then start filling window with new message from the beginning
    {
      RT_offset = 0;
      RT_new = 0;
    }
  
    for (i = 0; i <= 15; i++) // 16x characters window
    {
      if (RDS_RT[RT_offset + i] == '\0') // if last part of actual radiotext is less than 16 chars then loop back
      {
        RT_offset = -1;
        break;
      }
      RT_window[i] = RDS_RT[RT_offset + i];
    }
    RT_window[i] = '\0';
    RT_offset++;
  }
  write_text(RT_window);
}

void display_RSSI() // display Received Signal Strength Indicator
{
  unsigned char y;
  unsigned char RSSI_level; // RSSI level from 0 to 75
  unsigned char RSSI_icon[32]; // auxiliary array for selecting one icon from five available depending on the RSSI level

  write_display(INST, 0x26); // 4-bit bus, extended instruction, graphic display ON
  _delay_us(72);

  RSSI_level = registers[0x0A] & 0x00FF; // values from 0 to 75 (dBuV)
  switch (RSSI_level)
  {
    case 0 ... 9:
      memcpy(RSSI_icon, RSSI_0, 32); // zero bars
      break;
    case 10 ... 19:
      memcpy(RSSI_icon, RSSI_1, 32); // one bar
      break;
    case 20 ... 29:
      memcpy(RSSI_icon, RSSI_2, 32); // two bars
      break;
    case 30 ... 39:
      memcpy(RSSI_icon, RSSI_3, 32); // three bars
      break;
    case 40 ... 255:
      memcpy(RSSI_icon, RSSI_4, 32); // four bars
      break;
  }
 
  for (y = 0; y <= 15; y++) // vertical address range
  {
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x80); // horizontal address at 0x00
    _delay_us(72);
    write_display(DATA, RSSI_icon[2 * y]); // first data byte
    _delay_us(72);
    write_display(DATA, RSSI_icon[2 * y + 1]); // second data byte
    _delay_us(72);
  }
}

void display_invers() // display favourite nr inversed
{
  for (unsigned char y = 0; y <= 15; y++) // vertical address range
  {
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x84); // horizontal address at 0x00
    _delay_us(72);
    write_display(DATA, 0xFF); // first data byte
    _delay_us(72);
    write_display(DATA, 0x80); // second data byte
    _delay_us(72);
  }
}

void display_vol() // display volume
{
  unsigned char y;
  unsigned char vol_level; // volume level from 0 to 15
  unsigned char VOL_icon[32]; // auxiliary array for selecting one icon from four available depending on the volume level

  vol_level = registers[0x05] & 0x000F; // values from 0 to 15
  switch (vol_level)
  {
    case 0:
      memcpy(VOL_icon, VOL_0, 32); // mute
      break;
    case 1 ... 5:
      memcpy(VOL_icon, VOL_1, 32); // low level
      break;
    case 6 ... 10:
      memcpy(VOL_icon, VOL_2, 32); // middle level
      break;
    case 11 ... 15:
      memcpy(VOL_icon, VOL_3, 32); // high level
      break;
  }

  for (y = 0; y <= 15; y++) // vertical address range
  {
    write_display(INST, 0x80 + y); // set vertical address
    _delay_us(72);
    write_display(INST, 0x87); // horizontal address at 0x07
    _delay_us(72);
    write_display(DATA, VOL_icon[2 * y]); // first data byte
    _delay_us(72);
    write_display(DATA, VOL_icon[2 * y + 1]); // second data byte
    _delay_us(72);
  }

  write_display(INST, 0x20); // 4-bit bus, basic instruction
  _delay_us(72);
}

void display_info() // information display
{
  read_registers();

  write_text("        ");
  write_char(favourite + 0x30); // favourite nr
  write_text("       ");
  write_display(INST, 0x90); // move cursor to the starting position of the second line
  _delay_us(72);

  display_freq();
  write_display(INST, 0x88); // move cursor to the starting position of the third line
  _delay_us(72);

  display_PS();
  write_display(INST, 0x98); // move cursor to the starting position of the fourth line
  _delay_us(72);

  display_RT();

  display_RSSI();

  display_invers();
  
  display_vol();

  write_display(INST, 0x02); // move cursor to home position (starting position of the first line)
  _delay_us(72);
}

void init_keypad() // keypad initialization
{
  *_DDRD &= ~((1 << LEFT) | (1 << DOWN) | (1 << RIGHT) | (1 << UP)); // keypad bottons (A, B, C, D) as input
  *_PORTD |= (1 << LEFT) | (1 << DOWN) | (1 << RIGHT) | (1 << UP); // pull-ups on keypad
}
