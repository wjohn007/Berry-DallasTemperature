# autoexec.be is automatically loaded at startup
import string

appName="DallasTemp"

# tasmota.wd is only valid at startup step
tasmotawd = tasmota.wd

# needed to import modules located in tapp file
def push_path()
    import sys
    var p = tasmotawd
    var path = sys.path()
    if path.find(p) == nil
      path.push(p)
    end
  end

def xload(name,useRoot)
    var result=false

    if useRoot
      result = load(name)
    else
      result = load(tasmotawd + name)
    end

    print("loaded",name," with result:"+str(result))   
end

print("autoexec - start with app-file:"+tasmotawd)

# change to path where tapp files are located
push_path()

# no import your one module which is part of the tapp-file
# this is the first time loaded in cache, so following 'import' commands can work
import xtool

# define types
xload("git.be")
xload("A01DynClass.be")
xload("ThingSpeak.be")
xload("DallasTempBase.be")
xload("DallasTemp.be")

# define global variables
xload("configure01.be")

# loader user's input and adjustings 
xload(appName+"01.be",true)

# shortcut for test device
hostname=tasmota.cmd("status 5")['StatusNET']['Hostname']
 
# shortcut for test device
isTestController = (hostname == "tasmota-AC2638-1592") || (hostname == "tasmota-635C38-7224") || (hostname == "tasmota-ke1-klappe-5312")
if isTestController
  return
end

xload("configure02.be")

# settings after initializations
xload(appName+"02.be",true)


