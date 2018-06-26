/*  testdraw
 *
 *      A simple sketch to test our drawing
 */

#include <SPI.h>       // this is needed for display
#include <Wire.h>      // this is needed for FT6206
#include <Adafruit_GFX.h>    // Core graphics library
#include <Adafruit_ILI9341.h>
#include <Adafruit_FT6206.h>
#include "Helvetica24.h"

#define TFT_DC 9
#define TFT_CS 10

// Use hardware SPI (on Uno, #13, #12, #11) and the above for CS/DC
Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC);


void setup() 
{
    tft.begin();

    tft.fillScreen(ILI9341_BLACK);

    tft.setCursor(5,20);
    tft.setFont(&Helvetica24);
    tft.setTextColor(ILI9341_RED);
    tft.println("Hello world!");
}

void loop() {
  // put your main code here, to run repeatedly:

}
