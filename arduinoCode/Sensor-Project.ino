const int trigPin = 7;
const int echoPin = 8;

void setup() {
  // put your setup code here, to run once:
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  Serial.begin(9600);
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(trigPin, LOW);
  delayMicroseconds(10);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH);
  long in = microsecondsToInches(duration);
  long cm = microsecondsToCentimeters(duration);

  Serial.print("Distance: ");
  Serial.print(in);
  Serial.print(" in\n");
  Serial.print("Distance: ");
  Serial.print(cm);
  Serial.print(" cm\n");
}

long microsecondsToInches(long microseconds) {
  return microseconds / 74 / 2;

}

long microsecondsToCentimeters (long microseconds) {
  return microseconds / 29 / 2;
}