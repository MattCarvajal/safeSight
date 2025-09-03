#include <SPI.h>

#define LED_PIN 2
#define SS_PIN 5  // Chip Select (CS) pin

// SPI pins - modify according to your setup
#define SPI_MISO_PIN 19
#define SPI_MOSI_PIN 23
#define SPI_SCK_PIN 18

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Set up the SPI bus
  pinMode(SPI_MISO_PIN, INPUT);
  pinMode(SPI_MOSI_PIN, INPUT);
  pinMode(SPI_SCK_PIN, INPUT);
  pinMode(SS_PIN, INPUT_PULLUP);  // CS pin as input with pull-up resistor

  SPI.begin(SPI_SCK_PIN, SPI_MISO_PIN, SPI_MOSI_PIN, SS_PIN);  // Begin SPI bus with custom pins
  SPI.beginTransaction(SPISettings(1000000, MSBFIRST, SPI_MODE0));  // Set SPI speed, bit order, and mode

  Serial.println("SPI Slave Ready");
}

void loop() {
  if (digitalRead(SS_PIN) == LOW) {  // Check if CS is active (LOW)
    // Slave is selected, perform communication
    uint8_t receivedData = SPI.transfer(0x00);  // Transfer dummy data to receive data from master
    
    Serial.print("Received: 0x");
    Serial.println(receivedData, HEX);

    // Control the LED based on the received data
    if (receivedData == 0x01) {
      digitalWrite(LED_PIN, HIGH);
    } else if (receivedData == 0x00) {
      digitalWrite(LED_PIN, LOW);
    }
  }

  delay(10);  // Small delay to prevent overloading the loop
}
