/*
FM radio with RDS (Si4703 based).
Commands sent via serial monitor.
*/

#include "Radio_FM_RDS_lcd.h"

unsigned char volume = 1; // volume level (min)

int main()
{
  Serial.begin(9600);
  Serial.println("1-9     Favourite Stations");
  Serial.println("u d     Seek up / down");
  Serial.println("+ -     Volume up / down");

  init_radio();
  set_volume(volume);
  clr_eeprom();
  init_interrupt();
  init_display();

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
  }
}
