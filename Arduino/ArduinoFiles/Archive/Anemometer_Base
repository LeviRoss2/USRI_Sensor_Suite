// Code for Young 81000 Anemometer Data logging on TEENSY 4.1
//Kyle Hickman kthickm@okstate.edu
// 2_4_2021


//#include "SdFat.h"
//#include <i2c_t3.h>
//#include <SPI.h>
//#include <mavlink.h>
//#include <Adafruit_ADS1015.h>
//#include <TimeLib.h>

#define DEBUGGING_ENABLED

char filename[12]; // make it long enough to hold your longest file name, plus a null terminator

// Anemometer 
const byte numChars = 35;
char from_Anemo[numChars];
boolean newData = false;
int prevTime = 0;
int loopTime = 0;

unsigned char i;
unsigned char j;
unsigned char k;
unsigned char s;
unsigned char e;
char tDspeed[7];
char wind_ang[6];
char wind_ele[6];
char SoS[7];
char temp[8];
const int led = 13;


void setup() {
  // put your setup code here, to run once:
  
Serial.begin(115200); 
Serial2.begin(38400, SERIAL_8N1); // Young 81000 signal will be on rx pin 7 (for TEENSY 4.1)
pinMode(led,OUTPUT);
}

void loop() {
{ loopTime = millis();
    if((loopTime - prevTime) >1000){
    digitalWrite(led,!digitalRead(led));
    prevTime = loopTime;
}
  static boolean recvInProgress = false;
  static byte index = 0;
  char startMarker = (char)13;
  char endMarker = (char)13;
  newData = false;
  char rc;

  while (Serial2.available() > 0 && newData == false)
  {
    rc = Serial2.read();
    if (recvInProgress == true)
    {
      if (rc != endMarker && rc != '\0')
      {
        from_Anemo[index] = rc;
        index++;
        if (index >= numChars)
        {
          index = numChars - 1;
        }
      }
      else if (rc == endMarker)
      {
        if(index<numChars)
        {
          for (i=index; i<numChars; i++){
            from_Anemo[i] = (char)0;
          }
          index = i;
        }
        from_Anemo[index] = '\0'; // terminate the string
        recvInProgress = false;
        
        index = 0;
        newData = true;
      }
    }
    else if (rc == startMarker)
    {
      recvInProgress = true;
    }
  }

  if (newData == true)
  {
    i = 0;
    j = 0;
    s = 0;
    k = 0;
    e = 0;
    newData = false;

    Serial.print("from_Anemo: ");
    Serial.println(from_Anemo);

    for (int i = 0; i < sizeof(from_Anemo) - 1; i++)
    {
      if (i == 0)
      { 
        for ( int j=0; j<sizeof(tDspeed); j++){
        tDspeed[j] = from_Anemo[j+i];
        }
      }
      if (i == 8){
        for ( int j=0; j<sizeof(wind_ang); j++){
        wind_ang[j] = from_Anemo[j+i];
        }     
      }
      if (i == 13){
        for ( int j=0; j<sizeof(wind_ele); j++){
        wind_ele[j] = from_Anemo[j+i];
        }
      }
      if (i == 19){
        for ( int j=0; j<sizeof(SoS); j++){
        SoS[j] = from_Anemo[j+i];
        }
      }
      if (i == 26){
        for ( int j=0; j<sizeof(temp); j++){
        temp[j] = from_Anemo[j+i];
        if (j == sizeof(temp)){
          temp[j] = '\0';
        }
        }
      }

    Serial.print(String(" | "));
    Serial.print(String("Wind Speed: ") + tDspeed + String(" | "));
    Serial.print(String("Angle: ") + wind_ang + String(" | "));
    Serial.print(String("elevation:  ") + wind_ele + String(" | "));
    Serial.print(String("Speed of Sound: ") + SoS + String(" | "));
    Serial.println(String("temperature: " ) + temp + String(" | "));
  }
}}  
