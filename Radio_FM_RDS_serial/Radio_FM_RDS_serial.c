#include <string.h>
#include <avr/io.h>
#include <util/delay.h>
#include "Radio_FM_RDS_serial.h"

unsigned char sync_index = 0; // synchronization index for RDS radiotext
unsigned char RDS_ready = 0; // RDS group ready state (0 = no RDS group ready)
char RDS_PS[9] = "        "; // array for RDS Program Service text (max 8 chars + NULL char '\0')
char RDS_RT[65] = "                                                                "; // array for RDS radiotext (max 64 chars + NULL char '\0')
char auto_save[13] = "            "; // "(auto save)" text (12 chars + NULL char '\0')
unsigned short int registers[16]; // 16 x 16-bit device registers

/*** PORT C PINS OPERATIONS ***/

void sda_dir(unsigned char dir) // set SDA direction
{
  if (dir == 0)
    DDRC &= ~(1 << SDA); // SDA as input
  else if (dir == 1)
    DDRC |= (1 << SDA); // SDA as output
}

void sbit(unsigned char pin) // set bit
{
  PORTC |= (1 << pin);
}

void cbit(unsigned char pin) // clear bit
{
  PORTC &= ~(1 << pin);
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
  sbit(SDA);
  sbit(SCL);
  cbit(SDA);
  cbit(SCL);
}

void stp() // stop bit
{
  cbit(SDA);
  sbit(SCL);
  sbit(SDA);
}

void ack() // acknowledgment bit
{
  cbit(SDA);
  sbit(SCL);
  cbit(SCL);
}

void nack() // no acknowledgment bit
{
  sbit(SDA);
  sbit(SCL);
  cbit(SCL);
}

unsigned char read_byte() // read 8-bits
{
  unsigned char i, data = 0;

  sda_dir(_INPUT);
  for (i = 0; i <= 7; i++)
  {
    sbit(SCL);
    if (read_sda())
      data |= 1;
    if (i < 7)
      data <<= 1;
    cbit(SCL);
  }
  sda_dir(_OUTPUT);
  
  return data;
}

void write_byte(unsigned char data) // write 8-bits
{
  unsigned char i;
  
  for (i = 0; i <= 7; i++)
  {
    if ((data & 0x80) == 0)
    {
      cbit(SDA);
    }
    else
    {
      sbit(SDA);
    }
    sbit(SCL);
    cbit(SCL);
    data <<= 1;
  }
  
  sda_dir(_INPUT);
  sbit(SCL);
  cbit(SCL);
  sda_dir(_OUTPUT);
}

/*** EEPROM ***/

void clr_eeprom() // eeprom clean out from 0x08 up to 0x00 addresses
{
  for (char i = 8; i >= 0; i--)
  {
    while (EECR & (1 << EEPE)); // wait for completion of previous write
    EEARH = 0; // eeprom address register (high byte)
    EEARL = i; // eeprom address register (low byte)
    EEDR = 0; // eeprom data register
    EECR |= (1 << EEMPE);
    EECR |= (1 << EEPE); // start eeprom writing
  }
}

void read_eeprom(unsigned char fav) // read data from eeprom, address at current favourite
{
  while (EECR & (1 << EEPE)); // wait for completion of previous write
  EEARH = 0; // eeprom address register (high byte)
  EEARL = fav - 1; // eeprom address register (low byte)
  EECR |= (1 << EERE); // start eeprom reading
  registers[0x03] |= EEDR; // mask on new channel (eeprom data register)
}

void write_eeprom() // write data into eeprom, address at current favourite
{
  while (EECR & (1 << EEPE)); // wait for completion of previous write
  EEDR = registers[0x0B] & 0x00FF; // eeprom data register, mask on channel, only 8 bits is sufficient
  EECR |= (1 << EEMPE);
  EECR |= (1 << EEPE); // start eeprom writing
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

void radio_init() // Si4703 initialization
{
  DDRC = (1 << SCL) | (1 << SDA); // SCL and SDA as output
  DDRD |= (1 << RST); // RST as output

  sbit(SCL);
  cbit(SDA);
  PORTD &= ~(1 << RST); // low on RST
  _delay_ms(1);
  PORTD |= (1 << RST); // high on RST
  _delay_ms(1);
 
  read_registers();
  registers[0x07] = 0x8100; // enable oscillator
  write_registers();
  _delay_ms(500);

  read_registers();
  registers[0x02] = 0x4001; // enable IC
  registers[0x04] |= (1 << RDS) | (1 << DE); // RDS = 1, DE = 1 (50us de-emphasis used in Europe)
  registers[0x05] |= (1 << SPACE); // SPACE = 01 (100kHz channel spacing for Europe)
  write_registers();
  _delay_ms(110);
}

void set_channel(unsigned char _key) // tune into selected channel / frequency
{        
  strcpy(RDS_PS, "        "); // Program Service text clean out when favourite station selected
  strcpy(RDS_RT, "                                                                "); // radiotext clean out when favourite station selected
  sync_index = 0; // start reading radiotext from the beginning when favourite station selected
  RDS_ready = 1; // force to 1 (no rising edge further) due to remaining chars in the registers from previous read
  
  read_registers();
  registers[0x03] &= 0xFE00; // clean out channel bits
  read_eeprom(_key - 0x30);
  registers[0x03] |= (1 << TUNE); // TUNE = 1
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) != 0) // check STC status
      break;
  }
  
  read_registers();
  registers[0x03] &= ~(1 << TUNE); // TUNE = 0
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) == 0) // check STC status
      break;
  }
}

void seek_channel(unsigned char _key)
{
  strcpy(RDS_PS, "        "); // Program Service text clean out when favourite station selected
  strcpy(RDS_RT, "                                                                "); // radiotext clean out when favourite station selected
  sync_index = 0; // start reading radiotext from the beginning when favourite station selected
  RDS_ready = 1; // force to 1 (no rising edge further) due to remaining chars in the registers from previous read
  
  read_registers();
  if (_key == 'u')
    registers[0x02] |= (1 << SEEKUP); // SEEKUP = 1
  if (_key == 'd')
    registers[0x02] &= ~(1 << SEEKUP); // SEEKUP = 0
  registers[0x02] |= (1 << SEEK); // SEEK = 1
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) != 0) // check STC status
      break;
    display_info();
  }
  
  read_registers();
  registers[0x02] &= ~(1 << SEEK); // SEEK = 0
  write_registers();
  
  while (1)
  {
    read_registers();
    if ((registers[0x0A] & (1 << STC)) == 0) // check STC status
      break;
  }

  read_registers();
  write_eeprom();
  strcpy(auto_save, " (auto save)");
  display_info();
  _delay_ms(1000);
  strcpy(auto_save, "            ");
}

void set_volume(unsigned char vol)
{
  read_registers();
  registers[0x05] &= 0xFFF0; // VOLUME = 0
  registers[0x05] |= vol; // set new volume
  write_registers();
}

char *read_PS() // read RDS Program Service text
{
  unsigned char PS_index; // RDS received char index
  unsigned char rx_char; // RDS received char
  
  if (RDS_ready == 0 && (registers[0x0A] & (1 << RDSR)) != 0) // check if new RDS group is ready (rising edge on RDSR)
  {
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
  }
  return RDS_PS;
}

char *read_RT() // read RDS radiotext
{
  unsigned char i;
  unsigned char RT_ready; // RDS radiotext ready
  unsigned char RT_index; // RDS received char index
  char radiotext[65]; // array (buffer) for RDS radiotext (max 64 chars + NULL char '\0')
    
  if (RDS_ready == 0 && (registers[0x0A] & (1 << RDSR)) != 0) // check if new RDS group is ready (rising edge on RDSR)
  {
    if ((registers[0x0D] >> 11) == 4) // group type code 2A (radiotext)
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
          radiotext[4 * RT_index + i] = '\0'; // NULL char at the end of string
          strcpy(RDS_RT, radiotext);
          sync_index = 0;
        }
      }
      else
        sync_index = 0; // start buffering radiotext from the beginning due to frame lost
    }
  }
  RDS_ready = (registers[0x0A] & (1 << RDSR)) >> RDSR; // save current RDSR status

  return RDS_RT;
}
