#-----------------------------------
dynamic class implementation
------------------------------------#
#@ solidify:DynClass
class DynClass
    var xmap

    def setmember(name, value)
        self.xmap[name] = value
    end

    def item(name)
        import undefined
        if ! self.xmap.contains(name) return undefined end;
        return self.xmap[name] 
    end

    def setitem(name,value)
        self.xmap[name] = value
    end

    def member(name)
        import undefined
        if self.xmap.contains(name)
            return self.xmap[name]
        else
            return undefined
        end
    end

    def contains(name)
        return self.xmap.contains(name)
    end

    # return members as json-string
    def toJson()
        import json
        return json.dump(self.toMap())
    end

    # load new members from json-string
    def loadJson(jsonString)
        import json
        var data = json.load(jsonString)
        self.loadMap(data)
    end
    
    # load a map into recursive Dynclass nodes
    def loadMap(vmap)

        # print("input value:",vmap)
        if !(type(vmap)=="instance" && classname(vmap)=='map')
            #print("is no map")
            return
        end

        #print("looping")
        self.xmap = vmap
        for key:self.xmap.keys()
            var xkey = key
            var data = self.xmap[xkey]
            #print(data)

            if (type(data)=="instance" && classname(data)=='map')
                #print("is nested")

                var dyno = DynClass()
                self.xmap[xkey]=dyno
                dyno.loadMap(data)
            end
        end
    end

    # convert DynClass into map
    def toMap(vmap)
        #print("0. Start with",vmap)
        if vmap==nil
            vmap=self.xmap
        end

        var ymap={}

        for key:vmap.keys()
            var xkey = key
            var data = vmap[xkey]
            #print("1. key:",key,":",data)

            if (type(data)=="instance" && classname(data)=='DynClass')
                #print("2a. is nested")
                var yy = self.toMap(data.xmap)
                ymap[xkey]=yy
            else
                #print("2b. not nested") 
                ymap[xkey]=data
            end
        end
        return ymap
    end
    
    def tostring()
        return str(self.toMap())
    end

    def init()
        self.xmap = {}
    end
end