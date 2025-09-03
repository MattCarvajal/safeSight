#define ESP_RX2_PIN 4    // now using GPIO4
#define ESP_TX2_PIN -1   // unused

HardwareSerial PiSerial(2);  // UART2

#define LED_PIN 2

void setup() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  Serial.begin(115200);
  PiSerial.begin(115200, SERIAL_8N1, ESP_RX2_PIN, ESP_TX2_PIN);
  Serial.println("ESP32 listening on UART2 (RX=GPIO4) …");
}

void loop() {
  if (PiSerial.available()) {
    char c = PiSerial.read();
    if (c == '1') {
      digitalWrite(LED_PIN, HIGH);
      Serial.println("Got 1 → LED ON");
    }
    else if (c == '0') {
      digitalWrite(LED_PIN, LOW);
      Serial.println("Got 0 → LED OFF");
    }
  }
  delay(100);
}
