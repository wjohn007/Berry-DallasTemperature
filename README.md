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

## Motivation

I attach great importance to stable error detection. 

Unfortunately, the power-on-reset value of the sensor with the value 85 is not clear.</br>
The application tries to eliminate this disadvantage.

If a sensor is used in an application, its status must be signaled even if it is not connected.</br>
The registration method takes this requirement into account.


## Different Scenes

After start of application without connected sensors

- sensores are connected but no bus-scan has done

![Scene-01](images/scene01.png)


After bus-scan has performed

![Scene-02](images/scene02.png)


After sensor's device-0 data-pin is yanked

![Scene-02](images/scene03.png)

## How to install

Default GPIO 16 is used. You can adjust this setting in file 'DallasTemp01.be'
Do not configure the used GPIO in menu 'Configuration/Configure Module'.


- upload following files to to the tasmota-controller
    - DallasTemp.app
    - DallasTemp01.be
    - DallasTemp02.be
  
- Restart the controller

After that the "After start of application" scene should be visible.

### Registered vs. temporary sensors

A sensor is registered via its address.
    - the application is constantly trying to read values ​​from this sensor
    - it cannot be deleted from the list of sensors to be detected.

### Button 'Scan'

Initiates the Bus-Scanning process, that collects the available devices.

### Button 'Clear list'

All temporary sensors will be cleared in the task list, but never those sensors, which are registered.

```be
device = dallasTemp.register("28C9229E2022089E")
device.name = "myDevice.02"
device.offset = 1
```



### Enable Logging

The berry-variable 'dallasTemp' is global.

Use following statement in the Berry-Console to obtain more log-information.

```be
    dallasTemp.infoEnable=true
```

### Enable/disable enrichment of the sensor message tele/.../SENSOR

```be
    dallasTemp.enableSensorMsg=true
```

If 'enableSensorMsg' is activated then the sensor messages will be extended like

```json
 {
	"Time": "2024-01-16T18:42:21",
	"ANALOG": {
		"Illuminance1": 0
	},
	"OneWire.Group.01": {
		"gpio": 16,
		"devices": [
			{
				"address": "28C9229E2022089E",
				"name": "Boiler Temperature",
				"value": 33.0,
				"hasError": false
			}
		]
	},
	"TempUnit": "C"
}     
```

### Fault detection

- the application detects the error when GND/Power/Data pin is error.In this case, the status “hasError” is set to “true”.
- After an error detection, 2 consecutive valid values ​​are required to reset the hasError flag.