/*
ARDUINO 
pwm (9pin)
*/

import processing.funnel.*;

Funnel arduino;

int pwmPin = 9;

void setup()
{
  size(200,200);
  frameRate(25);
  
  Configuration config = ARDUINO.FIRMATA;
  config.setDigitalPinMode(pwmPin,ARDUINO.PWM);
  arduino = new Funnel(this,config);
  arduino.autoUpdate = true;

}

void draw()
{
  background(170);
  
  float val = float(mouseX)/width;
  arduino.port(ARDUINO.pwm[0]).value = val;


}

