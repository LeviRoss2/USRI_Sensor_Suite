// Code for Young 81000 or Trisonica Anemometer Data logging on TEENSY 4.1
//Kyle Hickman kthickm@okstate.edu
// 2_4_2021

///////// DO NOT EDIT BEYOND THIS POINT ///////////

#define Pixhawk false // true for MavLink message parsing
#define Trisonica true // true if trisonica is the anemometer
#define Y92000 false // true if y92000 is the anemometer

// Standardized libraries for basic operation
#include <mavlink.h>  // Allows for connection with Pixhawk-type autopilot
#include <TimeLib.h>  // Required for datetime conversions
#include <SPI.h>      // Required for all SD card operations of Teensy

// Check what version of Teensy is being used, and grab correpsonding library versions
#ifdef ARDUINO_TEENSY41
#include <Wire.h>  // Teensy 4.X-specific wire library
#include "SdFat-4.1.h"  // Modified SdFat library for Teensy 4.1
#include "sdios.h"      // Extra file for SdFat
#include <Adafruit_ADS1015-4.1.h>  // ADC library for tempAnemerature breakout boards, set for Teensy 4.X Wire library

#define SD_CS_PIN = SS;  // Built-in SD card pin
#define SD_CONFIG SdioConfig(FIFO_SDIO)  // Set configuration type for SD setup
SdFat sd;  // Define SD card variable name
File file;  // Define file variable used to save data into the filename

#else

#include <Adafruit_ADS1015-3.6.h>  // ADC library for tempAnemerature breakout boards, set for Teensy 3.X i2c_t3 library
#include <i2c_t3.h> // I2C library for Teensy 3.X boards
#include "SdFat-3.6.h"  // Based SdFat library for Teensy 3.X boards
#include "sdios.h"  // Extra file for SdFat
SdFatSdio sd;  // Define SD card variable name
SdFile file;  // Define file variable used to save data into the filename
const uint8_t SD_CHIP_SELECT = SS;
#define SD_CS = BUILTIN_SDCARD;

#endif

char filename[12]; // make it long enough to hold your longest file name, plus a null terminator

#if Pixhawk == true
#define HWSERIAL
#endif

// Anemometer
const byte numChars = 450;
char from_Anemo[numChars];
boolean newData = false;
int prevTime = 0;
int loopTime = 0;

float oldPixTime = 0;
uint32_t GPS_stat[1] = {0};
uint32_t PixTime[2] = {0, 0};
elapsedMillis oldTime;

unsigned char i;
unsigned char j;
unsigned char k;
unsigned char s;
unsigned char e;
char tDspeed[6];
char wind_ang[6];
char wind_ele[6];
char SoS[6];
char tempAnem[5];
const int led = 13;

uint16_t Year = 0000;
uint8_t Month = 00;
uint8_t Day = 00;
uint8_t Hour = 00;
uint8_t Minute = 00;
uint8_t Second = 00;


void setup() {
  // put your setup code here, to run once:

  Serial.begin(115200);
#if Pixhawk == true
  Serial1.begin(115200);
#endif
#if Trisonica == true
  Serial2.begin(115200, SERIAL_8N1); // Young 81000 signal will be on rx pin 7 (for TEENSY 4.1)
  pinMode(led, OUTPUT);
#endif
#if Y92000 == true 
  Serial2.begin(38400, SERIAL_8N1); // Young 81000 signal will be on rx pin 7 (for TEENSY 4.1)
  pinMode(led, OUTPUT);
#endif

  // Initialize at the highest speed supported by the board that is
  // not over 50 MHz. Try a lower speed if SPI errors occur.

#ifdef ARDUINO_TEENSY41
  if (!sd.begin(SdioConfig(FIFO_SDIO))) {
    // don't do anything more:
    while (1) {
      digitalWrite(led, !digitalRead(led));
      Serial.println("Teensy 4.1 SD fail. Reset card and try again.");
      delay(2000);
    }
  }
#else
  if (!sd.begin()) {
    // don't do anything more:
    while (1) {
      Serial.println("Teensy 3.6 SD fail. Reset card and try again.");
      digitalWrite(led, !digitalRead(led));
      delay(2000);
    }
  }
#endif

#if Pixhawk == true
  oldTime = 0;
  while (GPS_stat[0] < 3) {
    Serial.println("Waiting for GPS lock");
    GPS_receive();
    if (oldTime >= 1000) {
      digitalWrite(led, !digitalRead(led));
      oldTime = oldTime - 1000;
    }
  }

  oldTime = 0;
  while (PixTime[0] < 5) {
    Serial.println("Waiting for time sync");
    MavLink_receive();
    if (oldTime >= 500) {
      digitalWrite(led, !digitalRead(led));
      oldTime = oldTime - 500;
    }

    delay(10);
  }
  delay(2000);
  MavLink_receive();
#endif
  int n = 0;
  snprintf(filename, sizeof(filename), "WTUN%03d.csv", n); // includes a three-digit sequence number in the file name
  while (sd.exists(filename)) {
    n++;
    snprintf(filename, sizeof(filename), "WTUN%03d.csv", n);
  }
  if (Serial) {
    Serial.println(n);
    Serial.println(filename);
  }
  Year = 2001;
  Month = 01;
  Day = 01;
  Hour = 01;
  Minute = 01;
  Second = 01;

  // set creation date time
  //  if (!file.timestamp(T_CREATE, Year, Month, Day, Hour, Minute, Second)) {
  //    if (Serial) {
  //      Serial.println("Error creating timestamp");
  //    }
  //    while (1) {
  //      digitalWrite(led, !digitalRead(led));
  //      delay(2000);
  //    }
  //  }
  //  // set write/modification date time
  //  if (!file.timestamp(T_WRITE, Year, Month, Day, Hour, Minute, Second)) {
  //    if (Serial) {
  //      Serial.println("Error writing timestamp");
  //    }
  //    while (1) {
  //      digitalWrite(led, !digitalRead(led));
  //      delay(2000);
  //    }
  //  }
  //  // set access date
  //  if (!file.timestamp(T_ACCESS, Year, Month, Day, Hour, Minute, Second)) {
  //    if (Serial) {
  //      Serial.println("Error setting access timestamp");
  //    }
  //    while (1) {
  //      digitalWrite(led, !digitalRead(led));
  //      delay(2000);
  //    }
  //  }
  if (Serial) {
    Serial.println("File written successfully");
  }

  file.close();

  delay(50);

  file.open(filename, FILE_WRITE);
  file.println("Board Time (ms), Anemometer Data, Unix Time (sec), Pix Boot Time (ms)");
  file.close();

  delay(1000);
}

void loop() {

  file.open(filename, FILE_WRITE);
  digitalWrite(led, !digitalRead(led));
  loopTime = millis();
  file.print(loopTime + String(','));


  if ((loopTime - prevTime) > 1000) {
    digitalWrite(led, !digitalRead(led));
    Serial.println(loopTime);
    prevTime = loopTime;
  }
  static boolean recvInProgress = false;
  static byte index = 0;
  char startMarker = (char)83;
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

//    for (int i = 0; i < sizeof(from_Anemo) - 1; i++)
//    {
//      if (i == 0)
//      { 
//        for ( int j=0; j<sizeof(tDspeed); j++){
//        tDspeed[j] = from_Anemo[j+i];
//        }
//      }
//      if (i == 8){
//        for ( int j=0; j<sizeof(wind_ang); j++){
//        wind_ang[j] = from_Anemo[j+i];
//        }     
//      }
//      if (i == 13){
//        for ( int j=0; j<sizeof(wind_ele); j++){
//        wind_ele[j] = from_Anemo[j+i];
//        }
//      }
//      if (i == 19){
//        for ( int j=0; j<sizeof(SoS); j++){
//        SoS[j] = from_Anemo[j+i];
//        }
//      }
//      if (i == 26){
//        for ( int j=0; j<sizeof(tempAnem)-1; j++){
//        tempAnem[j] = from_Anemo[j+i];
//        if (j == sizeof(tempAnem)){
//          tempAnem[j] = '\0';
//          break;
//        }
//        }
//      }
//
//    Serial.print(String(" | "));
//    Serial.print(String("Wind Speed: ") + tDspeed + String(" | "));
//    Serial.print(String("Angle: ") + wind_ang + String(" | "));
//    Serial.print(String("elevation:  ") + wind_ele + String(" | "));
//    Serial.print(String("Speed of Sound: ") + SoS + String(" | "));
//    Serial.println(String("tempAnemerature: " ) + tempAnem + String(" | "));

    file.print(from_Anemo + String(','));
    }
  else {
    file.print(String(' ') + String(','));
  }

#if Pixhawk == true
  MavLink_receive();

  if (PixTime[1] > oldPixTime) {
    file.print(PixTime[0]);
    file.print(',');
    file.print(PixTime[1]);
    file.print(',');
    oldPixTime = PixTime[1];
  }
  else {
    file.print((String)' ' + ',' + ' ' + ',');
  }

#else
  file.print((String)' ' + ',' + ' ' + ',');
#endif

  file.println();
  file.close();

}

//function called by arduino to read any MAVlink messages sent by serial communication from flight controller to arduino
uint32_t* GPS_receive()
{
  mavlink_message_t msg;
  mavlink_status_t status;

  while (Serial1.available())
  {
    uint8_t c = Serial1.read();

    //Get new message
    if (mavlink_parse_char(MAVLINK_COMM_0, c, &msg, &status))
    {

      //Handle new message from autopilot
      switch (msg.msgid)
      {

        case MAVLINK_MSG_ID_GPS_RAW_INT:  // #27: RAW_IMU
          {
            /* Message decoding: PRIMITIVE
                  static inline void mavlink_msg_raw_imu_decode(const mavlink_message_t* msg, mavlink_raw_imu_t* raw_imu)
            */
            mavlink_gps_raw_int_t gps_raw_int;
            mavlink_msg_gps_raw_int_decode(&msg, &gps_raw_int);

            GPS_stat[0] = gps_raw_int.fix_type;

            return GPS_stat;


          }
          break;
      }
    }
  }
}

//function called by arduino to read any MAVlink messages sent by serial communication from flight controller to arduino
uint32_t* MavLink_receive()
{
  mavlink_message_t msg;
  mavlink_status_t status;

  while (Serial1.available())
  {
    uint8_t c = Serial1.read();

    //Get new message
    if (mavlink_parse_char(MAVLINK_COMM_0, c, &msg, &status))
    {

      //Handle new message from autopilot
      switch (msg.msgid)
      {

        case MAVLINK_MSG_ID_SYSTEM_TIME:  // #27: RAW_IMU
          {
            /* Message decoding: PRIMITIVE
                  static inline void mavlink_msg_raw_imu_decode(const mavlink_message_t* msg, mavlink_raw_imu_t* raw_imu)
            */
            mavlink_system_time_t system_time;
            mavlink_msg_system_time_decode(&msg, &system_time);

            uint64_t Ptime = system_time.time_unix_usec;
            PixTime[0] = Ptime / 1000000;
            PixTime[1] = system_time.time_boot_ms;

            return PixTime;


          }
          break;
      }
    }
  }
}
