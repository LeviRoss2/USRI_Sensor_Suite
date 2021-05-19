#include "SdFat-3.6.h"
#include "sdios.h"
#include <i2c_t3.h>
#include <SPI.h>
#include <mavlink.h>
#include <Adafruit_ADS1015-3.6.h>
#include <TimeLib.h>

/////// SET VALUES HERE ////////////////////////

#define Pixhawk true // true for MavLink message parsing
#define TPH true  // true for Temp and Humidity calcs
#define USB false // true for full serial output, false for no serial output (Serial.print(), etc.)
#define ARM_CHK true // Disable/enable arming check before logging starts
int FHP_freq = 200; // Hz | MAX: 200, MIN: 2 | Five Hole Probe refresh rate
int SS_freq = 10;   // Hz | MAX: 20, MIN: 2 | Sensor Suite refresh rate
#define addressMHP 0x38   // 0x28 | 0x38

////// DO NOT EDIT BEYOND THIS POINT ///////////

SdFatSdio sd;
SdFile file;
char filename[12]; // make it long enough to hold your longest file name, plus a null terminator

int Time = millis();
// Default SD chip select is SS pin
const uint8_t SD_CHIP_SELECT = SS;
#define SD_CS = BUILTIN_SDCARD;

#if Pixhawk == true
#define HWSERIAL
#endif

int led = LED_BUILTIN;
int count = 0;
int FHPiter = 0;
int FHPlast = 0;
int SSiter = 0;
int SSlast = 0;
int last_tot = 0;
int SScount = 0;
int FHPcount = 0;
float oldPixTime = 0;
uint32_t GPS_stat[1] = {0};
uint32_t PixTime[2] = {0, 0};
elapsedMillis oldTime;

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

//Low Pass Filter
double alpha = 0.5;
double temperature_bead[3] = { 0, 0, 0};
double temperature_ant[3] = { 0, 0, 0};
double humidity_ant[3] = { 0, 0, 0};

int AS1 = 0;
int AS2 = 0;
int AS3 = 0;

uint16_t Year = 0000;
uint8_t Month = 00;
uint8_t Day = 00;
uint8_t Hour = 00;
uint8_t Minute = 00;
uint8_t Second = 00;

void dateTime(uint16_t* date, uint16_t* time) {
  // User gets date and time from GPS or real-time
  // clock in real callback function

  // return date using FAT_DATE macro to format fields
  *date = FAT_DATE(Year, Month, Day);

  // return time using FAT_TIME macro to format fields
  *time = FAT_TIME(Hour, Minute, Second);
}

void printTimestamps(SdFile& f) {
  dir_t d;
  if (!f.dirEntry(&d)) {  }

  f.printFatDate(d.creationDate);
  f.printFatTime(d.creationTime);

  f.printFatDate(d.lastWriteDate);
  f.printFatTime(d.lastWriteTime);

  f.printFatDate(d.lastAccessDate);
}

//------------------------------------------------------------------------------
void setup(void) {

  Serial.begin(115200);
#if Pixhawk == true
  Serial1.begin(115200);
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
  if (!sd.begin()) {
    // don't do anything more:
    while (1) {
      Serial.println("Teensy 3.6 SD fail. Reset card and try again.");
      digitalWrite(led, !digitalRead(led));
      delay(2000);
    }
  }
#if Pixhawk == true
  if (USB == false) {
    oldTime = 0;
    while (GPS_stat[0] < 3) {
      GPS_receive();
      if (oldTime >= 1000) {
        digitalWrite(led, !digitalRead(led));
        oldTime = oldTime - 1000;
      }
    }

    oldTime = 0;
    while (PixTime[0] < 5) {
      MavLink_receive();
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
    Year = 2020;
    Month = 06;
    Day = 22;
    Hour = 16;
    Minute = 18;
    Second = 52;
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
  printTimestamps(file);
  if (Serial) {
    Serial.println("File written successfully");
  }

  file.close();

  delay(50);

  file.open(filename, FILE_WRITE);
  file.println("SS Time(ms), AS1-B1, AS1-B2, AS1-B3, AS1-B4, AS2-B1, AS2-B2, AS2-B3, AS2-B4, AS3-B1, AS3-B2, AS3-B3, AS3-B4, Humid1(%), HTemp1(C), Temp1(C), Volt1(mV), Humid2(%), HTemp2(C), Temp2(C), Volt2(mV), Humid3(%), HTemp3(C), Temp3(C), Volt3(mV), Unix Time (sec), Pix Boot Time (ms)");
  file.close();

  delay(1000);

#if Pixhawk == true
  if (ARM_CHK == true) {
    if (USB == false) {
      oldTime = 0;
      while (armed < 1) {
        Arming_Check();
        if (oldTime >= 250) {
          digitalWrite(led, !digitalRead(led));
          oldTime = oldTime - 250;
        }
      }
    }
  }
#endif
}

void loop() {

  last_tot = 0;
  while (USB == true) {
    digitalWrite(led, !digitalRead(led));
    Time = millis();
    file.open(filename, FILE_WRITE);
    file.print(Time + String(','));
    Serial.println(String("Time: ") + Time);

    Wire.requestFrom(addressMHP, 4);   // request 6 bytes from slave device #8
    while (Wire.available()) { // slave may send less than requested
      int AS1 = Wire.read();   // receive a byte as int
      Serial.print(AS1 + String(' '));        // print the int
      file.print(AS1 + String(','));
    }

    Wire1.requestFrom(addressMHP, 4);   // request 4 bytes from slave device 0x38
    while (Wire1.available()) { // slave may send less than requested
      int AS2 = Wire1.read();   // receive a byte as int
      Serial.print(AS2 + String(' '));        // print the int
      file.print(AS2 + String(','));
    }

    Wire2.requestFrom(addressMHP, 4);   // request 4 bytes from slave device 0x38
    while (Wire2.available()) { // slave may send less than requested
      int AS3 = Wire2.read();   // receive a byte as int
      Serial.print(AS3 + String(' '));        // print the int
      file.print(AS3 + String(','));
    }

#if TPH == true
    if ((Time - SSlast) >= SSiter) {
      SSlast = Time;
      SScount++;
      Serial.println();

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

        Serial.print((String) temperature[i] + ',' + humidity[i] + ',' + temperature_bead[i] + ',' + volt + ',');
        file.print((String) temperature[i] + ',' + humidity[i] + ',' + temperature_bead[i] + ',' + volt + ',');
      }
      Serial.println();
    }
    else {
      file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
    }
#else
    file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
#endif

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

    FHPcount++;

    if ((Time - last_tot) >= 1000) {
      Serial.println(); Serial.print("SS count: "); Serial.println(SScount); Serial.print("FHP count: "); Serial.println(FHPcount);
      Serial.print("Pix Date and Time: ");
      Serial.printf("%4d-%02d-%02d %02d:%02d:%02d\n", year(PixTime[0]), month(PixTime[0]), day(PixTime[0]), hour(PixTime[0]), minute(PixTime[0]), second(PixTime[0]));
      Serial.println();
      last_tot = Time;
      SScount = 0;
      FHPcount = 0;
    }
#else
    FHPcount++;
    file.print((String)' ' + ',' + ' ' + ',');

    if ((Time - last_tot) >= 1000) {
      Serial.println(); Serial.print("SS count: "); Serial.println(SScount); Serial.print("FHP count: "); Serial.println(FHPcount);
      Serial.println();
      last_tot = Time;
      SScount = 0;
      FHPcount = 0;
    }

#endif

    file.println();
    file.close();
  }

  while (USB == false) {
    digitalWrite(led, !digitalRead(led));
    Time = millis();
    file.open(filename, FILE_WRITE);
    file.print(Time + String(','));

    Wire.requestFrom(addressMHP, 4);   // request 6 bytes from slave device #8
    while (Wire.available()) { // slave may send less than requested
      int AS1 = Wire.read();   // receive a byte as int
      file.print(AS1 + String(','));
    }

    Wire1.requestFrom(addressMHP, 4);   // request 4 bytes from slave device 0x38
    while (Wire1.available()) { // slave may send less than requested
      int AS2 = Wire1.read();   // receive a byte as int
      file.print(AS2 + String(','));
    }

    Wire2.requestFrom(addressMHP, 4);   // request 4 bytes from slave device 0x38
    while (Wire2.available()) { // slave may send less than requested
      int AS3 = Wire2.read();   // receive a byte as int
      file.print(AS3 + String(','));
    }

#if TPH == true
    if ((Time - SSlast) >= SSiter) {
      SSlast = Time;
      SScount++;

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

        file.print((String) temperature[i] + ',' + humidity[i] + ',' + temperature_bead[i] + ',' + volt + ',');
      }
    }
    else {
      file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
    }
#else
    file.print((String)' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',' + ' ' + ',');
#endif

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
bool Arming_Check()
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
