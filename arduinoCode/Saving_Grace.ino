#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "DFRobot_C4001.h"

// Pin assignments
const int Speaker = 2;
#define I2C_SDA 21
#define I2C_SCL 22
#define RADAR_RX 16
#define RADAR_TX 17
#define ESP_RX2_PIN 26    // now using GPIO4
#define ESP_TX2_PIN 25   // unused

// ------- Initialize all LOGIC VARIABLES --------
bool attentive, greenLight, pedDetected = false;
enum MotionState{
  ACCELERATION,
  DECELERATION,
  IDLE_MOTION,
  IDLE_STILL
};
// Car State Variables
MotionState carState;
MotionState prevState;
// Initialize carStates and on startup prevstate = IDLE_STILL
const float ACCEL_THRESHOLD = -2.0;
const float DECEL_THRESHOLD = 2.0;

// Sensor instances
Adafruit_MPU6050 mpu;
DFRobot_C4001_UART radar(&Serial1, 9600, 16, 17);
HardwareSerial PiSerial(2);  // UART2

void setup() {
  // Initialize Speaker Pin, set LOW
  pinMode(Speaker, OUTPUT);
  digitalWrite(Speaker, LOW);

  // Begin I2C Communication BUS and Serial Monitor
  Serial.begin(115200);
  Wire.begin(I2C_SDA, I2C_SCL);

  // --- Init MPU6050 ---
  Serial.println("Initializing MPU6050...");
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) delay(10);
  }
  Serial.println("MPU6050 Found!");
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  Serial.println("MPU6050 configured successfully!\n");

  // Begin the Serial COM
  Serial.println("Initializing radar...");
  Serial1.begin(9600, SERIAL_8N1, 16, 17);
  delay(100);
  Serial.println("Serial1 initialized.");

  // --- Init Radar ---
  Serial.println("Setting radar mode...");
  radar.setSensorMode(eSpeedMode);
  //radar.setSensor(eStartSen);
  Serial.println("Radar mode set.");

  sSensorStatus_t data = radar.getStatus();
  Serial.print("work status  = "); Serial.println(data.workStatus);
  Serial.print("work mode    = "); Serial.println(data.workMode);
  Serial.print("init status  = "); Serial.println(data.initStatus);
  Serial.println();

  // Set Detection Threshold RADAR
  if (radar.setDetectThres(11, 1200, 10)) {
    Serial.println("Set detect threshold successfully");
  }

  // RADAR DETAILS
  radar.setFrettingDetection(eON);
  Serial.print("min range = "); Serial.println(radar.getTMinRange());
  Serial.print("max range = "); Serial.println(radar.getTMaxRange());
  Serial.print("threshold range = "); Serial.println(radar.getThresRange());
  Serial.print("fretting detection = "); Serial.println(radar.getFrettingDetection());

  // ON START SET THESE CAR STATES
  prevState = IDLE_STILL;
  carState = IDLE_STILL;

  //Begin Serial Pi
  PiSerial.begin(115200, SERIAL_8N1, ESP_RX2_PIN, ESP_TX2_PIN);
  Serial.println("ESP32 listening on UART2 ");
}

void loop() {
  // ------ Receive All Data First ------

  // Radar Fetch Value, Print
  sensors_event_t a, g, temp;
  float targetNumber = radar.getTargetNumber();
  float radarValue = radar.getTargetRange();
  Serial.print("target range  = "); Serial.print(radarValue); Serial.println(" m");


  if ((radarValue < 3) && (radarValue >= 1)){
    pedDetected = true;
    Serial.println("Pedestrian Detected");
  }else{
    pedDetected = false;
    Serial.println("NO Pedestrian Detected");
  }

  // Accelerometer Fetch Value, print, and Filter
  mpu.getEvent(&a, &g, &temp);
  float accelValue = a.acceleration.x;
  Serial.print("Accelration:"); Serial.println(a.acceleration.x);

  if ((accelValue < ACCEL_THRESHOLD) && (prevState == IDLE_STILL || prevState == IDLE_MOTION)) {
    prevState = carState;
    carState = ACCELERATION;
    Serial.println("ACCELERATING");
  } 
  else if ((accelValue > DECEL_THRESHOLD) && (prevState == IDLE_MOTION)) {
    prevState = carState;
    carState = DECELERATION;
    Serial.println("DECELERATING");
  } 
  else if ((accelValue < DECEL_THRESHOLD) && (accelValue > ACCEL_THRESHOLD) && prevState == ACCELERATION) {
    prevState = carState;
    carState = IDLE_MOTION;
    Serial.println("IDLE_MOTION");
  }
  else if ((accelValue < DECEL_THRESHOLD) && (accelValue > ACCEL_THRESHOLD) && ((prevState == DECELERATION) || prevState == IDLE_STILL)) {
    prevState = carState;
    carState = IDLE_STILL;
    Serial.println("IDLE_STILL");
  }else{
    // We need accelerometer values to be right if not continue
  }

  // Pi Serial Data
  // Read Serial Data, IF......ELSEif....ELSEif
  while (PiSerial.available()) {
    uint8_t c = PiSerial.read();
    switch(c) {
        case 0x11:
            greenLight = true;
            attentive = true;
            Serial.println("Green Light, Attentive");
            break;
        case 0x01:
            greenLight = false;
            attentive = true;
            Serial.println("No Green, Attentive");
            break;
        case 0x10:
            greenLight = true;
            attentive = false;
            Serial.println("Green, Distracted");
            break;
        default:
            greenLight = false;
            attentive = false;
            Serial.println("No green, distracted");
            break;
    }
  }

  // ------- LOGIC HANDLING --------
  // Car is IDLE, check for green light and attentive 
  if ((carState == IDLE_STILL) && (prevState == DECELERATION || prevState == IDLE_STILL)){
    digitalWrite(Speaker, LOW);
    if((greenLight == true) && (attentive != true)){
      digitalWrite(Speaker, HIGH);
      //--------- UART TRANSMIT-----------
      PiSerial.write(0x01);
      Serial.println("Not paying attention during green light");
    }
  }
  else{
    if(attentive == true){
      digitalWrite(Speaker, LOW);
    }
    else{
      digitalWrite(Speaker, HIGH);
      //--------- UART TRANSMIT-----------
      PiSerial.write(0x01);
      Serial.println("Not paying attention while in motion");
    }
    if(pedDetected == true && attentive != true){
      digitalWrite(Speaker, HIGH);
      //--------- UART TRANSMIT-----------
      PiSerial.write(0x01);
      Serial.println("Not paying attention while in motion and pedestrian");
    }
  }
  delay(100);
  Serial.println("");
}
