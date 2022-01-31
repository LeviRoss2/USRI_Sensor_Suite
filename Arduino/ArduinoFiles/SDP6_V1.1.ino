#include <Wire.h>
#include "SDP6x_W0.h"
#include "SDP6x_W1.h"
#include "SDP6x_W2.h"
#include "SD.h"
#include <SPI.h>

#define USB true

unsigned long Time = millis();
const unsigned long  iterTime = 1000;
unsigned long  last = 0;
const unsigned long  readIter = 33;
unsigned long  lastRead = 0;

float difPressure0;
float difPressure1;
float difPressure2;

int led = LED_BUILTIN;

File file;          // Initialize the variable used to access SD files
const uint8_t chipSelect = BUILTIN_SDCARD;  // Choose the Teensy built-in SD card slot
char filename[12];  // Initialize the filename used to write to SD files


//------------------------------------------------------------------------------
void setup(void) {

  Serial.begin(115200);

  delay(1000);

  Wire.begin();
  Wire1.begin();
  Wire2.begin();
  Serial.begin(9600);
  difPressure0 = 0.0;
  difPressure1 = 0.0;
  difPressure2 = 0.0;

  pinMode(led, OUTPUT); //LED for reference

  delay(1000);

  if (!SD.begin(chipSelect)) {
    // don't do anything more:
    while (1) {
      //      Serial.println("Teensy 3.6 SD fail. Reset card and try again.");
      digitalWrite(led, !digitalRead(led));
      delay(2000);
    }
  }

  int n = 0;
  snprintf(filename, sizeof(filename), "LOG%03d.csv", n); // includes a three-digit sequence number in the file name
  while (SD.exists(filename)) {
    n++;
    snprintf(filename, sizeof(filename), "LOG%03d.csv", n);
  }
  
  Serial.println(n);
  Serial.println(filename);

  Serial.println("File created successfully");


  file.close();

  delay(50);

  file = SD.open(filename, O_CREAT | O_WRITE);
  file.println("Teensy Time (ms), Diff Press 1 (Pa), Diff Press 2 (Pa), Diff Press 3 (Pa)");
  file.close();

  file = SD.open(filename, O_CREAT | O_WRITE);

}

void loop() {
  Time = millis();

  if ((Time - last) >= iterTime) {
    last = Time;
    file.flush();
  }

  if ((Time - lastRead) >= readIter) {

    lastRead = Time;
    digitalWrite(led, !digitalRead(led));
    difPressure0 = SDP6x0.GetPressureDiff0();
    difPressure1 = SDP6x1.GetPressureDiff1();
    difPressure2 = SDP6x2.GetPressureDiff2();
    Time = millis();

#if USB==true
    Serial.print(Time);
    Serial.print("      ");
    Serial.print(difPressure0);
    Serial.print(",  ");
    Serial.print(difPressure1);
    Serial.print(",  ");
    Serial.print(difPressure2);
    Serial.println();
#endif //USB == true

    char buf[25];
    sprintf(buf, "%lu,%f,%f,%f", Time, difPressure0, difPressure1, difPressure2);
    file.println(buf);
  }
}
