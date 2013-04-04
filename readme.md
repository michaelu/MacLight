MacLight
--------------
Purpose of this project is to mimic the AmbiLight feature of Philips television sets on a Macintosh computer. The program takes screenshots and calculates an average value for each led by taking 256 samples and calculating the mean. Most of the code has been created by copying and remixing other peoples work. Give credit where credit is due:

* The X-Code Project and most of the GUI parts are forked from the MacLight project of github user skattyadz (https://github.com/skattyadz/MacLight). It has been extended to not only sample a single color value of the screen, but to pick samples for an arbitrary number of leds around the screen.

* The original algorithm to do so is published as an processing sketch (http://learn.adafruit.com/adalight-diy-ambient-tv-lighting) this project can also be found on github (https://github.com/adafruit/Adalight).

* The pixel data is transfered in binary form to the microcontroller. On the controller the EasyTransfer library by Bil Porter is used (http://www.billporter.info/easytransfer-arduino-library/).

* To control the led string the FastSPI_LED library by Daniel Garcia is used. The code can be found here: https://code.google.com/p/fastspi/

Ready for your use, but very much undocumented.

#### PROBLEMS:
There seems to be a problem if the computer goes to sleep mode while the serial port is open.

#### TODO:
* Currently only the serial ports availbale at startup of the program are listed - could be improved.
* Framerate is hard coded to 15fps - make it configurable
* The number of leds is hard coded - make it configurable
* Fun feature: show a preview of the pixel data that is transfered to the controller.
* Apply gamma to constant color value.
* Clean up code
* Rename OpenGLScreenReader - it doesn't use openGL
* Allow user to calibrate the output level of each channel. The red LEDs in my setup are slightly too bright, so all red values are multiplied by 0.9 at the moment.
* Refactor things out of app delegate where possible
* Retain user settings