/* Includes
______________________________________________________________________*/

#include <Wire.h>
#include <NewSoftSerial.h>
#include "LedControl.h"

/* CHANGE THIS DEPENDING ON THE CUBE
_____________________________________________________________________*/

int xbeeNumber = 2;

/* Global properties
______________________________________________________________________*/

long previousMillis = 0;
boolean enabled = true;

LedControl lc = LedControl(12,11,10,1);

/* XBee Properties
______________________________________________________________________*/

NewSoftSerial XBee = NewSoftSerial(2, 3);
long previousMessage = 0;
int computerNumber = 1;
char identifier = '*';

/* Accelerometer properties
______________________________________________________________________*/

int xVal = 0;           
int yVal = 0;
int zVal = 0;
int difference = 50;            // value difference used in side detection
int enableSec = 1000;           // when counter is this the side changes
int formerSide = 0;
int curSide = 0;                // this is used to find the right side
int curSideChecked = 0;         // this is always the right side        

/* Gyro properties
______________________________________________________________________*/

byte data[6];                   // six data bytes
int formerYaw, formerPitch, formerRoll;
int yaw, pitch, roll;           // three axes
int yaw0, pitch0, roll0;        // calibration zeroes
int gyroReading = 0;

/* Setup
______________________________________________________________________*/

void setup()
{
   XBee.begin(9600);
   
   initAccelerometer();
   
   initGyro();
   
   lc.shutdown(0,false);
   lc.setIntensity(0,8);
   
   setLEDs();
}

/* Initialize accelerometer
______________________________________________________________________*/

void initAccelerometer()
{
    readAccelerometer();
    
    // set startup side
    formerSide = curSide;
    curSideChecked = curSide;
}

/* Initialize gyro
______________________________________________________________________*/

void initGyro()
{
   Wire.begin();
   
   enableWii();                        
   
   calibrateWii();              
   
   delay(1000); 
}

/* Set LED
______________________________________________________________________*/

void setLEDs()
{
    lc.setLed(0, 0, 2, true);     // red
   
    lc.setLed(0, 1, 0, true);    // green
   
    lc.setLed(0, (xbeeNumber == 2) ? 4 : 2, 1, true);    // blue
   
    lc.setLed(0, 3, 2, true);     // red
    lc.setLed(0, 3, 0, true);     // green
    
    lc.setLed(0, (xbeeNumber == 2) ? 2 : 4, 2, true);    // red
    lc.setLed(0, (xbeeNumber == 2) ? 2 : 4, 1, true);    // blue
   
    lc.setLed(0, 5, 1, true);    //  blue
    lc.setLed(0, 5, 0, true);    // green
}

/* Loop
______________________________________________________________________*/

void loop()
{
   if(xbeeNumber == 3)
   {
     readAccelerometer();
   
     calculateSide();
   
     readGyro();
   }
   
   checkMessage(); 
   
   //debugMode();
   
   delay(10);
}

/* Debug mode
______________________________________________________________________*/

/*void debugMode()
{
   XBee.print("Current Side: ");
   
   if(!enabled)  XBee.print(-1);
   else  XBee.print(curSideChecked);
   
   XBee.print(" xVal: ");
   XBee.print(xVal);
   XBee.print(" yVal: ");
   XBee.print(yVal);
   XBee.print(" zVal: ");
   XBee.print(zVal);
   
   XBee.print(" Yaw: ");
   XBee.print(yaw);
   XBee.print(" Pitch: ");
   XBee.print(pitch);
   XBee.print(" Roll: ");
   XBee.println(roll);
}*/

/* Read Accelerometer
______________________________________________________________________*/

void readAccelerometer()
{
   // read values
   xVal = analogRead(0);
   yVal = analogRead(2);
   zVal = analogRead(1);
   
   switch(curSide)
   {
     case 1:   
        if(zVal > xVal + difference && zVal > yVal + difference)    curSide = 1;  
        else if(zVal < xVal - difference && zVal < yVal - difference)    curSide = 2;
        else if(yVal < xVal - difference && yVal < zVal - difference)    curSide = 3;
        else if(yVal > xVal + difference && yVal > zVal + difference)    curSide = 4;
        else if(xVal > yVal + difference && xVal > zVal + difference)    curSide = 5;
        else if(xVal < yVal - difference && xVal < zVal - difference)    curSide = 0; 
        break;
     case 2:  
        if(zVal < xVal - difference && zVal < yVal - difference)    curSide = 2;
        else if(yVal < xVal - difference && yVal < zVal - difference)    curSide = 3;
        else if(yVal > xVal + difference && yVal > zVal + difference)    curSide = 4;
        else if(xVal > yVal + difference && xVal > zVal + difference)    curSide = 5;
        else if(xVal < yVal - difference && xVal < zVal - difference)    curSide = 0;    
        else if(zVal > xVal + difference && zVal > yVal + difference)    curSide = 1;
        break;
     case 3:
        if(yVal < xVal - difference && yVal < zVal - difference)    curSide = 3;
        else if(yVal > xVal + difference && yVal > zVal + difference)    curSide = 4;
        else if(xVal > yVal + difference && xVal > zVal + difference)    curSide = 5;
        else if(xVal < yVal - difference && xVal < zVal - difference)    curSide = 0;    
        else if(zVal > xVal + difference && zVal > yVal + difference)    curSide = 1;  
        else if(zVal < xVal - difference && zVal < yVal - difference)    curSide = 2;
        break;
     case 4:
        if(yVal > xVal + difference && yVal > zVal + difference)    curSide = 4;
        else if(xVal > yVal + difference && xVal > zVal + difference)    curSide = 5;
        else if(xVal < yVal - difference && xVal < zVal - difference)    curSide = 0;    
        else if(zVal > xVal + difference && zVal > yVal + difference)    curSide = 1;  
        else if(zVal < xVal - difference && zVal < yVal - difference)    curSide = 2;
        else if(yVal < xVal - difference && yVal < zVal - difference)    curSide = 3;
        break;
     case 5:
        if(xVal > yVal + difference && xVal > zVal + difference)    curSide = 5;
        else if(xVal < yVal - difference && xVal < zVal - difference)    curSide = 0;    
        else if(zVal > xVal + difference && zVal > yVal + difference)    curSide = 1;  
        else if(zVal < xVal - difference && zVal < yVal - difference)    curSide = 2;
        else if(yVal < xVal - difference && yVal < zVal - difference)    curSide = 3;
        else if(yVal > xVal + difference && yVal > zVal + difference)    curSide = 4;
        break;
     default:
        if(xVal < yVal - difference && xVal < zVal - difference)    curSide = 0;    
        else if(zVal > xVal + difference && zVal > yVal + difference)    curSide = 1;  
        else if(zVal < xVal - difference && zVal < yVal - difference)    curSide = 2;
        else if(yVal < xVal - difference && yVal < zVal - difference)    curSide = 3;
        else if(yVal > xVal + difference && yVal > zVal + difference)    curSide = 4;
        else if(xVal > yVal + difference && xVal > zVal + difference)    curSide = 5;
        break; 
   }
}

/* Detect side from reading
______________________________________________________________________*/

void calculateSide()
{
   // if not a new side
   if(formerSide == curSide)
   {            
      if(millis() - previousMillis > enableSec)
      {
         if(!enabled)
         {
            curSideChecked = curSide;
           
            enable();
         }
       } 
   }
   
   // if new side
   else
   {
      if(enabled)
      {
        disable();
      }
      
      previousMillis = millis();
      formerSide = curSide; 
   } 
}

/* Read gyro and detect angle
______________________________________________________________________*/

void readGyro()
{
    if(enabled)
    {
      receiveData();         
  
      switch(curSideChecked)
      {
         case 0:
         case 5:
            gyroReading = yaw;
            break;
         case 1:
         case 2:
            gyroReading = roll;
            break;
         case 3:
         case 4:
            gyroReading = pitch;
            break;
       }
    }
    else
    {
      gyroReading = 0; 
    }
}

/* Check message
______________________________________________________________________*/

void checkMessage()
{ 
  if(XBee.available() > 1) 
  {
    int firstByte = XBee.read();
    
    if(firstByte == identifier) 
    {
      int secondByte = XBee.read();
      
      if(secondByte == xbeeNumber) 
      {       
        if(xbeeNumber == 2)
        { 
           readAccelerometer();
   
           calculateSide();
     
           readGyro();
        }
   
         sendMessage();
      }
    }
  }
}

/* Send message
______________________________________________________________________*/

void sendMessage()
{ 
   previousMessage = millis();
   
   // Send identifier
   XBee.print(identifier);
   XBee.print(",");  
   
   // Send to computer
   XBee.print(computerNumber, DEC);
   XBee.print(",");
   
   // our number
   XBee.print(xbeeNumber, DEC);
   XBee.print(",");
   
   // send side   
   if(!enabled)  XBee.print(-1);
   else          XBee.print(curSideChecked);
   XBee.print(",");
   
   // send gyro reading
   XBee.println(gyroReading); 
}

/* Activate Wii Motion +
______________________________________________________________________*/

void enableWii()
{
   Wire.beginTransmission(0x53);    //WM+ starts out deactivated at address 0x53
   Wire.send(0xfe);                 //send 0x04 to address 0xFE to activate WM+
   Wire.send(0x04);
   Wire.endTransmission();          //WM+ jumps to address 0x52 and is now active
}

/* Calibrate Wii
______________________________________________________________________*/

void calibrateWii()
{
  for (int i=0; i < 10; i++)
  {
    sendZeroWii();
    
    Wire.requestFrom(0x52,6);
    
    for (int i=0;i<6;i++)
    {
      data[i] = Wire.receive();
    }
    
    yaw0   += (((data[3]>>2)<<8)+data[0]) / 10;        //average 10 readings for each zero
    pitch0 += (((data[4]>>2)<<8)+data[1]) / 10;
    roll0  += (((data[5]>>2)<<8)+data[2]) / 10;
  }
}

/* Get data from Wii
______________________________________________________________________*/

void receiveData()
{
  sendZeroWii();                   //send zero before each request (same as nunchuck)
  Wire.requestFrom(0x52,6);        //request the six bytes from the WM+
  
  for(int i=0; i<6; i++)
  {
    data[i] = Wire.receive();
  }
  
  yaw   = ((data[3]>>2)<<8) + data[0] - yaw0;        //see http://wiibrew.org/wiki/Wiimote/Extension_Controllers#Wii_Motion_Plus
  pitch = ((data[4]>>2)<<8) + data[1] - pitch0;    //for info on what each byte represents
  roll  = ((data[5]>>2)<<8) + data[2] - roll0;      
}

/* Send 0 to communicate with wii
______________________________________________________________________*/

void sendZeroWii()
{
  Wire.beginTransmission(0x52);    //now at address 0x52
  Wire.send(0x00);                 //send zero to signal we want info
  Wire.endTransmission();
}

/* Enable / Disable
______________________________________________________________________*/

void enable()
{
   enabled = true;
}

void disable()
{
   enabled = false;
}
