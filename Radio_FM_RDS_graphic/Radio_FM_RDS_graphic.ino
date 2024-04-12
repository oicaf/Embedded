/*
FM radio with RDS (Si4703 based).
*/

#include "Radio_FM_RDS_graphic.h"

int main()
{
  favourite = 1;
  init_radio();
  set_volume(volume);
  clr_eeprom();
  init_display();
  init_keypad();
  init_interrupt();  

  while (1)
  {
    unsigned long int start_time;

    key = *_PIND & ((1 << LEFT) | (1 << DOWN) | (1 << RIGHT) | (1 << UP));
    if (key != 0xF0) // check if any key is pressed
    {
      switch (key)
      {
        case 0xF0 - (1 << UP): // A button (volume up)
          volume++;
          if (volume == 16)
            volume = 15;
          else
          {
            set_volume(volume);
            _delay_ms(100);
          }
          break;
          
        case 0xF0 - (1 << RIGHT): // B button (next favourite / seek up)
          start_time = millis();
          while ((*_PIND & (1 << RIGHT)) == 0 && (millis() - start_time) < 1000); // while key still pressed and elapsed time less than 1s
          if (millis() - start_time < 1000)
          {
            favourite++;
            if (favourite == 10)
              favourite = 9;
            set_channel(favourite);
          }
          else
          {
            seek_channel('u');
            _delay_ms(1000);            
          }
          break;
          
        case 0xF0 - (1 << DOWN): // C button (volume down)
          volume--;
          if (volume == 255)
            volume = 0;
          else
          {
            set_volume(volume);
            _delay_ms(100);
          }
          break;
          
        case 0xF0 - (1 << LEFT): // D button (previous favourite / seek down)
          start_time = millis();
          while ((*_PIND & (1 << LEFT)) == 0 && (millis() - start_time) < 1000); // while key still pressed and elapsed time less than 1s
          if (millis() - start_time < 1000)
          {
            favourite--;
            if (favourite == 0)
              favourite = 1;
            set_channel(favourite);
          }
          else
          {
            seek_channel('d');
            _delay_ms(1000);            
          }
          break;
      }
    }
    
    display_info();
  }
}
