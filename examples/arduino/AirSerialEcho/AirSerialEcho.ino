// AirSerial hardware test sketch.
//  - Sends "READY" once after boot (opening the port resets most boards; wait for this line first)
//  - Echoes every received byte back unchanged
// Open the board's COM port at 115200 with AirSerial, wait for "READY", then anything you send comes back.

const unsigned long BAUD = 115200;

void setup() {
  Serial.begin(BAUD);
  while (!Serial) { }          // boards with native USB (Leonardo, Micro) wait for the host
  Serial.print("READY\r\n");
}

void loop() {
  while (Serial.available() > 0) {
    Serial.write((uint8_t)Serial.read());
  }
}
