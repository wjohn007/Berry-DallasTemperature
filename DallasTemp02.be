# --- this script is processed, after components are created

# ========== DallasTemp ==========

dallasTemp = DallasTemp("OneWire.Group.01",gpioForOneWire)
dallasTemp.infoEnable=true

part1=""
part2=""
dimension=""
html=""

dallasTemp.onBuildWebView = 
def()
  part1='<table class=berry><tbody><tr><th colspan=5>Temperatures</th></tr><tr><th>Name</th><th>Address</th><th>Is Fake</th><th>Offset [%s]</th><th>Valid</th><th>Value [%s]</th></tr>%s<tr><td><button id=owtemp_scan onclick=dola(this)>Scan 1-Wire-Bus</button></td><td><button id=owtemp_clear onclick=dola(this)>Clear list</button></td><td></td><td></td><td></td><td></td></tr></tbody></table>'
  var ssi='<tr><td><span>%s</span></td><td><span>%s</span></td><td><span>%s</span></td><td><span>%s</span></td><td><span>%s</span></td><td><span>%s</span></td></tr>'

  part2=""
  for device: dallasTemp.devices
    part2+=string.format(ssi ,
       device.name,
       str(device.address.tohex()),
       str(device.isFake()),
       str(device.offset),
       device.hasError ? "no": "yes",
       string.format("%5.2f",device.value))
  end

  var dimension = dallasTemp.useFahrenheit ? "°F" : "°C"
  html= string.format(part1 ,dimension,dimension,part2)
  return html
end

# -  register existing devices

device = dallasTemp.register("283039370600009B") 
device.name = "myDevice.01"
device.offset = 0
device.freezeOnError = true # default value is true

# get more logging info
dallasTemp.infoEnable=true

# Enable enrichment of sensor message
dallasTemp.enableSensorMsg=true

# start sensor scan
dallasTemp.startScan()

# ========== !!Thingspeak !!==========
# uncomment following area to test the ThingSpeak-component

#- 
# create an instance
thingSpeak = ThingSpeak()

# let us see the logs
thingSpeak.infoEnable=true

# !!! put here the 'Write Api KEY' from ThingSpeak 
thingSpeak.apiKey="your-api-key"

# limit the data-rate
thingSpeak.updatesPerHour(60)

# use the callback of dallasTemp fired, when all sensors are acquired
dallasTemp.onCollectingDone=def (dallasTemp)
  if device && !device.hasError && tool.isNumber(device.value)
     # this is all to do, write to field1 .. field8 the values of the channel
     thingSpeak.field1=device.value 
  end
end
-#


