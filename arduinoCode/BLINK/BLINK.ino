// ESP32 mmWave Sensor UART Reader using Serial2
const int testPin = 2;

void setup() {
  pinMode(testPin, OUTPUT);
}

void loop() {
    digitalWrite(testPin, HIGH);
    delay(1000);
    digitalWrite(testPin, LOW);
    delay(1000);
}