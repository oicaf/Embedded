/*
Infrared non-contact thermometer (MLX90614ESF-BAA based).
Commands and results via serial monitor.
*/

#include "IR_Thermometer.h"

void setup() {
  Serial.begin(9600);
  Serial.println("1 - Ambient Temperature");
  Serial.println("2 - Object Temperature");
  Serial.println("3 - Body Temperature (after activation, wait 1s with sensor close to body)");
  Serial.println();
  init_port();
}

void loop() {
  if (Serial.available())
  {
    key = Serial.read();
    switch (key)
    {
      case '1':
        Serial.print("Ambient Temperature = "); Serial.print(read_temp(0x06), 1); Serial.println("°C");
        break;

      case '2':
        Serial.print("Object Temperature = "); Serial.print(read_temp(0x07), 1); Serial.println("°C");
        break;

      case '3':
        _delay_ms(1000);
        Tamb = read_temp(0x06);
        Tobj = read_temp(0x07);
        // option 1 - offset correction
        Serial.print("Body Temperature = "); Serial.print(Tobj + 3.1, 1); Serial.println("°C");
        // option 2 - autocalibration formula
        Serial.print("Body Temperature = "); Serial.print(Tobj + (0.5 * (36.5 - Tobj) + 0.1 * (Tamb - 25)) + 1.5, 1); Serial.println("°C");
        break;
    }
  }
}
