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

  -- Intervalos para piscada dos leds de cada modo
  local intervals = {
    normal = {500},
    fast = {200},
    loading = {400,2400},
    error1 = {200,200,1200,200,200,1000}, -- algo errado no disco dos minutos (60 divisoes)
    error2 = {200,200,1200,200,600,1000}, -- algo errado nos discos das horas (dois discos mais internos)
  }

  local piscaCtx = {
     modo = 'normal',
     idx = 1,
   }

  local function piscarTmr(timer) 
    if ledAceso then
       gpioOff()
    else 
       gpioOn()
    end
    timer:interval(intervals[piscaCtx.modo][math.min(piscaCtx.idx,#intervals[piscaCtx.modo])])
    piscaCtx.idx = piscaCtx.idx + 1
    if (piscaCtx.idx > #intervals[piscaCtx.modo]) then
      piscaCtx.idx = 1
    end
  end
  
  local piscaLedTimer = tmr.create() 
  piscaLedTimer:register(500, tmr.ALARM_AUTO, piscarTmr)

  local function piscar( modo )
    gpioOff()
    piscaLedTimer:stop()
    piscaCtx.modo = modo
    piscaCtx.idx = 1
    piscaLedTimer:interval(intervals[piscaCtx.modo][piscaCtx.idx])
    piscaLedTimer:start()
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
    --print("releasing led")
    piscaLedTimer:stop()
    piscaLedTimer:unregister()
  end

  led.on = on
  led.off = off
  led.piscar = piscar
  led.release = release

  led.status  = function ()
    return piscaCtx;
  end

  gpioOff()
  
end
