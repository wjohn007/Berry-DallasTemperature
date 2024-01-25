# Berry-DallasTemperature

A Berry application for DS18B20 temperature sensors

This application

- scans the 1-Wire bus looking for DS18B20-sensors
- captures the ID of each existing sensor
- acquires the temperature values from the sensors
- checks the validity of the values
- detects fault situations
- each sensor value can be adjusted via offset
- shows a nice UI with the sensor data and some controls
- transmits the temperature-values ​​via sensor-message
- support of SetOption8 (Fahrenheit/Celsius)
- support of Command TempOffset (default offset for unregistered sensors)
- detects faked sensors (not original Maxim)
- option: freeze value on error


Find more [information](ReadmeDallasTemp.md)



 # Berry-ThingSpeak

 If you want to store, aggregate and visualize data without a smart home server at all, Mathlab's ThingSpeak service is very helpful. 

 The Berry driver 'ThingSpeak' makes it easy to use ThingSpeak.

Find more [information](ReadmeThingSpeak.md)

