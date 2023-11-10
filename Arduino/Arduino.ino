#include <MIDI.h>

#define inputSize 12
MIDI_CREATE_DEFAULT_INSTANCE();

const int inputPort[] = { 34, 18, 32, 25, 16, 2, 15, 17, 33, 26, 13, 27 };
const int note[] = {60, 62, 64, 65, 67, 69, 71, 61, 63, 66, 68, 70};

int lastState[inputSize], currentState[inputSize];

void setup() {
  Serial.begin(115200);
  for (int i = 0; i < inputSize; i++) {
    pinMode(inputPort[i], INPUT);
    lastState[i] = LOW;
    currentState[i] = LOW;
  }
}
void loop() {
  for (int i = 0; i < inputSize; i++) {
    currentState[i] = digitalRead(inputPort[i]);
    if (lastState[i] == LOW && currentState[i] == HIGH) {
      //Serial.println("Port " + String(inputPort[i]) + " is touched");
      MIDI.sendNoteOn(note[i], 127, 1);
    } else if (lastState[i] == HIGH && currentState[i] == LOW) {
      //Serial.println("Port " + String(inputPort[i]) + " is released");
      MIDI.sendNoteOff(note[i], 127, 1);
    }
    lastState[i] = currentState[i];
  }
}
