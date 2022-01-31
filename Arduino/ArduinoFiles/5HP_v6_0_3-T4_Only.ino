/* USRI Sensor Suite Package
   Unmanned Systems Research Institute at Oklahoma State University

   Created by: Levi Ross    | levi.ross@okstate.edu
               Kyle Hickman | kthickm@okstate.edu (initial anemometer data)

   Last edit:  10/27/2021

   Code for Teensy 4.1 that logs triply redundant temperature, barometric pressure,
      and humidity data alongside 3 differential pressure transducers that function
      as a 5-Hole Probe over I2C connections. Support exists for anemometer data
      readings over serial com port connection.

   All libraries needed to operate code and process data can be found on the GitHub:
   https://github.com/LeviRoss2/USRI_Sensor_Suite
 * *
*/

/////////// SET VALUES HERE ////////////////////////

#define Pixhawk false      // true for MavLink message parsing
#define TPH true          // true for Temp and Humidity calcs
#define MHP true          // true for 5HP data collection
#define USB false         // true for full serial output, false for no serial output (Serial.print(), etc.)
#define ARM_CHK false      // Disable/enable arming check before logging starts
#define YoungAnem false   // Disable/enable Young 81000 Anemometer data logging

int FHP_freq = 200;       // Hz | MAX: 200, MIN: 2 | Five Hole Probe refresh rate
int SS_freq = 2;          // Hz | MAX: 20, MIN: 2 | Sensor Suite refresh rate
#define btnState 12       // Digital pin to read button state (enter MTP on startup)
#define btnLED 11         // LED visualzing btn state

#define USE_SD  1         // SDFAT based SDIO and SPI

#define addressMHP 0x38   // I2C address of 5HP differential transducers

///////// DO NOT EDIT BEYOND THIS POINT ///////////

#include "SdFat.h"    // Faster data write library
#include "SD.h"       // Access to SD card data (read/write, USB file transfer)
#include "sdios.h"    // Extra file for SdFat
#include "MTP.h"      // Protocol that allows for USB file transfer
#include <mavlink.h>  // Allows for connection with Pixhawk-type autopilots
#include <TimeLib.h>  // Required for datetime conversions
#include <Wire.h>     // Updated for Teensy 3.X and 4.X support
#include <SPI.h>      // Required for SD card functions
#include <Adafruit_ADS1015-4.1.h>  // ADC library for temperature breakout boards, set for Teensy 4.1 Wire library

// SENSOR SD CARD SETUP (SDFAT)
#define SD_CS_PIN = SS;  // Built-in SD card pin
#define SD_CONFIG SdioConfig(FIFO_SDIO)  // Set configuration type for SD setup
SdFat sd;  // Define SD card variable name
FsFile file;  // Define file variable used to save data into the filename
char filename[12]; // Stores the name of the resulting log file
// END SENSOR SD CARD SETUP

// ANEMOMETER SETUP
char tDspeed[7];
char wind_ang[6];
char wind_ele[6];
char SoS[7];
char tempAnem[8];
// END ANEMOMETER SETUP

// SENSOR SUITE SETUP
int Time = millis();  // Initialize internal timer

// If Pixhawk data is requested, enable hardware serial
#if Pixhawk == true
#define HWSERIAL
#endif

#define led LED_BUILTIN       // Configure built-in LED to display current status

// Predefine variables
int FHPiter = 0;  // Interval frequency for 5HP measurement logging
int FHPlast = 0;  // Last time interval logged
int SSiter = 0;   // Interval frequency for TPH measurement logging
int SSlast = 0;   // Last time interval logged
int last_tot = 0;  // Last time the 1 second check was run (to verify loop speed)
int SScount = 0;   // Total times the SS data was run in the last second
int FHPcount = 0;  // Total times the 5HP data was run in the last second
float oldPixTime = 0;  // Previous Pixhawk GPS time, only run again if new data exists
uint32_t GPS_stat[1] = {0};  // GPS state (3D lock, 2D, none, etc.)
uint32_t PixTime[2] = {0, 0};  // Pixhawk system time (us) and time since boot (ms)
elapsedMillis oldTime;  // Timer for LED blink
#define telemSerial Serial1
#define pixSerial Serial2
#define youngSerial Serial3


//constants for digital ports feeding the temperature sensors
#define PIN_SENSOR_TEMP1 23
#define PIN_SENSOR_TEMP2 33
#define PIN_SENSOR_TEMP3 35
#define PIN_SENSOR_TEMP4 45

//prototypes
void readBead(int, double*, double*); //reads the voltage from the ADC and converts it to temperature
bool readSensor(int, int, double, double); // reads a humidity sensor

//variables for the temperature sensors
double temp;
double volt;
double coeff[3][3];

//Initialize ADS1115 with their corresponding addresses
Adafruit_ADS1115 adc1(0x49);
Adafruit_ADS1115 adc2(0x4A);
Adafruit_ADS1115 adc3(0x4B);

//variables for the humidity sensors
int address[3] = {0x30, 0x31, 0x32};
double humidity[3] = { -1, -1, -1};
double temperature[3] = {0, 0, 0};
int i; //loop index
bool result;
bool armed = false;

// Temp and Humidity variable initialization for thermistors
double alpha = 0.5;  // Low Pass Filter
double temperature_bead[3] = { 0, 0, 0};
double temperature_ant[3] = { 0, 0, 0};
double humidity_ant[3] = { 0, 0, 0};

// 5HP variable initialization
int AS1 = 0;
int AS2 = 0;
int AS3 = 0;

// Initialize date variables (used to store write time in UTC)
uint16_t Year = 0000;
uint8_t Month = 00;
uint8_t Day = 00;
uint8_t Hour = 00;
uint8_t Minute = 00;
uint8_t Second = 00;
// END SENSOR SUITE SETUP

// MTP PROTOCOL SETUP (SD)
bool USB_STATE = false;

#if USE_EVENTS==1
extern "C" int usb_init_events(void);
#else
int usb_init_events(void) {}
#endif

#if defined(__IMXRT1062__)
// following only as long usb_mtp is not included in cores
#if !__has_include("usb_mtp.h")
#include "usb1_mtp.h"
#endif
#else
#ifndef BUILTIN_SDCARD
#define BUILTIN_SDCARD 254
#endif
void usb_mtp_configure(void) {}
#endif

// edit SPI to reflect your configuration (following is for T4.1)
#define SD_MOSI 11
#define SD_MISO 12
#define SD_SCK  13

#define SPI_SPEED SD_SCK_MHZ(33)  // adjust to sd card 

#if defined (BUILTIN_SDCARD)
const char *sd_str[] = {"sdio", "sd1"}; // edit to reflect your configuration
const int cs[] = {BUILTIN_SDCARD, 10}; // edit to reflect your configuration
#else
const char *sd_str[] = {"sd1"}; // edit to reflect your configuration
const int cs[] = {10}; // edit to reflect your configuration
#endif
const int nsd = sizeof(sd_str) / sizeof(const char *);

SDClass sdx[nsd];

MTPStorage_SD storage;
MTPD    mtpd(&storage);
// END MTP SETUP

void storage_configure()
{
#if USE_SD==1
#if defined SD_SCK
  SPI.setMOSI(SD_MOSI);
  SPI.setMISO(SD_MISO);
  SPI.setSCK(SD_SCK);
#endif

  for (int ii = 0; ii < nsd; ii++)
  {
#if defined(BUILTIN_SDCARD)
    if (cs[ii] == BUILTIN_SDCARD)
    {
      if (!sdx[ii].sdfs.begin(SdioConfig(FIFO_SDIO)))
      { Serial.printf("SDIO Storage %d %d %s failed or missing", ii, cs[ii], sd_str[ii]);  Serial.println();
      }
      else
      {
        storage.addFilesystem(sdx[ii], sd_str[ii]);
        uint64_t totalSize = sdx[ii].totalSize();
        uint64_t usedSize  = sdx[ii].usedSize();
        Serial.printf("SDIO Storage %d %d %s ", ii, cs[ii], sd_str[ii]);
        Serial.print(totalSize); Serial.print(" "); Serial.println(usedSize);
      }
    }
    else if (cs[ii] < BUILTIN_SDCARD)
#endif
    {
      pinMode(cs[ii], OUTPUT); digitalWriteFast(cs[ii], HIGH);
      if (!sdx[ii].sdfs.begin(SdSpiConfig(cs[ii], SHARED_SPI, SPI_SPEED)))
      { Serial.printf("SD Storage %d %d %s failed or missing", ii, cs[ii], sd_str[ii]);  Serial.println();
      }
      else
      {
        storage.addFilesystem(sdx[ii], sd_str[ii]);
        uint64_t totalSize = sdx[ii].totalSize();
        uint64_t usedSize  = sdx[ii].usedSize();
        Serial.printf("SD Storage %d %d %s ", ii, cs[ii], sd_str[ii]);
        Serial.print(totalSize); Serial.print(" "); Serial.println(usedSize);
      }
    }
  }
#endif

}

//------------------------------------------------------------------------------
void setup(void) {

  Serial.begin(115200);
  telemSerial.begin(57600);
  pinMode(btnState,INPUT);
  pinMode(btnLED, OUTPUT);

  for(int i=0;i<2000;i++){
    if((i%100)==0){
      digitalWrite(btnLED,HIGH);
    }else{
      digitalWrite(btnLED,LOW);
    }
    delay(3);
  }

  if (digitalRead(btnState)==HIGH) {
    digitalWrite(btnLED,HIGH);
    USB_STATE = true;
    Serial.println("Entering MTP protocol for file transfer.");
    Serial.println("No data will be processed or recorded until after reboot and disconnect from PC.");
    telemSerial.println("Entering MTP mode, no sensor data will be available until reboot.");

#if USE_EVENTS==1
    usb_init_events();
#endif

#if !__has_include("usb_mtp.h")
    usb_mtp_configure();
#endif
    storage_configure();
  } else {
    telemSerial.println("Enter normal data logging mode...");
    digitalWrite(btnLED,LOW);
    USB_STATE = false;

#if Pixhawk == true
bool pixCheck 
    pixSerial.begin(115200);
    telemSerial.println("Pixhawk data requested.");
#endif

#if YoungAnem == true
    youngSerial.begin(38400, SERIAL_8N1); // Young 81000 signal will be on rx pin 7 (for TEENSY 4.1)
    telemSerial.println("Young anemometer data requested.");
#endif

    delay(1000);

    pinMode(led, OUTPUT); //LED for reference
    Wire.begin(); //i2c bus 1
    Wire1.begin(); //i2c bus 2
    Wire2.begin(); //i2c bus 3

    //instance of an temp_sensor
    adc1.begin();
    adc2.begin();
    adc3.begin();

    //digital pins feeding the sensors
    pinMode(PIN_SENSOR_TEMP1, OUTPUT);
    pinMode(PIN_SENSOR_TEMP2, OUTPUT);
    pinMode(PIN_SENSOR_TEMP3, OUTPUT);
    pinMode(PIN_SENSOR_TEMP4, OUTPUT);
    digitalWrite(PIN_SENSOR_TEMP1, HIGH);
    digitalWrite(PIN_SENSOR_TEMP2, HIGH);
    digitalWrite(PIN_SENSOR_TEMP3, HIGH);
    digitalWrite(PIN_SENSOR_TEMP4, HIGH);

    //48623
    coeff[0][0] = 1.00733068 * pow(10, -3);
    coeff[0][1] = 2.62299300 * pow(10, -4);
    coeff[0][2] = 1.48361439 * pow(10, -7);

    //48627
    coeff[1][0] = 1.00097308 * pow(10, -3);
    coeff[1][1] = 2.62806129 * pow(10, -4);
    coeff[1][2] = 1.46350112 * pow(10, -7);

    //48628
    coeff[2][0] = 9.89775772 * pow(10, -4);
    coeff[2][1] = 2.64144606 * pow(10, -4);
    coeff[2][2] = 1.42274703 * pow(10, -7);

    if (FHP_freq < 2) {
      FHP_freq = 2;
    }
    if (FHP_freq > 200) {
      FHP_freq = 200;
    }
    FHPiter = 1000 / FHP_freq;
    if (SS_freq > 20) {
      SS_freq = 20;
    }
    if (SS_freq < 2) {
      SS_freq = 2;
    }
    SSiter = 1000 / SS_freq;

    // Initialize at the highest speed supported by the board that is
    // not over 50 MHz. Try a lower speed if SPI errors occur.
    if (!sd.begin(SdioConfig(FIFO_SDIO))) {
      // don't do anything more:
      while (1) {
        digitalWrite(led, !digitalRead(led));
        Serial.println("Teensy 4.1 SD fail. Reset card and try again.");
        delay(2000);
      }
    }

    telemSerial.println("SD card initialized.");

#if Pixhawk == true
    if (USB == false) {
      oldTime = 0;
      bool msgSend = false;
      while (GPS_stat[0] < 3) {
        if(msgSend == false){
          telemSerial.println("Waiting for valid GPS signal...");
          msgSend = true;
        }
        GPS_receive();
        if (oldTime >= 1000) {
          digitalWrite(led, !digitalRead(led));
          oldTime = oldTime - 1000;
        }
      }

      oldTime = 0;
      bool msgSend = false;
      while (PixTime[0] < 5) {
        MavLink_receive();
        if(msgSend == false){
          telemSerial.println("Waiting for GPS 3D position lock...");
          msgSend = true;
        }
        if (oldTime >= 500) {
          digitalWrite(led, !digitalRead(led));
          oldTime = oldTime - 500;
        }

        delay(10);
      }
    }
#endif

#if Pixhawk == true
    int n = 0;
    snprintf(filename, sizeof(filename), "HERA%03d.csv", n); // includes a three-digit sequence number in the file name
    while (sd.exists(filename)) {
      n++;
      snprintf(filename, sizeof(filename), "HERA%03d.csv", n);
    }
    if (Serial) {
      Serial.println(n);
      Serial.println(filename);
    }

    if (USB == false) {
      Year = year(PixTime[0]);
      Month = month(PixTime[0]);
      Day = day(PixTime[0]);
      Hour = hour(PixTime[0]);
      Minute = minute(PixTime[0]);
      Second = second(PixTime[0]);
    }

    if (USB == true) {
      Year = 2001;
      Month = 01;
      Day = 01;
      Hour = 01;
      Minute = 01;
      Second = 01;
    }
#else
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

#endif

    // create a new file with default timestamps
    if (!file.open(filename, O_WRONLY | O_CREAT)) {
      if (Serial) {
        Serial.println("Error Opening file");
      }
      while (1) {
        digitalWrite(led, !digitalRead(led));
        delay(2000);
      }
    }
    // set creation date time
    if (!file.timestamp(T_CREATE, Year, Month, Day, Hour, Minute, Second)) {
      if (Serial) {
        Serial.println("Error creating timestamp");
      }
      while (1) {
        digitalWrite(led, !digitalRead(led));
        delay(2000);
      }
    }
    // set write/modification date time
    if (!file.timestamp(T_WRITE, Year, Month, Day, Hour, Minute, Second)) {
      if (Serial) {
        Serial.println("Error writing timestamp");
      }
      while (1) {
        digitalWrite(led, !digitalRead(led));
        delay(2000);
      }
    }
    // set access date
    if (!file.timestamp(T_ACCESS, Year, Month, Day, Hour, Minute, Second)) {
      if (Serial) {
        Serial.println("Error setting access timestamp");
      }
      while (1) {
        digitalWrite(led, !digitalRead(led));
        delay(2000);
      }
    }
    if (Serial) {
      Serial.println("File written successfully");
    }

    file.close();

    delay(50);

    #if MHP == true

    file.open(filename, FILE_WRITE);
    file.println("SS Time(ms), AS1-B1, AS1-B2, AS1-B3, AS1-B4, AS2-B1, AS2-B2, AS2-B3, AS2-B4, AS3-B1, AS3-B2, AS3-B3, AS3-B4, Humid1(%), HTemp1(C), Temp1(C), Volt1(mV), Humid2(%), HTemp2(C), Temp2(C), Volt2(mV), Humid3(%), HTemp3(C), Temp3(C), Volt3(mV), Unix Time (sec), Pix Boot Time (ms)");
    file.close();

    #else

    //Whatever header for Anemometer code
    // New #else if for each header type

    #endif

    telemSerial.println("File setup complete.");

    delay(1000);

    last_tot = 0;

#if Pixhawk == true
    if (ARM_CHK == true) {
      if (USB == false) {
        bool msgSend = false;
        oldTime = 0;
        while (armed < 1) {
          Arming_Check();
          if(msgSend == false){
            telemSerial.println("Waiting for aircraft to arm...");
            msgSend = true;
          }
          if (oldTime >= 250) {
            digitalWrite(led, !digitalRead(led));
            oldTime = oldTime - 250;
          }
        }
        telemSerial.println("Aircraft armed, system ready!");
      }
    }
#endif
  }

  Serial.println((String)"STATE: " + USB_STATE);
  telemSerial.println("Starting main loop!");
}

void loop() {

  if (USB_STATE == false) {
    file.open(filename, FILE_WRITE);
    digitalWrite(led, !digitalRead(led));
    Time = millis();

    telemSerial.print(Time + String(','));
    file.print(Time + String(','));
#if USB == true
    Serial.println(String("Time: ") + Time);
#endif

#if MHP == true
    if ((Time - FHPlast) >= FHPiter) {
      FHPlast = Time;
      FHPcount++;
      mhpCheck();
    }
    else {
      telemSerial.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
      file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
    }
#else
    telemSerial.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
    file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
#endif

#if TPH == true
    if ((Time - SSlast) >= SSiter) {
      SSlast = Time;
      SScount++;
      tphCheck();
    } else {
      telemSerial.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
      file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
    }

#else
    telemSerial.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
    file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
#endif

#if Pixhawk == true
    MavLink_receive();

    if (PixTime[1] > oldPixTime) {
      telemSerial.print(PixTime[0]);
      telemSerial.print(',');
      telemSerial.print(PixTime[1]);
      telemSerial.print(',');
      file.print(PixTime[0]);
      file.print(',');
      file.print(PixTime[1]);
      file.print(',');
      oldPixTime = PixTime[1];
    }
    else {
      telemSerial.print((String)' ' + ',' + ' ' + ',');
      file.print((String)' ' + ',' + ' ' + ',');
    }
#else
    telemSerial.print((String)' ' + ',' + ' ' + ',');
    file.print((String)' ' + ',' + ' ' + ',');
#endif

    telemSerial.println();
    file.println();
    file.close();

    //#if USB == true
    if ((Time - last_tot) >= 1000) {
      Serial.println(); Serial.print("SS count: "); Serial.println(SScount); Serial.print("FHP count: "); Serial.println(FHPcount);
      Serial.println();
      last_tot = Time;
      SScount = 0;
      FHPcount = 0;
    }
    //#endif

  } else {
    mtpd.loop();

#if USE_EVENTS==1
    if (Serial.available())
    {
      char ch = Serial.read();
      Serial.println(ch);
      if (ch == 'r')
      {
        Serial.println("Reset");
        mtpd.send_DeviceResetEvent();
      }
    }
    if (oldTime >= 1000) {
      digitalWrite(led, !digitalRead(led));
      oldTime = 0;
    }
#endif
  }
}

void mhpCheck() {

#if USB == true
  Serial.println();
#endif

  Wire.requestFrom(addressMHP, 4);   // request 4 bytes from slave device #8
  while (Wire.available()) { // slave may send less than requested
    AS1 = Wire.read();   // receive a byte as int
    file.print(AS1 + String(','));
#if USB == true
    Serial.print(AS1 + String(','));
#endif
  }

  Wire1.requestFrom(addressMHP, 4);   // request 4 bytes from slave device 0x38
  while (Wire1.available()) { // slave may send less than requested
    AS2 = Wire1.read();   // receive a byte as int
    file.print(AS2 + String(','));
#if USB == true
    Serial.print(AS2 + String(','));
#endif
  }

  Wire2.requestFrom(addressMHP, 4);   // request 4 bytes from slave device 0x38
  while (Wire2.available()) { // slave may send less than requested
    AS3 = Wire2.read();   // receive a byte as int
    file.print(AS3 + String(','));
#if USB == true
    Serial.print(AS3 + String(','));
#endif
  }
}

void YoungAnemometer() {
  static boolean recvInProgress = false;
  static byte index = 0;
  char startMarker = (char)13;
  char endMarker = (char)13;
  boolean newData = false;
  char rc;
  const byte numChars = 35;
  char from_Anemo[numChars];

  while (youngSerial.available() > 0 && newData == false)
  {
    rc = youngSerial.read();
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
        if (index < numChars)
        {
          for (i = index; i < numChars; i++) {
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
    unsigned char i = 0;
    unsigned char j = 0;
    unsigned char k = 0;
    unsigned char s = 0;
    unsigned char e = 0;

    newData = false;

#if USB == true
    Serial.print("from_Anemo: ");
    Serial.println(from_Anemo);
#endif

    for (int i = 0; i < sizeof(from_Anemo) - 1; i++)
    {
      if (i == 0)
      {
        for ( int j = 0; j < sizeof(tDspeed); j++) {
          tDspeed[j] = from_Anemo[j + i];
        }
      }
      if (i == 8) {
        for ( int j = 0; j < sizeof(wind_ang); j++) {
          wind_ang[j] = from_Anemo[j + i];
        }
      }
      if (i == 13) {
        for ( int j = 0; j < sizeof(wind_ele); j++) {
          wind_ele[j] = from_Anemo[j + i];
        }
      }
      if (i == 19) {
        for ( int j = 0; j < sizeof(SoS); j++) {
          SoS[j] = from_Anemo[j + i];
        }
      }
      if (i == 26) {
        for ( int j = 0; j < sizeof(tempAnem); j++) {
          tempAnem[j] = from_Anemo[j + i];
          if (j == sizeof(tempAnem)) {
            tempAnem[j] = '\0';
          }
        }
      }
#if USB == true
      Serial.print(String(" | "));
      Serial.print(String("Wind Speed: ") + tDspeed + String(" | "));
      Serial.print(String("Angle: ") + wind_ang + String(" | "));
      Serial.print(String("elevation:  ") + wind_ele + String(" | "));
      Serial.print(String("Speed of Sound: ") + SoS + String(" | "));
      Serial.println(String("temperature: " ) + tempAnem + String(" | "));
#endif
    }
  }
}

void tphCheck() {

#if USB == true
  Serial.println();
#endif

  for (i = 0; i < 3; i++)
  {
    // Read humidity sensor
    result = readSensor(address[i], i, temperature, humidity);
    // Read temperature sensor
    readBead(i, &temp, &volt);
    switch (i) {
      case 0:
        temperature_bead[i] = temp;
        break;
      case 1:
        temperature_bead[i] = temp;
        break;
      case 2:
        temperature_bead[i] = temp;
        break;
      case 3:
        temperature_bead[i] = temp;
        break;
      default:
        ;
    }
    //Fliter with mean average filter
    temperature_bead[i] = (temperature_bead[i] + temperature_ant[i]) / 2;
    temperature_ant[i] = temperature_bead[i];

    //Fliter with mean average filter
    humidity[i] = (humidity[i] + humidity_ant[i]) / 2;
    humidity_ant[i] = humidity[i];

#if USB == true
    Serial.println((String) "TH" + i + ": " + temperature[i] + ", " + "HH" + i + ": " + humidity_ant[i] + ", " + 'T' + i + ": " + temperature_ant[i] +  ", " + 'V' + i + ": " + volt);
#endif

    //#if USB == true
    //      Serial.print((String) temperature[i] + ',' + humidity_ant[i] + ',' + temperature_ant[i] + ',' + volt + ',');
    //#endif
    file.print((String) temperature[i] + ',' + humidity_ant[i] + ',' + temperature_ant[i] + ',' + volt + ',');
  }
#if USB == true
  Serial.println();
#endif

}

//function called by arduino to read any MAVlink messages sent by serial communication from flight controller to arduino
uint32_t* GPS_receive()
{
  mavlink_message_t msg;
  mavlink_status_t status;

  while (pixSerial.available())
  {
    uint8_t c = pixSerial.read();

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
bool Arming_Check()
{
  mavlink_message_t msg;
  mavlink_status_t status;

  while (pixSerial.available())
  {
    uint8_t c = pixSerial.read();

    //Get new message
    if (mavlink_parse_char(MAVLINK_COMM_0, c, &msg, &status))
    {

      //Handle new message from autopilot
      switch (msg.msgid)
      {

        case MAVLINK_MSG_ID_HEARTBEAT:  // #0: Heartbeat
          {

            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);

            armed = ((heartbeat.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) ? true : false);

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

  while (pixSerial.available())
  {
    uint8_t c = pixSerial.read();

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

/***************************************reads a humidity semsor *******************************/
bool readSensor(int addr, int sensor_num, double * temp, double * humi)
{
  int b1, b2, b3, b4; //bytes read from the sensor
  int rawTemperature, rawHumidity; //binary values of temp and humi

  Wire.beginTransmission(addr);   // Begin transmission with given device on I2C bus
  Wire.requestFrom(addr, 4);      // Request 4 bytes

  // Read the bytes if they are available
  // The first two bytes are humidity the last two are temperature
  if (Wire.available() == 4) {
    b1 = Wire.read();
    b2 = Wire.read();
    b3 = Wire.read();
    b4 = Wire.read();

    Wire.endTransmission();           // End transmission and release I2C bus

    // combine humidity bytes and calculate humidity
    rawHumidity = b1 << 8 | b2;
    // compound bitwise to get 14 bit measurement first two bits
    // are status/stall bit (see intro text)
    rawHumidity =  (rawHumidity &= 0x3FFF);
    *(humi + sensor_num) = (100.0 / (pow(2, 14) - 1)) * rawHumidity;

    // combine temperature bytes and calculate temperature
    b4 = (b4 >> 2); // Mask away 2 least significant bits see HYT 221 doc
    rawTemperature = b3 << 6 | b4;
    *(temp + sensor_num) = (165.0 / (pow(2, 14) - 1)) * rawTemperature - 40;

    return true;
  }
  else
  {
    *(temp + sensor_num) = 0;
    *(humi + sensor_num) = 0;
    return false;
  }
}

/******************** reads a temperature sensor *******************************/
void readBead(int sensor, double * temp, double * volt)
{
  double adcval, vref, resist;

  //toggles on and off the sensors
  switch (sensor)
  {
    case 0:
      adcval = adc1.readADC_SingleEnded(0);
      vref = adc1.readADC_SingleEnded(1);
      break;
    case 1:
      adcval = adc2.readADC_SingleEnded(0);
      vref = adc2.readADC_SingleEnded(1);
      break;
    case 2:
      adcval = adc3.readADC_SingleEnded(0);
      vref = adc3.readADC_SingleEnded(1);
      break;
    default:
      ;
  }
  //reads the voltagr and covnerts to temperature

  resist = 64900 * (vref / adcval - 1);
  *volt = adcval * 0.1875; //to store the voltage and send it
  *temp = 1 / (coeff[sensor][0] + coeff[sensor][1] * log(resist) + coeff[sensor][2] * pow(log(resist), 3)); //converts to temperature
  *temp -= 273.15; //covnerts to celsius
  if (*temp < -270) {
    *temp = 0;
  }

}
