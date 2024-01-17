#  Name		DallasTempBase.be

import string
import json
import undefined

class TempDevice 
    var address
    var offset
    var value

    var hasError
    var name
    var stateReported
    var isPreDefined
    var ignoreAfterError

    def setTemperature(value)
        self.value = value + self.offset
    end

    def init()
        self.hasError=false
        self.name="??"
        self.offset=0
        self.hasError = true
        self.stateReported = false
        self.isPreDefined = false
        self.ignoreAfterError = 2
    end
end

class DallasTempBase

    static IGNORE_AFTER_ERROR = 2

    static DSROM_FAMILY =0
    static DSROM_CRC = 7

    static DS18S20MODEL = 0x10  # also DS1820
    static DS18B20MODEL = 0x28  # also MAX31820
    static DS1822MODEL  = 0x22
    static DS1825MODEL  = 0x3B  # also MAX31850

    # OneWire commands
    static STARTCONVO      = 0x44  # Tells device to take a temperature reading and put it on the scratchpad
    static COPYSCRATCH     = 0x48  # Copy scratchpad to EEPROM
    static READSCRATCH     = 0xBE  # Read from scratchpad
    static WRITESCRATCH    = 0x4E  # Write to scratchpad
    static RECALLSCRATCH   = 0xB8  # Recall from EEPROM to scratchpad
    static READPOWERSUPPLY = 0xB4  # Determine if device needs parasite power
    static ALARMSEARCH     = 0xEC  # Query bus for devices with an alarm condition

     # Scratchpad locations
    static TEMP_LSB        = 0
    static TEMP_MSB        = 1
    static HIGH_ALARM_TEMP = 2
    static LOW_ALARM_TEMP  = 3
    static CONFIGURATION   = 4
    static INTERNAL_BYTE   = 5
    static COUNT_REMAIN    = 6
    static COUNT_PER_C     = 7
    static SCRATCHPAD_CRC  = 8

    static RuleTempOffset = 2
    static RuleSO8 = 3

    var gpio
    var webArgPrefix
    var enabled
    var enableSensorMsg
    var familySupported
    var devices
    var scratchPad

    var lastLogInfo
    var lastWarnInfo
    var lastLogProc
    var infoEnable

    var ow
    var scanState
    var reqState
    var reqWaiter
    var reqWaiterMax
    var scanResult
    var name

    var tempOffsetDefault
    var useFahrenheit

    #- called after all registered sensors are collected
       def (obj)
    -#
    var onCollectingDone

    #- called after sonsor state has changed (e.g. CRC error)
      def (DallasTemp,TempDevice)
    -#
    var onSensorStateChanged

    #-
    callback          callback when web view has to be updated
    para              (webserver)
    return            html content
    -#  
    var onBuildWebView 

    #-
    callback          callback if value is updated
    para              (dallasTemp,device,value)
    return            the value to be set
    -# 
    var onValueUpdate

    # log with level INFO
    def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO "+self.name+"."+proc+" - "+info) end
    end

    # log with level WARN
    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN "+self.name+"."+proc+" - "+info)
    end

    # checks the power supply
    # return 0xff if power is not parasit, otherwise 0x00
    def readPowerSupply(device)
        var cproc="readPowerSupply"
        var anyExists =  self.ow.reset()

        if !anyExists
            self.warn(cproc,"not any device on bus")
            return 0
        end

       # Berry: `select(bytes) -> nil`
       self.ow.select(device.address)
       self.ow.write(self.READPOWERSUPPLY);

       var result = self.ow.read();
       var value = result[0]

       # if (_wire->read_bit() == 0)
	   #	parasiteMode = true;
       self.ow.reset()

       self.info(cproc,result.tohex())
       return value
    end

    # find the device using the address
    def findDevice(idBytes)
        var cproc="findDevice"

        var foundDevice = nil
        var idBytesString = idBytes.tohex()
        self.info(cproc,"try to find device:"+idBytesString)

        for device:self.devices
            if device.address.tohex() == idBytesString
                self.info(cproc,"device found")
                return device
            end
        end

        self.info(cproc,"device not found")
        return
    end

    # create new device
    def newDevice(idBytes)
        var device = TempDevice()
        device.address = idBytes
        device.name = "device-"+str(size(self.devices))

        self.devices.push(device)
        return device
    end

    # clear all devices, that are not registered
    def clear()
        var cproc="clear"

        # self.devices.clear()
        var devices=self.devices

        var i = 0	
        while i < size(devices)
            var device = devices[i]
            if !device.isPreDefined
                self.info (cproc," remove ",device.name)
                devices.remove(i)
            else
                i += 1
            end
        end 
        self.info(cproc,"done")
    end

    #-
    register a temp-device with sensorID
    return: the cound/created TempDevice
    -# 
    def register(sensorIdString,isScan)
        var cproc="register" 
    
        isScan = isScan == true
        var idBytes = bytes(sensorIdString)
        var device = self.findDevice(idBytes)

        # sensor not exists
        if !device
            device = self.newDevice(idBytes)
            # predefines are not possible from scan
            device.isPreDefined=!isScan
            device.offset = self.tempOffsetDefault
            self.info(cproc,"new device:"+sensorIdString+" predefined:"+str(device.isPreDefined)) 
        else
            # sensor exists and no scan
            if !isScan
                device.isPreDefined=true
            end
            self.info(cproc,"device already exists:"+sensorIdString+" predefined:"+str(device.isPreDefined)) 
        end

        return device      
    end

    #  request the sensors for conversion , needs < 800 millis
    def requestTemperatures()
        self.ow.reset();
        self.ow.skip();
        self.ow.write(self.STARTCONVO);
    end

    # returns the state of the instance as json-string
    def getJsonAppend()

        var dyn = DynClass()
        dyn.gpio = self.gpio
        dyn.devices = []

        for device : self.devices
            var xdev = DynClass()
            xdev.name = device.name
            xdev.address = device.address.tohex()
            xdev.value = device.value
            xdev.hasError = device.hasError

            dyn.devices.push(xdev.toMap())
        end

        var ss = dyn.toJson()
        return ss
    end	

    def getJsonCommand()
        return string.format('"%s":%s', self.name, self.getJsonAppend())
    end

    # callback from tasmota driver manager
    def json_append()
        var cproc='json_append'
        if !self.enableSensorMsg return false end
        # var ss = self.getJsonTeleperiod()
        var ss=string.format("," + self.getJsonCommand())
        if ss 
            tasmota.response_append(ss) 
            return true
        end
        return false
    end

    # destructor
    def deinit()
        var cproc="deinit"

        if self.ow
            self.ow.deinit()
        end
        
        tasmota.remove_rule("TempOffset",self.RuleTempOffset)
        tasmota.remove_rule("SetOption8",self.RuleSO8)

        self.warn(cproc,"done")
    end

    # constructor
	def init(name,gpio)
		var cproc="init"

        self.name=name
        if !self.name  self.name="Dallas" end

        self.gpio = gpio
        self.enabled = false
        self.enableSensorMsg=false
        self.scanState = 0
        self.ow = OneWire(self.gpio)

        self.familySupported=[self.DS18B20MODEL]
        self.devices=[]
        self.reqState = 0
        self.reqWaiterMax = 3
        self.reqWaiter = 0 
        self.webArgPrefix = "owtemp"

        self.infoEnable = true
        self.info(cproc,"DallasTemp created using GPIO:" + str(self.gpio))
        self.infoEnable = false	

        #-
        tasmota.add_rule("TempRes",   
            def(value,topic) if value!=nil self.tempRes = value end end
            , self.RuleTempRes)
        -#

        tasmota.add_rule("TempOffset",
            def(value,topic) if value!=nil self.tempOffsetDefault = value end end
           , self.RuleTempOffset)

        tasmota.add_rule("SetOption8",  
            def(value,topic) self.useFahrenheit = tasmota.get_option(8)==1 end
            , self.RuleSO8)

        # trigger all rules
        tasmota.cmd("Backlog TempOffset; so8")
	end	
end
