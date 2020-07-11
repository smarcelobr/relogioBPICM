function startup()
    if file.open("rotary.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("rotary.lua")
        -- the actual application is stored in 'application.lua'
        dofile("rotary2020.lua")
    end
end

  local pinRotaryLED, pinMotor, pinMinuto, pinHora, pinStatusLED = 7, 6, 1, 2, 0

  gpio.mode(pinMinuto, gpio.INT, gpio.PULLUP)
  gpio.mode(pinHora, gpio.INT, gpio.PULLUP)
  gpio.mode(pinMotor, gpio.OUTPUT) 
  gpio.mode(pinRotaryLED,gpio.OUTPUT)
  gpio.mode(pinStatusLED,gpio.OUTPUT)
  
  -- desliga rele
  gpio.write(pinMotor, gpio.LOW)
  -- desliga rotary encoder
  gpio.write(pinRotaryLED,gpio.LOW)
  -- desliga LED
  gpio.write(pinStatusLED, gpio.HIGH)
  
uart.setup(0,115200,8,0,1,0)

file.remove('init.paused')
print("Digite rapidamente:")
print("file.rename('init.lua','init.paused')")
print("You have 10 seconds to abort")
print("Waiting...")
tmrStartup = tmr.create()
if not tmrStartup:alarm(10*1000, tmr.ALARM_SINGLE, startup) -- 10 segundos
then  
    print("init.lua: Problemas no tmrStartup")
end
