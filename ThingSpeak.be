#-----------------------------------
ThingSpeak - a component to consume the cloud services of Mathlab
-----------------------------------#

import string
import json
import math

class ThingSpeak: DynClass

    static MinWaitSeconds = 10
    static MaxWaitSeconds = 3600
    static MAP = {"field1":nil,"field2":nil,"field3":nil,"field4":nil,"field5":nil,"field6":nil,"field7":nil,"field8":nil}
    static httpUriPrefix = "https://api.thingspeak.com/update.json?api_key="

    var name
    var infoEnable
    var lastLogInfo
    var lastWarnInfo
    var lastLogProc

    var apiKey # for channel
    var uri
    var waitSecs
    var nextUpdMillis
    var client
    var anyField  # a helper flag
    var unitTest

    # log with level 'INFO'
    def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO "+self.name+"."+proc+" - "+info) end
    end

    # log with level 'WARN'
    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN "+self.name+"."+proc+" - "+info)
    end

    # add fields tu uri string
    def addFields()
        var cproc="addFields"

        var xmap = self.toMap()

        self.anyField=false

        for key : self.MAP.keys()
            # shortcut if value = nil
            var value = xmap[key]
            if value == nil
                continue
            end

            self.anyField=true
            self.uri += string.format("&%s=%s",key,value)
        end
    end

    # clear the values of the thingspeak-fields
    def clearFields()
        # clone the map
        var jstring = json.dump(self.MAP)
        var xmap = json.load(jstring)
        self.loadMap(xmap)
    end

    # build the uri with params for thingSpeak
    def buildUri()
        self.uri = self.httpUriPrefix+self.apiKey
        self.addFields()
        self.clearFields()
    end

    # write the field-valus to thingspeak-cloud
    def write()
        var cproc="write"
        var resp=200
   
        self.buildUri()
        if !self.anyField
            if self.infoEnable  self.info(cproc,"nothing to do") end
            return -1
        end

        if !self.unitTest
            self.client.begin(self.uri)
            resp = self.client.GET()
            self.client.close()
        end

        if self.infoEnable self.info(cproc,self.uri+" ret-code:"+str(resp)) end
        return resp
    end

    # is called every second by tasmota
    def every_second()
        var cproc="every_second"

        # check whether update has to be performed
        var millis = tasmota.millis()
        if millis >= self.nextUpdMillis
            self.nextUpdMillis = millis + self.waitSecs*1000
            self.write()
        end

    end

    # define the updates per hour
    def updatesPerHour(value)
        var cproc="updatesPerHour"
        var xval = 3600 / value
        if xval < self.MinWaitSeconds
            xval = self.MinWaitSeconds
        end

        if xval > self.MaxWaitSeconds
            xval = self.MaxWaitSeconds
        end   
        
        self.waitSecs=math.ceil(xval)
        self.info(cproc,str(self.waitSecs))
    end

    # constructor	
    def init(name)
        var cproc='init'

        if name==nil
            name="ThingSpeak"
        end
        self.name = name
        self.anyField=false
        self.apiKey = ""
        self.unitTest=false

        super(self).init()
        self.clearFields()

        self.updatesPerHour(60)
        self.nextUpdMillis=tasmota.millis() + 5000
        self.client = webclient()

        # uses tasmotas callback for second
        tasmota.add_driver(self)

        self.infoEnable = true
        self.info(cproc,"created ThingSpeak: "+name)
        self.infoEnable = false
    end

    # destructor
    def deinit()
        tasmota.remove_driver(self)
        self.info("deinit","done")
    end

end
