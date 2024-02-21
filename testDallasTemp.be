import string

# ------- TempDevice

var device = TempDevice()
assert(device.name,"??","td.1")
assert(device.offset==0,"td.2")
assert(device.hasError,"td.3")
assert(!device.stateReported,"td.4")
assert(!device.isPreDefined,"td.5")

assert(device.ignoreAfterError==2,"td.7")
assert(device.freezeOnError,"td.8")
assert(device.value==nil,"td.9")

device.setTemperature(33)
assert(device.value==nil,"td.9")

device.hasError=false
device.setTemperature(33)
assert(device.value==33,"td.10")

# freeze is still active
device.hasError=true
device.setTemperature(44)
assert(device.value==33,"td.11")

device.hasError=true
device.freezeOnError=false
device.setTemperature(44)

assert(device.value==44,"td.12")

device=nil

# -------- DallasTemp
# Init
gpioForOneWire = 23

dt = DallasTemp("OneWire.01",gpioForOneWire)
dt.infoEnable=true
assert(dt.name=="OneWire.01","dt.1")
assert(!dt.enabled,"dt.1a")
assert(dt.gpio==gpioForOneWire,"b.2")
assert(dt.reqState==0,"b.3")
assert(dt.reqWaiterMax==3,"dt.4")
assert(dt.reqWaiter==0,"b.5")
assert(dt.webArgPrefix=="owtemp","dt.6")
assert(size(dt.devices)==0,"dt.7")
assert(!dt.onJsonAppend,"tdtd.6")

# --- Register

# register a new device
var idAddress="28111BAA20220994"
var idBytes = bytes(idAddress)

device = dt.register(idAddress)
assert(size(dt.devices)==1,"b.1")
assert(device.address.tohex()==idAddress,"b.2")
assert(device.isPreDefined,"b.3")
assert(device.address.tohex()==idAddress,"b.4")
assert(device.name=="device-"+str(size(dt.devices)-1),"b.4")

# register same device again, no change expected
device = dt.register(idAddress)
assert(size(dt.devices)==1,"c.1")

# Clear devices, only valid vor non-registered devices
dt.clear()
assert(size(dt.devices)==1,"c.1")

# find device
device = dt.findDevice(idBytes)
assert(device.name=="device-"+str(size(dt.devices)-1),"d.1")

# set Error
var gotError=false
var gotDevice=nil

dt.onSensorStateChanged=def (dallas,device)
    gotDevice=device
  gotError=true
end

device.ignoreAfterError=0
dt.setError(device,false)
assert(!device.hasError,"e.1")
assert(gotError,"e.2")
assert(gotDevice==device,"e.3")

dt.setErrorAll()
assert(device.hasError,"e.4")

# --- start scan
assert(!dt.enabled,"f.0")
dt.startScan()
assert(dt.scanState==1,"f.1")
assert(dt.enabled,"f.2")
dt.enabled=false

# ------ CRC
dataOK =    bytes("43014B467FFF0C1079")
assert(dt.isCrcOK(dataOK),"g.1")

dataWrong = bytes("43014B467FFF0C1033")
assert(!dt.isCrcOK(dataWrong),"g.2")

dataWrong = bytes("43014B467FFF0")
assert(!dt.isCrcOK(dataWrong),"g.3")

# calculate temperature
gotTemp=nil
dt.onValueUpdate=def (dallas,device,temp)
    gotTemp=temp
    return temp
end


device.hasError=false
dt.scratchPad = dataOK
dt.calculateTemperature(device)
assert(string.format("%5.2f",device.value)=="20.19","h.1")
assert(gotTemp==device.value,"h.2")

# ------ json
dt.enableSensorMsg=false
assert(!dt.json_append(),"i.1")

dt.enableSensorMsg=true
assert(dt.json_append(),"i.2")

# "OneWire.01":{"gpio":23,"devices":[{"address":"28111BAA20220994","name":"device-0","value":20.1875,"hasError":true}]}
assert(string.find(dt.getJsonCommand(),"OneWire")>0,"i.2")

# ------ onJsonAppend

var jsString=""
dt.onJsonAppend = def(obj,jsonString)
   jsString=jsonString
end

dt.json_append()

assert(size(jsString)>=10,"i.10")

# --- cleanup

dt.deinit()
dt=nil
