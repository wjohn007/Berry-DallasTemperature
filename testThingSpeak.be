# ------ tetsts for ThingSpeak component

import tool
import string

# check basics

var bc = ThingSpeak()
bc.unitTest=true
assert(!bc.infoEnable,"a.02")

bc.infoEnable=true
bc.apiKey="KEY"

assert(bc.name=="ThingSpeak", "a.01")
assert(bc.nextUpdMillis>0,"a.03")
assert(bc.client!=nil,"a.04")
assert(bc.waitSecs == 3600/60,"a.05")

# ------- check fields 
# https://api.thingspeak.com/update.json?api_key=KEY&field1=1

bc.field1 = 1
bc.buildUri()
assert(bc.field1 == nil, "b.01")
assert(string.find(bc.uri,"field1=1")>0, "b.02")
assert(string.find(bc.uri,"api_key=KEY")>0, "b.03")

bc.field1 = 1
bc.field2 = 2
bc.field3 = 3
bc.field4 = 4
bc.field5 = 5
bc.field6 = 6
bc.field7 = 7
bc.field8 = 8
# this is added but never used, and removed after a write()
bc.field9 = 9
bc.buildUri()
assert(string.find(bc.uri,"field1=1")>0, "b.05.1")
assert(string.find(bc.uri,"field2=2")>0, "b.05.2")
assert(string.find(bc.uri,"field8=8")>0, "b.05.8")
assert(bc.field8 == nil, "b.06")

# ------- check updatesPerHour 
bc.updatesPerHour(1)
assert(bc.waitSecs == 3600,"c.01")

bc.updatesPerHour(6)
assert(bc.waitSecs == 600,"c.02")

bc.updatesPerHour(7)
assert(bc.waitSecs == 514,"c.03")

# limit to MinWaitSeconds
bc.updatesPerHour(3600)
assert(bc.waitSecs == bc.MinWaitSeconds,"c.03")

# limit to MaxWaitSeconds
bc.updatesPerHour(0.1)
assert(bc.waitSecs == bc.MaxWaitSeconds,"c.04")


# ------- write
bc.field1 = 1
bc.field2 = 2
assert(bc.write()==200,"d.01")
assert(bc.write()==-1,"d.02")

bc.nextUpdMillis=0
bc.field1 = 1
bc.every_second()
assert(bc.field1 == nil, "d.03")

# ===== housekeeping
bc.deinit()
bc=nil


#- playground

var thingSpeak = ThingSpeak()
thingSpeak.unitTest=true
thingSpeak.infoEnable=true
thingSpeak.updatesPerHour(240)
thingSpeak.apiKey="xxx"


thingSpeak.field1 = 50

# wait a minute here

thingSpeak.deinit()
-#


