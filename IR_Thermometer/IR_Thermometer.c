#include <util/delay.h>
#include "IR_Thermometer.h"


/*** BIT OPERATIONS ***/

void sbit(unsigned char pin) // set bit on port C
{
  *_PORTC |= (1 << pin);
}

void cbit(unsigned char pin) // clear bit on port C
{
  *_PORTC &= ~(1 << pin);
}

void dir_sda(unsigned char dir) // set SDA direction
{
  if (dir == 0)
    *_DDRC &= ~(1 << SDA); // SDA as input
  else if (dir == 1)
    *_DDRC |= (1 << SDA); // SDA as output
}

unsigned char read_sda() // read bit on SDA
{
  unsigned char data = *_PINC; // read byte
  data &= (1 << SDA); // mask on SDA
  return (data != 0) ? 1 : 0;
}

/*** SMBus ***/

void start() // start condition
{
  sbit(SDA);
  sbit(SCL);
  _delay_us(5); // tBUF / tSU;STA
  cbit(SDA);
  _delay_us(4); // tHD;STA
  cbit(SCL);
  _delay_us(5); // tLOW
}

void stp() // stop condition
{
  cbit(SDA);
  sbit(SCL);
  _delay_us(4); // tSU;STO
  sbit(SDA);
}

void ack() // acknowledgment bit
{
  cbit(SDA);
  _delay_us(1); // tSU;DAT
  sbit(SCL);
  _delay_us(4); // tHIGH
  cbit(SCL);
  _delay_us(5); // tLOW
}

void nack() // no acknowledgment bit
{
  sbit(SDA);
  _delay_us(1); // tSU;DAT
  sbit(SCL);
  _delay_us(4); // tHIGH
  cbit(SCL);
  _delay_us(5); // tLOW
}

/*** ATmega328 ***/

void init_port() // initial port C configuration
{
  dir_sda(_OUTPUT); // SDA as output
  *_DDRC |= (1 << SCL); // SCL as output
}

/*** MLX90614 ***/

unsigned char read_byte()
{
  unsigned char i, data = 0;

  dir_sda(_INPUT);

  for (i = 0; i <= 7; i++)
  {
    sbit(SCL);
    _delay_us(4); // tHIGH

    if (read_sda())
      data |= 1;
    if (i < 7)
      data <<= 1;

    cbit(SCL);
    _delay_us(5); // tLOW
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
      cbit(SDA);
    else
      sbit(SDA);
    _delay_us(1); // tSU;DAT

    sbit(SCL);
    _delay_us(4); // tHIGH
    cbit(SCL);
    _delay_us(5); // tLOW

    data <<= 1;
  }

  dir_sda(_INPUT);
  
  sbit(SCL);
  _delay_us(4); // tHIGH
  data = read_sda(); // acknowledge status from slave
  cbit(SCL);
  _delay_us(5); // tLOW

  dir_sda(_OUTPUT);
}

float read_temp(unsigned char cmd_code) // read temperatures from RAM
{
  unsigned char byte_low, byte_high;
  float result;

  start();
  write_byte(0xB4); // slave address + write bit
  write_byte(cmd_code); // read-RAM command code
  start();
  write_byte(0xB5); // slave address + read bit
  byte_low = read_byte(); // lower byte
  ack();
  byte_high = read_byte(); // upper byte
  ack();
  stp();

  return result = (float)(((byte_high << 8) & 0xFF00) | byte_low) / 50 - 273.15; // result in Celsius degrees
}
