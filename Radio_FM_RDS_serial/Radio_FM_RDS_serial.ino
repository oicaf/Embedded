/*
FM radio with RDS (Si4703 based).
Commands sent via serial monitor and information presented on serial monitor.
*/

#include "Radio_FM_RDS_serial.h"

unsigned char volume = 1; // volume level (min)
extern char auto_save[13];
extern unsigned short int registers[16];

void display_info() // information display
{
  unsigned short int frequency; // channel / station frequency

  read_registers();
   
  Serial.print("FAVOURITE ");
  Serial.print(EEARL + 1);
  Serial.println(auto_save);
  
  Serial.print("FREQUENCY ");
  frequency = (registers[0x0B] & 0x03FF) + 875; // frequency according to device manufacturer formula
  Serial.print(frequency / 10); // hundreds of MHz
  Serial.print(".");
  Serial.print(frequency % 10); // hundreds of kHz (after comma)
  Serial.println(" MHz");

  Serial.print("RDS(PS)   ");
  Serial.println(read_PS());

  Serial.print("RDS(RT)   ");
  Serial.println(read_RT());
  
  Serial.print("VOLUME    ");
  Serial.println(volume, DEC);

  _delay_ms(20);
}

int main()
{
  Serial.begin(500000);
  Serial.println("1-9     Favourite Stations");
  Serial.println("u d     Seek up / down");
  Serial.println("+ -     Volume up / down");

  radio_init();
  set_volume(volume);
  clr_eeprom();

  while (1)
  {
    if (Serial.available())
    {
      key = Serial.read();
      switch (key)
      {
        case '1'...'9':
          set_channel(key);
          break;

        case 'u':
          seek_channel(key);
          break;

        case 'd':
          seek_channel(key);
          break;
        
        case '+':
          volume++;
          if (volume == 16)
            volume = 15;
          set_volume(volume);
          break;
        
        case '-':
          volume--;
          if (volume == 255)
            volume = 0;
          set_volume(volume);
          break;
      }
    }
    display_info();
    _delay_ms(20);
  }
}
