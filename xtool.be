#-----------------------------------
The static class  implements common functions
------------------------------------#

#@ solidify:xtool
xtool = module('xtool')


class XTool
    static BerryStyle='<style>table.berry {max-width:100%;table-layout: fixed;}table, th,td { border: 1px solid #f4f5f0; text-align: center; border-collapse: collapse;} </style>'

    var lastJsonResult 
    var lastIsBoolResult
    var lastIsNumberResult
    var lastLogProc
    var infoEnable
    var lastLogInfo
    var lastWarnInfo
    var rebootWeeklyActivated

    def init()
        self.infoEnable=false
        self.rebootWeeklyActivated=false
        tasmota.add_driver(self)
    end

    def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO xtool."..proc.." - "..info) end
    end    

    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN xtool."..proc.." - "..info)
    end

    #-
    function      checks whether value can be converted into a valid json
    return        true, if value is a valid json, false otherwise 
    -#
    def isJson(value)
        
        import json
        self.lastJsonResult = json.load(value)
        if classname(self.lastJsonResult)=='map'
            return true
        else
            return false
        end 
    end

    #-
        function      checks whether value can be converted to a bool value
        returns       true, if value is convertible to a bool, false otherwise 
    -#
    def isBool(value)
        import json
        import string

        self.lastIsBoolResult=nil

        if value==nil return false end

        var ss = string.format('{"value": %s}',string.tolower(str(value)))
        var data = json.load(ss)
    
        if data==nil return false end
    
        var xval = data["value"]
    
        if type(xval)  == 'bool'
            self.lastIsBoolResult =xval
            return true
        else
            return false
        end
    end   

    #-
    function      checks whether value can be converted to a number value
    return        true, if value is convertible to a number, false otherwise
    -#
    def isNumber(value)
        import json
        self.lastIsNumberResult = json.load(str(value))
        var xtype = type(self.lastIsNumberResult)
        var result = xtype == "int" || xtype == "real"
        return result
    end

    #-
    function      checks whether property defined in 'propName' exists in 'obj'
    returns        obj, if property was found, nil otherwise
    -#
    def mapCheckProp(obj,propName)
        if classname(obj) != "map"
            self.warn("mapCheckProp","no map")
            return nil
        end

        if !obj.contains(propName)
            return nil
        end

        return obj
    end

        #-
    function      tries to extract the value of key 'propname' from the map 'obj' as bool. 
    returns        property-value as bool, nil otherwise
    -#
    def mapGetBoolean(obj,propName)

        if self.mapCheckProp(obj,propName) == nil
            return nil
        end
    
        if type(obj[propName]) != "bool"
            self.warn("mapGetBoolean","wrong type")
            return nil
        end
    
        return obj[propName]
    end   

    #-
    function      tries to extract the the value of key 'propname' from the map 'obj' as number. 
    returns        property-value as number, nil otherwise 
    -#
    def mapGetNumber(obj,propName)

        if self.mapCheckProp(obj,propName) == nil
            return nil
        end
    
        var xvalue = obj[propName]
        if  !self.isNumber(xvalue)
            self.warn("mapGetNumber","wrong type")
            return nil
        end
    
        return self.lastIsNumberResult
    end  

     #-
    function      tries to extract the the value of key 'propname' from the map 'obj' as string. 
    returns       property-value as string, nil otherwise 
    -#
    def mapGetString(obj,propName)

        if self.mapCheckProp(obj,propName) == nil
            return nil
        end

        var xtype = type(obj[propName]) 
        if  xtype != "string"
            self.warn("mapGetString","wrong type")
            return nil
        end

        return obj[propName]    
    end
   
    #  calculates the dewpoint
    def calcDewpoint(temp,hum)
        import math

        var rf1 = 0.01 * hum
        var k1 = 0.124688
        var k2 = 109.8
        var s = math.pow(rf1,k1)
        var result = (s * (k2 + temp)) - k2
        return result
    end   

    # reboots at Sa at 09:00
    def rebootWeekly()
        var cproc="rebootWeekly"
        self.info(cproc,"will reboot weekly")

        # seconds minute hour day   month Weekday
        # 0-59    0-59   0-23 1-30  1-12  0 (So)-6(Sa)
        tasmota.remove_cron('weeklyRestart')

        tasmota.add_cron("0 0 9 * * 6",
            def()
            tasmota.cmd("restart 1")
            end
            ,'weeklyRestart') 
            self.rebootWeeklyActivated=true
    end

    #  function     callback for tasmota driver mimic
    #  installs in the static part of the main page the javaScript 'dola'
    def web_add_main_button()
        import webserver

        var cproc="web_add_main_button"
        self.info(cproc,"run")

        # javascript enhancement using function 'dola'
        var html='<script> function dola(t){let e=""==t.value?"1":t.value,l;la("&"+t.getAttribute("id")+"="+e)} </script>'
        webserver.content_send(html)
    end 


end

xtool.XTool = XTool

xtool.init = def (m)   
    import global
    global.xtool = m
    # return a single instance for this class
    return xtool.XTool()
end

# return the module as the output of import, which is eventually replaced by the return value of 'init()'
return xtool 