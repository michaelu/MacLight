#include <EasyTransfer.h>
#include <FastSPI_LED.h>

#define NUM_LEDS 49
#define PIN 11

struct CRGB { unsigned char r; unsigned char g; unsigned char b; };
struct CRGB *leds;

EasyTransfer ET; 

struct RECEIVE_DATA_STRUCTURE {
  struct CRGB buffer[NUM_LEDS];
};

RECEIVE_DATA_STRUCTURE frame;

unsigned long time;
static const unsigned long timeout = 10000;

void setup(){
//  pinMode(13, OUTPUT);
//  digitalWrite(13, HIGH);
//  delay(333);
//  digitalWrite(13, LOW);
//  delay(333);
//  digitalWrite(13, HIGH);
//  delay(333);
//  digitalWrite(13, LOW);
  setupLED();

  Serial.begin(115200);
  uint8_t* buffer = FastSPI_LED.getRGBData();
  ET.begin((unsigned char*)buffer, NUM_LEDS * 3, &Serial);
  
  // timeout is unused
//  time = millis();
  boolean status_led_on = false;
  /// MAIN LOOP //////////////////////////////////
  
  for (;;) {
    if (ET.receiveData()) {
//      if (status_led_on) {
//        digitalWrite(13, LOW);
//        status_led_on = false;
//      } else {
//        digitalWrite(13, HIGH);
//        status_led_on = true;
//      }
      
//      time = millis();

      //Serial.print('?');
      FastSPI_LED.show();
    }
//    else {
//      if ((millis() - time) > timeout) {
//        // connection loss for >= 10 seconds, so switch off led
//        time = millis();
//        struct CRGB* buffer = (CRGB*) FastSPI_LED.getRGBData();
//        memset(buffer, 0, NUM_LEDS * 3);
//        FastSPI_LED.show();
//      }
//    }
  }
}

void setupLED() {
  pinMode(PIN, OUTPUT);
  FastSPI_LED.setLeds(NUM_LEDS);
  FastSPI_LED.setChipset(CFastSPI_LED::SPI_TM1809);
  FastSPI_LED.setPin(PIN);
  FastSPI_LED.init();
  FastSPI_LED.start();
  
  struct CRGB* buffer = (CRGB*) FastSPI_LED.getRGBData();
  memset(buffer, 0, NUM_LEDS * 3);
  FastSPI_LED.show();
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.println("?");
    delay(333);
  }
}

void loop(){
}
