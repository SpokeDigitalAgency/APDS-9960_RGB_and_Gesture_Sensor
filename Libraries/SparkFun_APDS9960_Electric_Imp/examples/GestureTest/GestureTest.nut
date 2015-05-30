/****************************************************************
GestureTest.nut
APDS-9960 RGB and Gesture Sensor

Ported to Electric Imp by Eric Svensson @ Spoke Digital Agency
April 20, 2015

Based on code written by:
Shawn Hymel @ SparkFun Electronics
May 30, 2014
https://github.com/sparkfun/APDS-9960_RGB_and_Gesture_Sensor

Tests the gesture sensing abilities of the APDS-9960. Configures
APDS-9960 over I2C and waits for gesture events. Calculates the
direction of the swipe (up, down, left, right) and displays it
on a serial console. 

To perform a NEAR gesture, hold your hand
far above the sensor and move it close to the sensor (within 2
inches). Hold your hand there for at least 1 second and move it
away.

To perform a FAR gesture, hold your hand within 2 inches of the
sensor for at least 1 second and then move it above (out of
range) of the sensor.

Hardware Connections:

IMPORTANT: The APDS-9960 can only accept 3.3V!
 
 Arduino Pin  APDS-9960 Board  Function
 
 3.3V         VCC              Power
 GND          GND              Ground
 A4           SDA              I2C Data
 A5           SCL              I2C Clock
 2            INT              Interrupt

Resources:
Requires SparkFun_APDS9960 class from the file SparkFun_APDS9960.class.nut
available in the APDS-9960_RGB_and_Gesture_Sensor repository at
https://github.com/SpokeDigitalAgency/APDS-9960_RGB_and_Gesture_Sensor.

Development environment specifics:
Tested with Electric Imp model imp001.

This code is beerware; if you see us at the local, and you've
found our code helpful, please buy us a round!

Distributed as-is; no warranty is given.
****************************************************************/

// Pins
APDS9960_Int <- hardware.pin1; // Needs to be an interrupt pin
i2c <- hardware.i2c89;

/* Initialize I2C */
i2c.configure(CLOCK_SPEED_10_KHZ);

// Global Variables
apds <- null;

function setup()
{

  server.log("--------------------------------");
  server.log("SparkFun APDS-9960 - GestureTest");
  server.log("--------------------------------");

  // Initialize interrupt service routine
  APDS9960_Int.configure(DIGITAL_IN, onGestureInterrupt);

  // Instantiate APDS9960 class.
  apds <- SparkFun_APDS9960(i2c);

  // Initialize APDS-9960 (configure I2C and initial values)
  if (apds.init())
  {
    server.log("APDS-9960 initialization complete.");
  }
  else
  {
    server.log("Something went wrong during APDS-9960 init!");
  }
  
  // Start running the APDS-9960 gesture sensor engine
  if (apds.enableGestureSensor(true))
  {
      server.log("Gesture sensor is now running.");
  }
  else
  {
      server.log("Something went wrong during gesture sensor init!");
  }
}

function handleGesture()
{
  if ( apds.isGestureAvailable() )
  {
    switch ( apds.readGesture() )
    {
      case apds.DIR_UP:
        server.log("UP");
        break;
      case apds.DIR_DOWN:
        server.log("DOWN");
        break;
      case apds.DIR_LEFT:
        server.log("LEFT");
        break;
      case apds.DIR_RIGHT:
        server.log("RIGHT");
        break;
      case apds.DIR_NEAR:
        server.log("NEAR");
        break;
      case apds.DIR_FAR:
        server.log("FAR");
        break;
      default:
        server.log("NONE");
    }
  }
}

function onGestureInterrupt()
{
  if (APDS9960_Int.read() == 0)
  {
    handleGesture();
  }
}

setup();