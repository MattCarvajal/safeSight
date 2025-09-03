#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "DFRobot_C4001.h"

// Pin assignments
const int testPin = 19;
#define I2C_SDA 21
#define I2C_SCL 22
#define RADAR_RX 16
#define RADAR_TX 17

// Sensor instances
Adafruit_MPU6050 mpu;
DFRobot_C4001_UART radar(&Serial1, 9600, RADAR_RX, RADAR_TX);

void setup() {
  // GPIO
  pinMode(testPin, OUTPUT);
  digitalWrite(testPin, LOW);

  // Serial for debug
  Serial.begin(115200);

  // I2C for MPU6050
  Wire.begin(I2C_SDA, I2C_SCL);

  // Init MPU6050
  Serial.println("Initializing MPU6050...");
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) delay(10);
  }
  Serial.println("MPU6050 Found!");
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  delay(100);

  // Init C4001 Radar
  Serial.println("Initializing C4001 Radar...");
  while (!radar.begin()) {
    Serial.println("Radar not detected!");
    delay(1000);
  }
  Serial.println("Radar Connected!");
  radar.setSensorMode(eSpeedMode);
  radar.setDetectThres(11, 1200, 10);
  radar.setFrettingDetection(eON);
}

void loop() {
  // ——— MPU6050 readings ———
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);
  Serial.print("Accel X: "); Serial.print(a.acceleration.x);
  Serial.print(", Y: "); Serial.print(a.acceleration.y);
  Serial.print(", Z: "); Serial.println(a.acceleration.z);

  // ——— Radar readings ———
  uint8_t targets = radar.getTargetNumber();
  float   speed   = radar.getTargetSpeed();
  float   range   = radar.getTargetRange();
  float   energy  = radar.getTargetEnergy();

  Serial.print("Targets: "); Serial.print(targets);
  Serial.print("  Speed: "); Serial.print(speed);
  Serial.print("  Range: "); Serial.print(range);
  Serial.print("  Energy: "); Serial.println(energy);

  // ——— testPin logic ———
  digitalWrite(testPin, (range < 2.0f) ? HIGH : LOW);

  Serial.println();  
  delay(200);
}