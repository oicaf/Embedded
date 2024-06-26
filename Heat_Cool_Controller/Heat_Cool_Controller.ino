/*
Heating / cooling controller based on hysteresis regulator.
Two temperature sensors: internal (for regulator) and external (information only).
Temperature set-up via B button (increase) and D button (decrease), range 10.0`C - 39.0`C.
Hysteresis selection via B button (increase) and D button (decrease), 0.5`C or 1.0`C (hysteresis menu under E button).
*/

#include "Heat_Cool_Controller.h"

int main()
{
  unsigned char mode = 0; // working mode (0 - normal, 1 - heating, 2 - cooling)
  short int temp; // temperature from sensor (real value x 10)

  init_display();
  //read_code(); // needed only to get temperature sensor unique code, in normal operation must be removed, entire code displayed on LCD (in HEX) must be rewritten into the
               // appropriate array, first byte displayed from the left must be started with index 0 in the array and so on, only one sensor is allowed to be in the bus
               // during this operation (while getting the code)
  write_background();
  init_interrupt();

  while (1)
  {
    temp = temperature();
    mode = regulator(mode, temp);
    _delay_ms(1000);
  }
}
