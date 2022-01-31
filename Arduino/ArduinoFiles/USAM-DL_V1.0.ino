/* USRI Anemometer Datalogger
   Unmanned Systems Research Institute at Oklahoma State University

   Created by: Levi Ross    | levi.ross@okstate.edu

   Last edit:  12/16/2021

   UltraSonic AneMometer DataLogger - USAM-DL

   Code for Teensy 4.1 that logs data sent from Young and Trisonica-series
      anemometers over UART serial connection to the on-board SD card of
      the Teensy. Intended for post-processing in Matlab.

   For access to the development environment needed to run this code, email Levi Ross
      and he will send a portable Arduino installation (currently 1.8.15) with all libraries
      and configurations set for proper functionality.

*/

/////////// SET VALUES HERE ////////////////////////
#define Pixhawk true      // true for MavLink message parsing
#define USB true         // true for full serial output, false for no serial output (Serial.print(), etc.)
#define ARM_CHK false      // Disable/enable arming check before logging starts
#define Young92 false   // Disable/enable Young 92000 Anemometer data logging
#define Young81 false   // Disable/enable Young 81000 Anemometer data logging
#define TriMini true
bool ENTRY = true;       // Temp flag to boot into MTP, will be button read

///////// DO NOT EDIT BEYOND THIS POINT ///////////

// Frequency change can only slow down log speed, not increase
// Young81, for example, logs at 4 Hz max regardless of value here
#define btnState 12       // Digital pin to read button state (enter MTP on startup)
#define btnLED 11         // LED visualzing btn state
#define led LED_BUILTIN   // Teensy built-in LED

#define telemSerial Serial1  // Serial for telemtry radio feed to ground station
#define pixSerial Serial2    // Serial for Pixhawk MavLink data
#define young81 Serial3      // Serial for Young 81000 data stream
#define young92 Serial4      // Serial for Young 92000 data stream
#define triAnem Serial5      // Serial for Trisnonica Mini with Pipe Mount

///////////////////// LIBRARY CONFIGURATION
#include "SD.h"       // Access to SD card data (read/write, USB file transfer)
#include "MTP.h"      // Protocol that allows for USB file transfer
#include <mavlink.h>  // Allows for connection with Pixhawk-type autopilots
#include <TimeLib.h>  // Required for datetime conversions
#include <Wire.h>     // Updated for Teensy 3.X and 4.X support
#include <SPI.h>      // Required for SD card functions
///////////////////// END LIBRARY CONFIGURATION

///////////////////// SD CARD CONFIG
const uint8_t chipSelect = BUILTIN_SDCARD;  // Choose the Teensy built-in SD card slot
char filename[12];  // initialize the filename used to write to SD files
File file;          // Initialize the variables used to access SD files
///////////////////// END SD CARD CONFIG

///////////////////// YOUNG 81000 SETUP
char wSpeed81[7];
char wAng81[6];
char wEle81[6];
char SoS81[6];
char Temp81[7];
///////////////////// END YOUNG 81000 SETUP

///////////////////// YOUNG 92000 SETUP
char wSpeed92[7];
char wAng92[6];
char wTemp92[6];
char wHumid92[6];
char aPress92[7];
///////////////////// END YOUNG 92000 SETUP

///////////////////// TRISONICA SETUP
char speed3D[6];
char speed2D[6];
char dirHoriz[5];
char dirVert[5];
char uVec[7];
char vVec[7];
char wVec[7];
char temp[6];
char humid[6];
char dewPoint[6];
char xLevel[7];
char yLevel[7];
char zLevel[7];
char pitch[7];
char roll[7];
char magHead[5];
///////////////////// END TRISONICA SETUP

///////////////////// SHARED VARIABLES
int Time = millis();  // Initialize internal timer
///////////////////// END SHARED VARIABLES

///////////////////// PIXHAWK SETUP
float oldPixTime = 0;         // Previous Pixhawk GPS time, only run again if new data exists
uint32_t GPS_stat[1] = {0};   // GPS state (3D lock, 2D, none, etc.)
double PixTime[2] = {0, 0}; // Pixhawk system time (us) and time since boot (ms)
elapsedMillis oldTime;        // Timer for LED blink
bool armed = false;           // Flag to determine if aircraft is armed or not
///////////////////// END Pixhawk Setup

///////////////////// MTP PROTOCOL SETUP (SD)
bool USB_STATE = false;

#define USE_SD  1         // SDFAT based SDIO and SPI
#define USE_LFS_RAM 0     // T4.1 PSRAM (or RAM)
#define USE_LFS_QSPI 0    // T4.1 QSPI
#define USE_LFS_PROGM 0   // T4.1 Progam Flash
#define USE_LFS_SPI 0     // SPI Flash

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


/****  Start device specific change area  ****/
// SDClasses
#if USE_SD==1
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
#endif

MTPStorage_SD storage;
MTPD    mtpd(&storage);
///////////////////// END MTP PROTOCOL SETUP (SD)

void storage_configure() {
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

void setup() {
  Serial.begin(115200);
  pinMode(led, OUTPUT);      // Teensy build-in LED for reference
  pinMode(btnState, INPUT);  // Button to trigger between MTP/Logging modes
  pinMode(btnLED, OUTPUT);   // Visual indicator of MTP/Logger state

  // If MTP mode is requested
  if (ENTRY == true) {
    digitalWrite(btnLED, HIGH);
    digitalWrite(led, HIGH);
    USB_STATE = true;
    Serial.println("Entering MTP protocol for file transfer.");
    Serial.println("No data will be processed or recorded until after reboot and disconnect from PC.");

#if USE_EVENTS==1
    usb_init_events();
#endif

#if !__has_include("usb_mtp.h")
    usb_mtp_configure();
#endif
    storage_configure();

    // Switch to non-MTP mode if false
  }
  else
  {

    // If both anemometers are enabled, error out
#if ((Young92 + Young81 + TriMini) > 1)
    Serial.println("Error: Cannot have multiple anemometer types enabled at the same time. Choose only one, and reflash to Teensy.");
    digitalWrite(led, HIGH);
    while (1) {
      digitalWrite(led, !digitalRead(led));
      delay(500);
      digitalWrite(led, !digitalRead(led));
      delay(2000);
    }
#endif

    // If neither anemometers are enabled, error out
#if ((Young92 + Young81 + TriMini) < 1)
    Serial.println("Error: Please enable one of the anemometer types and reflash code to Teensy.");
    digitalWrite(led, HIGH);
    while (1) {
      digitalWrite(led, !digitalRead(led));
      delay(500);
      digitalWrite(led, !digitalRead(led));
      delay(2000);
    }
#endif

    Serial.println("Enter normal data logging mode...");
    digitalWrite(btnLED, LOW);
    digitalWrite(led, LOW);

    // Enable chosen serial type, preventing the other from running
    // Preserves overhead processing power
#if Young81 == true
    young81.begin(38400);
    Serial.println("Young 81000 anemometer data requested.");
#endif

#if Young92 == true
    young92.begin(38400);
    Serial.println("Young 92000 anemometer data requested.");
#endif

#if TriMini == true
    triAnem.begin(115200, SERIAL_8N1);
    Serial.println("Trisonica anemometer data requested.");
#endif

#if Pixhawk == true
    pixSerial.begin(115200);
    Serial.println("Pixhawk data requested.");
#endif

    // Allow all systems to catch up
    delay(1000);

    // Initialize SD card
    if (!SD.begin(chipSelect)) {
      while (1) {
        digitalWrite(led, !digitalRead(led));
        Serial.println("Teensy 4.1 SD fail. Reset card and try again.");
        delay(2000);
      }
    }

    Serial.println("SD card initialized.");

    // If Pixhawk connection is true, not connected over USB, attempt to get GPS data
    // Will stay stuck in loopif  GPS fix is not established or Mavlink Data is not being sent
#if Pixhawk == true
    if (ARM_CHK == true) {
      oldTime = 0;
      bool msgSend = false;
      while (GPS_stat[0] < 3) {
        if (msgSend == false) {
          Serial.println("Waiting for valid GPS signal...");
          telemSerial.println("Waiting for valid GPS signal...");
          msgSend = true;
        }
        MavLink_receive();
        if (oldTime >= 1000) {
          digitalWrite(led, !digitalRead(led));
          oldTime = oldTime - 1000;
        }
      }

      oldTime = 0;
      msgSend = false;
      while (PixTime[0] < 5) {
        MavLink_receive();
        if (msgSend == false) {
          Serial.println("Waiting for GPS 3D position lock...");
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

    // Initialize filename variable
    // Iterate over all known files to keep naming consistent but iterable
    int n = 0;
#if TriMini == true
    snprintf(filename, sizeof(filename), "TRI_%03d.csv", n); // includes a three-digit sequence number in the file name
    while (SD.exists(filename)) {
      n++;
      snprintf(filename, sizeof(filename), "TRI_%03d.csv", n);
    }

    file = SD.open(filename, FILE_WRITE);
    file.println("Board Time(ms),3D Wind Speed (m/s),2D Wind Speed (m/s),Horiz. Direction (deg),Verti. Direction (deg),U Velocity (m/s),V Velocity (m/s),W Velocity (m/s),Temperature (C),Humidity (%),Dew Point (C),X Level (unknown),Y Level (unknown),Z level (unknown),Pitch (deg),Roll (deg),Mag Heading (deg),Unix Time (sec),Pix Boot Time (ms)");
    file.close();
    triAnem.flush();
#endif

#if Young92 == true
    snprintf(filename, sizeof(filename), "Y92_%03d.csv", n); // includes a three-digit sequence number in the file name
    while (SD.exists(filename)) {
      n++;
      snprintf(filename, sizeof(filename), "Y92_%03d.csv", n);
    }

    file = SD.open(filename, FILE_WRITE);
    file.println("Board Time(ms),Wind Speed (m/s),Wind Direction (deg),Temp (C),Humidity (%RH),Pressure (hPa),Unix Time (sec),Pix Boot Time (ms)");
    file.close();
    young92.flush;
#endif

#if Young81 == true
    snprintf(filename, sizeof(filename), "Y81_%03d.csv", n); // includes a three-digit sequence number in the file name
    while (SD.exists(filename)) {
      n++;
      snprintf(filename, sizeof(filename), "Y81_%03d.csv", n);
    }

    file = SD.open(filename, FILE_WRITE);
    file.println("Board Time(ms),Wind Speed (m/s),Wind Direction (deg),Wind Elevation (deg),Speed of Sound (m/s),Temp (C),Unix Time (sec),Pix Boot Time (ms)");
    file.close();
    young81.flush();
#endif

    Serial.println(n);
    Serial.println(filename);
    Serial.println("File setup complete.");

  }
}

void loop() {
  Serial.println("All systems ready, chosen operation commencing!");
  if (USB_STATE == true) {
    Serial.println("Media Transfer Protocol activated, preparing for file transfer capabilites...");
    while (1) {
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
#endif
    }
  }
  else
  {
    Serial.println("Entering main data collection loop now...");
    while (1) {

      digitalWrite(btnLED, !digitalRead(btnLED));
      file = SD.open(filename, FILE_WRITE);
      Time = millis();
      file.print((String) Time + ',');

#if Young92 == true
      Young92000();
#endif

#if Young81 == true
      Young81000();
#endif

#if TriMini == true
      Trisonica();
#endif

#if Pixhawk == true
      MavLink_receive();

      if (PixTime[1] > oldPixTime) {
        digitalWrite(led, !digitalRead(led));
        file.printf("%16lf", PixTime[0]);
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
  }
}

void Young81000() {

  int index = 0;
  boolean newData = false;
  const byte numChars = 35;
  char fromAnem[numChars];
  char endMarker = (char)13;
  int arrLoc = 0;

  for (int i = 0; i < numChars; i++) {
    while (!young81.available());
    char val = young81.read();
    fromAnem[index] = val;
    index++;
    fromAnem[index] = '\0';
  }

  for (int i = 0; i < sizeof(fromAnem); i++) {
    char val = fromAnem[i];
    if (val == endMarker) {
      index = 0;
      for (int j = 2; j < 8; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wSpeed81[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wSpeed81[index] = fromAnem[j + i];
        }
        index++;
        wSpeed81[index] = '\0';
      }
      index = 0;
      for (int j = 8; j < 14; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wAng81[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wAng81[index] = fromAnem[j + i];
        }
        index++;
        wAng81[index] = '\0';
      }
      index = 0;
      for (int j = 14; j < 20; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wEle81[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wEle81[index] = fromAnem[j + i];
        }
        index++;
        wEle81[index] = '\0';
      }
      index = 0;
      for (int j = 20; j < 27; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          SoS81[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          SoS81[index] = fromAnem[j + i];
        }
        index++;
        SoS81[index] = '\0';
      }
      index = 0;
      for (int j = 27; j < 34; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          Temp81[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          Temp81[index] = fromAnem[j + i];
        }
        index++;
        Temp81[index] = '\0';
      }
      break;
    }
  }

#if USB == true
  Serial.println();
  Serial.println(String("Speed: ") + wSpeed81);
  Serial.println(String("Direction: ") + wAng81);
  Serial.println(String("Elevation: ") + wEle81);
  Serial.println(String("Speed of Sound: ") + SoS81);
  Serial.println(String("Temp: ") + Temp81);
  Serial.println();
#endif

  file.print((String) wSpeed81 + ',' + wAng81 + ',' + wEle81 + ',' + SoS81 + ',' + Temp81 + ',');

}

void Young92000() {

  int index = 0;
  boolean newData = false;
  const byte numChars = 40;
  char fromAnem[numChars];
  char startMarker = (char)83;
  char endMarker = (char)10;
  int arrLoc = 0;

  for (int i = 0; i < numChars; i++) {
    while (!young92.available());
    char val = young92.read();
    fromAnem[index] = val;
    index++;
    fromAnem[index] = '\0';
  }

  for (int i = 0; i < sizeof(fromAnem) - 1; i++)
  {

    char val = fromAnem[i];
    if (val == startMarker)
    {
      index = 0;
      for (int j = 2; j < 8; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wSpeed92[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wSpeed92[index] = fromAnem[j + i];
        }
        index++;
        wSpeed92[index] = '\0';
      }
      index = 0;
      for ( int j = 9; j < 14; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wAng92[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wAng92[index] = fromAnem[j + i];
        }
        index++;
        wAng92[index] = '\0';
      }
      index = 0;
      for ( int j = 15; j < 20; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wTemp92[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wTemp92[index] = fromAnem[j + i];
        }
        index++;
        wTemp92[index] = '\0';
      }
      index = 0;
      for ( int j = 21; j < 26; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          wHumid92[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          wHumid92[index] = fromAnem[j + i];
        }
        index++;
        wHumid92[index] = '\0';
      }
      index = 0;
      for ( int j = 27; j < 33; j++) {
        if ((j + i) > (sizeof(fromAnem) - 1)) {
          aPress92[index] = fromAnem[j + i - sizeof(fromAnem)];
        } else {
          aPress92[index] = fromAnem[j + i];
        }
        index++;
        aPress92[index] = '\0';
      }
      break;
    }
  }
#if USB == true
  Serial.println();
  Serial.println(String("Speed: ") + wSpeed92);
  Serial.println(String("Direction: ") + wAng92);
  Serial.println(String("Temp: ") + wTemp92);
  Serial.println(String("Humidity: ") + wHumid92);
  Serial.println(String("Pressure: ") + aPress92);
  Serial.println();
#endif

  file.print((String) wSpeed92 + ',' + wAng92 + ',' + wTemp92 + ',' + wHumid92 + ',' + aPress92 + ',');

}

void Trisonica() {

  delay(10);
  int index = 0;
  boolean newData = false;
  boolean dataRcvd = false;
  const byte numChars = 150;
  char fromAnem[numChars];
  char startMarker = (char)10;
  char endMarker = (char)13;
  int arrLoc = 0;

  while (dataRcvd == false) {
    while (!triAnem.available());
    char val = triAnem.read();
    if (newData == false) {
      if (val == startMarker) {
        fromAnem[index] = val;
        index++;
        fromAnem[index] = '\0';
        newData = true;
      }
    }
    else if (val == endMarker)
    {
      dataRcvd = true;
      break;
    }
    else
    {
      fromAnem[index] = val;
      index++;
      fromAnem[index] = '\0';
    }
  }

#if USB == true
  //Serial.print("From Anem: ");
  //Serial.println(fromAnem);
#endif

  index = 0;
  for (int j = 3; j < 9; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      speed3D[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      speed3D[index] = fromAnem[j];
    }
    index++;
    speed3D[index] = '\0';
  }

  index = 0;
  for ( int j = 13; j < 19; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      speed2D[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      speed2D[index] = fromAnem[j];
    }
    index++;
    speed2D[index] = '\0';
  }

  index = 0;
  for ( int j = 22; j < 26; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      dirHoriz[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      dirHoriz[index] = fromAnem[j];
    }
    index++;
    dirHoriz[index] = '\0';
  }

  index = 0;
  for ( int j = 30; j < 34; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      dirVert[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      dirVert[index] = fromAnem[j];
    }
    index++;
    dirVert[index] = '\0';
  }

  index = 0;
  for ( int j = 37; j < 43; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      uVec[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      uVec[index] = fromAnem[j];
    }
    index++;
    uVec[index] = '\0';
  }

  index = 0;
  for ( int j = 46; j < 52; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      vVec[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      vVec[index] = fromAnem[j];
    }
    index++;
    vVec[index] = '\0';
  }

  index = 0;
  for ( int j = 55; j < 61; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      wVec[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      wVec[index] = fromAnem[j];
    }
    index++;
    wVec[index] = '\0';
  }

  index = 0;
  for ( int j = 64; j < 70; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      temp[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      temp[index] = fromAnem[j];
    }
    index++;
    temp[index] = '\0';
  }

  index = 0;
  for ( int j = 73; j < 79; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      humid[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      humid[index] = fromAnem[j];
    }
    index++;
    humid[index] = '\0';
  }

  index = 0;
  for ( int j = 83; j < 89; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      dewPoint[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      dewPoint[index] = fromAnem[j];
    }
    index++;
    dewPoint[index] = '\0';
  }

  index = 0;
  for ( int j = 93; j < 99; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      xLevel[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      xLevel[index] = fromAnem[j];
    }
    index++;
    xLevel[index] = '\0';
  }

  index = 0;
  for ( int j = 103; j < 109; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      yLevel[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      yLevel[index] = fromAnem[j];
    }
    index++;
    yLevel[index] = '\0';
  }

  index = 0;
  for ( int j = 113; j < 119; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      zLevel[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      zLevel[index] = fromAnem[j];
    }
    index++;
    zLevel[index] = '\0';
  }

  index = 0;
  for ( int j = 123; j < 129; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      pitch[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      pitch[index] = fromAnem[j];
    }
    index++;
    pitch[index] = '\0';
  }

  index = 0;
  for ( int j = 133; j < 139; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      roll[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      roll[index] = fromAnem[j];
    }
    index++;
    roll[index] = '\0';
  }

  index = 0;
  for ( int j = 143; j < 148; j++) {
    if ((j) > (sizeof(fromAnem) - 1)) {
      magHead[index] = fromAnem[j - sizeof(fromAnem)];
    } else {
      magHead[index] = fromAnem[j];
    }
    index++;
    magHead[index] = '\0';
  }

#if USB == true
  Serial.println();
  Serial.println(String("3D Speed: ") + speed3D);
  Serial.println(String("2D Speed: ") + speed2D);
  Serial.println(String("H.Dir: ") + dirHoriz);
  Serial.println(String("V.Dir: ") + dirVert);
  Serial.println(String("U: ") + uVec);
  Serial.println(String("V: ") + vVec);
  Serial.println(String("W: ") + wVec);
  Serial.println(String("Temp: ") + temp);
  Serial.println(String("Humid: ") + humid);
  Serial.println(String("DewPoint: ") + dewPoint);
  Serial.println(String("X Level: ") + xLevel);
  Serial.println(String("Y Level: ") + yLevel);
  Serial.println(String("Z Level: ") + zLevel);
  Serial.println(String("Pitch: ") + pitch);
  Serial.println(String("Roll: ") + roll);
  Serial.println(String("Heading: ") + magHead);
  Serial.println();
#endif

  file.print((String)speed3D + ',' + speed2D + ',' + dirHoriz + ',' + dirVert + ',' + uVec + ',' + vVec + ',' + wVec + ',' + temp + ',' + humid + ',' + dewPoint + ',' + xLevel + ',' + yLevel + ',' + zLevel + ',' + pitch + ',' + roll + ',' + magHead + ',');
}

void MavLink_receive() {
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

            //uint64_t Ptime = system_time.time_unix_usec;
            PixTime[0] = system_time.time_unix_usec;
            PixTime[1] = system_time.time_boot_ms;

#if USB == true
            Serial.print("Unix Time: ");
            Serial.printf("%16lf\n", PixTime[0]);
            Serial.print("Pix Boot Time: ");
            Serial.println(PixTime[1]);
#endif

            return PixTime;


          }
          break;

        case MAVLINK_MSG_ID_HEARTBEAT:  // #0: Heartbeat
          {

            mavlink_heartbeat_t heartbeat;
            mavlink_msg_heartbeat_decode(&msg, &heartbeat);

            armed = ((heartbeat.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) ? true : false);

          }
          break;

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
