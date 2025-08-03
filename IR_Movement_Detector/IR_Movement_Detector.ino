/*
Infrared intrusion / movement detector (MLX90614ESF-BAA based).
Detection status on LED_BUILTIN.
Parameters like threshold (sensitivity), delay between temperature measurements or condition when background should be updated are to be adapted individually.
*/

#include "IR_Movement_Detector.h"

void setup()
{
  Serial.begin(9600);
  init_port();
  led(_LOW);

  Serial.println("Select Sensitivity:");
  Serial.println("1 - HIGH");
  Serial.println("2 - MID");
  Serial.println("3 - LOW");
  
  while (!Serial.available());
  key = Serial.read();
  switch (key)
  {
    case '1':
      threshold = 0.25;
      Serial.println("HIGH Sensitivity Selected");
      break;
    case '2':
      threshold = 0.5;
      Serial.println("MID Sensitivity Selected");
      break;
    case '3':
      threshold = 0.75;
      Serial.println("LOW Sensitivity Selected");
      break;
  }
  T_base = read_temp(0x07);
}

void loop()
{
  T_curr = read_temp(0x07);
  if (abs(T_curr - T_base) <= 0.1)
    T_base = T_curr;
  _delay_ms(500);
  T_obj = read_temp(0x07);
  if ((T_obj - T_base) >= threshold)
  {
    do
    {
      led(_HIGH);
      _delay_ms(500);
      led(_LOW);
      T_obj = read_temp(0x07);
      if ((T_obj - T_base) < threshold)
        break;
    } while (1);
  }
}
