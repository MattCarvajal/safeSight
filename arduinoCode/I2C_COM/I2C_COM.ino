#include <Wire.h>

#define LED_PIN 2        // Built-in LED on many ESP32 boards
#define I2C_SLAVE_ADDR 0x08

void receiveEvent(int bytes) {
  while (Wire.available()) {
    uint8_t cmd = Wire.read();

    if (cmd == 0x01) {
      digitalWrite(LED_PIN, HIGH);
      Serial.println("LED ON (Received 0x01)");
    } else if (cmd == 0x00) {
      digitalWrite(LED_PIN, LOW);
      Serial.println("LED OFF (Received 0x00)");
    } else {
      Serial.print("Unknown command received: 0x");
      Serial.println(cmd, HEX);
    }
  }
}

void setup() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.begin(115200);
  delay(1000);
  Serial.println("ESP32 I2C Slave Ready");

  Wire.begin(I2C_SLAVE_ADDR);           // Join I2C bus as slave
  Wire.onReceive(receiveEvent);         // Register receive handler
}

void loop() {
  // Nothing here, everything handled in receiveEvent
}
