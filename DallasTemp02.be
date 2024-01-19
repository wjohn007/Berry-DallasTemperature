# --- this script is processed, after components are created


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
    # var device = dallasTemp.devices[0]
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

#-  register existing devices

device = dallasTemp.register("28111BAA20220994") 
device.name = "myDevice.01"
-#
device = dallasTemp.register("28C9229E2022089E")
device.name = "myDevice.02"
device.offset = 0


# perform autoscan at start

# get more logging info
dallasTemp.infoEnable=true

# Enable enrichment of sensor message
dallasTemp.enableSensorMsg=true

# start sensor scan
dallasTemp.startScan()