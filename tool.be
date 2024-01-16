#-----------------------------------
The module 'tool' impelments common functions
------------------------------------#
import json
import string
import webserver

tool = module("tool")

tool.init = def (m)

    class Tool
        static BerryStyle='<style>table.berry {max-width:100%;table-layout: fixed;}table, th,td { border: 1px solid #f4f5f0; text-align: center; border-collapse: collapse;} </style>'

        var lastIsNumberResult
        var lastJsonResult
        var lastLogInfo
        var lastWarnInfo
        var lastLogProc
        var infoEnable

        def init()
            self.infoEnable = false
            tasmota.add_driver(self)
        end

        def info(proc,info)
            self.lastLogProc = proc
            self.lastLogInfo = info
            if self.infoEnable print("INFO "+"Tool."+proc+" - "+info) end
        end

        def warn(proc,info)
            self.lastLogProc = proc
            self.lastWarnInfo = info
            print("WARN "+"Tool."+proc+" - "+info)
        end

        #-
        function      checks whether value can be converted to a bool value
        returns       true, if value is convertible to a bool, false otherwise 
        -#
        def isBool(value)
            return type(value)=='bool'
        end

        #-
        function      checks whether value can be converted to a number value
        return        true, if value is convertible to a number, false otherwise
        -#
        def isNumber(value)
            self.lastIsNumberResult = json.load(str(value))
            var xtype = type(self.lastIsNumberResult)
            var result = xtype == "int" || xtype == "real"
            return result
        end

        #-
        function      checks whether value can be converted into a valid json
        return        true, if value is a valid json, false otherwise 
        -#
        def isJson(value)
            self.lastJsonResult = json.load(value)
            if classname(self.lastJsonResult)=='map'
                return true
            else
                return false
            end 
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


        #  function     callback for tasmota driver mimic
        #  installs in the static part of the main page the javaScript 'dola'
        def web_add_main_button()
            var cproc="web_add_main_button"
            self.info(cproc,"run")

            # javascript enhancement using function 'dola'
            var html='<script> function dola(t){let e=""==t.value?"1":t.value,l;la("&"+t.getAttribute("id")+"="+e)} </script>'
            webserver.content_send(html)
	    end        
    end

    # return a single instance for this class
    return Tool()
end

# return the module as the output of import, which is eventually replaced by the return value of 'init()'
return tool 
