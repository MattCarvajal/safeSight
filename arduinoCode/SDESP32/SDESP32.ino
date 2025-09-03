const int testPin = 19;

void setup() {
  pinMode(testPin, OUTPUT);
}

void loop() {
  digitalWrite(testPin, HIGH);
  delay(10);
  digitalWrite(testPin, LOW);
  delay(1000);
}

// ESP32 mmWave Sensor UART Reader using Serial2

// Define the pins connected to the mmWave sensor
#define SENSOR_RX_PIN 16  // ESP32 receives data on this pin (connect to sensor TX)
#define SENSOR_TX_PIN 17  // ESP32 transmits data on this pin (connect to sensor RX)

void setup() {
  Serial.begin(115200);                // For Serial Monitor output
  Serial2.begin(256000, SERIAL_8N1, SENSOR_RX_PIN, SENSOR_TX_PIN); // Sensor UART config
  Serial.println("ESP32 mmWave Presence Sensor Test Started");
}

void loop() {
  while (Serial2.available()) {
    char c = Serial2.read();
    Serial.print(c);  // Forward sensor output to Serial Monitor
  }
}
