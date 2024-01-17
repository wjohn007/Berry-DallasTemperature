#-----------------------------------
Name		DallasTemp.be
Task 		dealing with dallas temperature sensor DS18B20 using oneWire.

only DS18B20 types are tested
only non parasite mode is tested
multiple sensors are supported
crc8 check is implemented
-----------------------------------#
import string
import webserver

class DallasTemp : DallasTempBase

    #-
        calculate temperature using scratchpad data.
        temperature is written into tempDevice-structure
    -#
    def calculateTemperature(tempDevice)
        var cproc="calculateTemperature"

        var msb = self.scratchPad[self.TEMP_MSB]
        var lsb = self.scratchPad[self.TEMP_LSB]
        var raw = (msb << 8) | lsb

        # perform 2-complement, if sign-flag is true
        if msb & 0x80
            raw =  (raw ^ 0xffff)+1
        end
    
        var temp = raw / 16.0

        if self.useFahrenheit
            temp = temp * 1.8 + 32 
        end

        # check if callback is required
        if self.onValueUpdate
            try
                var newTemp = self.onValueUpdate(self,tempDevice,temp)
                if newTemp !=nil
                    temp = newTemp
                end
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end   
        end

        tempDevice.setTemperature(temp)

        if self.infoEnable
            self.info(cproc,"temperature:"+str(tempDevice.value)+" device:"+tempDevice.name)
        end  
    end

    #-
    Checs the CRC of the scratchpad data
    - scratchpad has 9 bytes, last one holds the crc from sensor
    - byte 1-8 are used to calculate the crc

    return : true, if crc is ok  
    -#
    def isCrcOK(scratchpad)
        var cproc="isCrcOK"

        var ssize = size(scratchpad)
        if ssize != 9
            self.warn(cproc,"wrong count of bytes")
            return false
        end

        var crc = 0
        var sensorCrc = scratchpad[ssize-1]
    
        var ilast = ssize-2   

        # loop over 8 bytes of scratchpad
        for i: 0 .. ilast
    
            var inbyte = scratchpad[i]
            # print("inbyte:",inbyte)
    
            # loop over 8 bits of each byte
            for bit : 1..8
                # perform xor
                var mix = (crc ^ inbyte) & 0x01
                crc = crc >> 1
    
                if mix
                    crc = crc ^ 0x8C  # 1000 1100   X8 + X5 + X4 + 1
                end
    
                inbyte = inbyte >> 1
            end
        end
    
        if  crc == sensorCrc
            return true
        else
            self.warn(cproc,"CRC-error sensor-crc:"+string.hex(sensorCrc)+" calced crc:"+string.hex(crc)+" "+scratchpad.tohex())
            return false
        end
    end

    #-
    reads the data from the sensor 'scratchPad'.
    if device is not available scratchPad is filled up with FF

    return: 1=OK, 0= no device on bus, -1 = CRC error, -2 only zero, -3 only FF
    -#
    def readScratchPad(device)
        var cproc="readScratchPad"
        
        var anyExists =  self.ow.reset()
        var onlyZero = true
        var onlyFF = true

        if !anyExists
            return 0
        end

        # Berry: `select(bytes) -> nil`
        self.ow.select(device.address)
        self.ow.write(self.READSCRATCH);
        self.scratchPad = bytes("000102030405060708")

        for i: 0 .. 8
            var result = self.ow.read();
            var value = result[0]
            self.scratchPad[i] = value
            if value!=0
                onlyZero=false
            end
            if value!=0xff
                onlyFF=false
            end
        end

        self.ow.reset()

        var erg = 1 
        var info=""

        if onlyFF
            erg = -3
            info = "only 0xff values"

        elif onlyZero
            erg = -2
            info = "only 0x00 values"
            
        elif  !self.isCrcOK(self.scratchPad)   
            erg = -1
            info = "crc error"
        end 

        self.info(cproc,"scratchPad:"+self.scratchPad.tohex()+" return:"+str(erg)+" - "+info)
        return erg
    end

    #-
    scan the devices on bus
    - this method is cyclically called by 1 second
    - state 0:  do nothing
    - state 1:  initiates a search for devices on bus
    - state 2:  process scan result
    -#
    def scan()
        var cproc="scan"

        # state = 0
        if self.scanState==0
            return
        end

        # state=1 : initiate a search for devices
        if self.scanState == 1

            self.info(cproc,"initiate search")
            self.ow.reset_search()
            self.scanState = 2
            return
        end

        # state=2 : check the search results
        if self.scanState == 2
            self.info(cproc,"check search results")

            self.scanResult= self.ow.search()

            # we got a result
            if self.scanResult!=nil

                # only known device-types are supported
                var code=self.scanResult[self.DSROM_FAMILY]
                if self.familySupported.find(code) !=nil
                    self.info(cproc,"found device :" + self.scanResult.tohex())  

                    self.register(self.scanResult.tohex(),true)
                else  
                    self.info(cproc,"found unsupported device:"+self.scanResult.tohex())    
                end

            # no scan-result, so we are done
            else
                self.info(cproc,"finish scanning")
                self.scanState = 0
            end
            return
        end
    end

    #-
    starts the scan of devices on 1-wire bus
    -#
    def startScan()
        var cproc="startScan"
        self.scanState=1
        self.enabled=true
        self.info(cproc,"scan started")
    end
    
    # set the error state of a device
    # a reset need multiple valid values
    def setError(device,hasError)
        var cproc="setError"

        var errorChanged = device.hasError != hasError

        if errorChanged
            if hasError 
                device.hasError=hasError
                self.warn(cproc,"error detected for device:"+device.address.tohex())
                device.ignoreAfterError = self.IGNORE_AFTER_ERROR
            else
                if device.ignoreAfterError >0 
                    device.ignoreAfterError = device.ignoreAfterError-1
                    errorChanged=false
                    self.info(cproc,"decrement error counter:"+device.address.tohex()) 
                else
                    device.hasError=hasError
                    self.info(cproc,"error reset for device:"+device.address.tohex()) 
                end
            end
        end

        if errorChanged || !device.stateReported
            device.stateReported = true
            if self.onSensorStateChanged
                try
                    self.onSensorStateChanged(self,device)
                except .. as exname, exmsg
                    self.warn(cproc, exname + " - " + exmsg)
                end   
            end
        end
    end

    def setErrorAll()
        for device : self.devices
            self.setError(device,true)
        end
    end

    #-
    collects the temperature value from registered sensors
    -#  
    def collect()
        var cproc="collect"

        if self.reqWaiter <= 0

            # state 0 : request temperature from sensors
            if self.reqState == 0 && size(self.devices)>0 
                self.reqState = 1
                self.requestTemperatures()
                self.info(cproc,"request temperature")
                self.reqWaiter = self.reqWaiterMax   

            # state 1 :  calculate the temperatures
            elif self.reqState == 1
                var loopDone = false

                self.reqState = 0
                self.info(cproc,"start read process")

                for device : self.devices
                    var error=false
                    var powerIsOk = false

                    var readResult = self.readScratchPad(device)

                    # if OK then check power supply
                    if readResult==1
                        powerIsOk = self.readPowerSupply(device) == 0xff
                    end

                    if !powerIsOk         # wrong power-supply leads to wrong values
                        self.setErrorAll()
                        self.warn(cproc," read power-supply is bad, ignore value")
                        break

                    elif readResult==1         # value is valid             
                        self.calculateTemperature(device)  

                    elif readResult == 0 # no device on bus
                        self.warn(cproc,"no devices on bus")
                        self.setErrorAll()
                        break

                    elif readResult == -1
                        self.warn(cproc,"got CRC error")
                        error = true

                    elif readResult == -2
                        self.warn(cproc,"only 0x00 error")
                        error = true   

                    elif readResult == -3
                        self.warn(cproc,"only 0xff error")
                        error = true        
                    end

                    self.setError(device,error)
                    loopDone=true
                end

                # at least one device exists on bus
                if loopDone  && self.onCollectingDone 
                    try
                        self.onCollectingDone(self)
                    except .. as exname, exmsg
                        self.warn(cproc, exname + " - " + exmsg)
                    end                    
                end

                self.reqWaiter =self.reqWaiterMax 
            end
        else
            self.reqWaiter = self.reqWaiter-1
        end
    end

    # called every second by tasmota
    def every_second()
        if self.enabled
            self.scan()
            self.collect()
        end
    end
    
    #  function     callback for tasmota driver mimic
    def web_sensor()
        var cproc="web_sensor"

        var paraName=self.webArgPrefix + "_scan"
        if webserver.has_arg(paraName)  
            self.info(cproc,"got command:"+paraName) 
            self.startScan()
        end

        paraName=self.webArgPrefix + "_clear"
        if webserver.has_arg(paraName)  
            self.info(cproc,"got command:"+paraName) 
            self.clear()
        end

        # update web-view for this instance
        if self.onBuildWebView != nil
            try
                var html=tool.BerryStyle
                html += self.onBuildWebView()
                webserver.content_send(html)
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end   
        end
    end

    def deinit()
        tasmota.remove_driver(self)
        super(self).deinit()
    end

    def init(name,gpio)
        var cproc="init"

        super(self).init(name,gpio)
        tasmota.add_driver(self)
    end
end
