#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <DFRobot_C4001.h>

#define ESP_RX2_PIN 4    // now using GPIO4
#define ESP_TX2_PIN -1   // unused
#define I2C_SDA 21
#define I2C_SCL 22
#define RADAR_RX 16
#define RADAR_TX 17
#define LED_PIN 2

Adafruit_MPU6050 mpu;
DFRobot_C4001_UART radar(&Serial1, 9600, RADAR_RX, RADAR_TX);
HardwareSerial PiSerial(2);  // UART2

void setup() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.begin(115200);
  PiSerial.begin(115200, SERIAL_8N1, ESP_RX2_PIN, ESP_TX2_PIN);
  Serial.println("ESP32 listening on UART2 (RX=GPIO4) …");

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
  radar.setSensorMode(eExitMode);
  radar.setDetectThres(11, 1200, 10);
  radar.setFrettingDetection(eON);
}

void loop() {
  if (PiSerial.available()) {

    // Fetch Readings
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    float   range   = radar.getTargetRange();

    // Status Register Check
    uint8_t c = PiSerial.read();
    if (c == 0x01) {
      digitalWrite(LED_PIN, HIGH);
      Serial.println("Got 1 → LED ON");
    }
    else if (c == 0x00) {
      digitalWrite(LED_PIN, LOW);
      Serial.println("Got 0 → LED OFF");
    }
    Serial.print("  Range: "); Serial.print(range);
    Serial.println(); 
    Serial.print("Accel X: "); Serial.print(a.acceleration.x);
    Serial.print(", Y: "); Serial.print(a.acceleration.y);
    Serial.print(", Z: "); Serial.println(a.acceleration.z);
    Serial.println(); 
  }
  delay(4);
}
