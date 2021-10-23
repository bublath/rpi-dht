# rpi-dht

Perl interface to read alues from DHT11 and DHT22 sensors (in a more reliable way than the Raspberry kernel driver dht11).
Based on the work of Steve Bertrand: https://github.com/stevieb9/rpi-dht11 and David Feng https://github.com/fengcda/DHT_Sensor_AVR_Library

Changes from Steve's work:
- Added support for DHT22 sensors
- Added support for decimal digits for DHT11 sensors (this might be support added with newer sensors since old drivers always ignored it)
- Modified the read algorithm to me more robust and closer to the chip specifications
- Added function to read temperature and humidity on one go (since they always get queried both from the sensor anyway) which also increased reliablity 
- Limit number of retries so wrong configurations etc. don't block forever
- Returning "undef" in case of erros

