print("loading app_led")
if led and led.release then
  led.release()
end  
led = {}
do

  local pinStatusLED = 0

  gpio.mode(pinStatusLED,gpio.OUTPUT)

  local ledAceso = false

  local function gpioOff()
    gpio.write(pinStatusLED,gpio.HIGH)
    ledAceso = false
  end

  local function gpioOn()
    gpio.write(pinStatusLED,gpio.LOW)
    ledAceso = true
  end

  gpioOn()

  local piscaCtx = {
     modo = 'normal',
     idx = 1,
     intervals = {
       normal = {500},
       fast = {200},
       loading = {400,2400},
       error = {1200,200,200,200}
     }
   }

  local function piscarTmr(timer) 
    if ledAceso then
       gpioOff()
    else 
       gpioOn()
    end
    piscaCtx.idx = piscaCtx.idx + 1
    if (piscaCtx.idx > #piscaCtx.intervals[piscaCtx.modo]) then
      piscaCtx.idx = 1
    end
    timer:interval(piscaCtx.intervals[piscaCtx.modo][piscaCtx.idx])
  end
  
  local piscaLedTimer = tmr.create() 
  piscaLedTimer:register(500, tmr.ALARM_AUTO, piscarTmr)

  local function piscar( modo )
    gpioOff()
    piscaLedTimer:stop()
    piscaCtx.modo = modo
    piscaCtx.idx = 1
    piscaLedTimer:interval(piscaCtx.intervals[piscaCtx.modo][piscaCtx.idx])
    if not piscaLedTimer:start()
    then  
        print("problemas no piscaLedTimer")
    end    
  end

  local function off()
    piscaLedTimer:stop()
    gpioOff()
  end

  local function on()
    piscaLedTimer:stop()
    gpioOn()
  end

  local function release()
    print("releasing led")
    piscaLedTimer:stop()
    piscaLedTimer:unregister()
  end

  led.on = on
  led.off = off
  led.piscar = piscar
  led.release = release

  gpioOff()
  
end