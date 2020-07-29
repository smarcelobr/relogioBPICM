print("loading rotary2020")
if (r and r.release)~=nil then 
  r.release()
end
r = {}
do

  require("motor")
  motor.desligar()
  require("util")
  require("app_led")
  require("app_wifi")
  require("gdate")
  require("relogioInternet")
  require("encoder")
  require("telnet"):open()
--  require("rotarysvc").init()

  led.piscar("loading")

  -- conecta no WIFI para pegar a hora
	
  local falhaMotor = false
  local pausado = false
  local minutoAlvo = nil
  local isBuscaHora = false
	
  local function falhouMotor()
	-- entra em modo de falha.
	print("Falha motor/encoder nao responde.")
	motor.desligar()
	falhaMotor = true
	led.piscar("error")
  end

  local function calcDif(gmin1, gmin2) 
    -- se +, roda ccw para ajuste
    -- se -, roda cw para ajuste
    local difs = {gmin1-gmin2,
                  gmin1-(720+gmin2),
                  (gmin1+720)-gmin2
                  }

    local menorDif = difs[1]
    for i,dif in ipairs(difs) do
      if math.abs(menorDif) > math.abs(dif) then
        menorDif = dif
      end
    end
    return menorDif
  end

  local function acionaPonteiro(ptrTimer)
    print('ptrTimer')

    local rtcGMIN, newSec = rtc.GMIN()

    if (newSec ~= nil) then
      local newInterval = math.max( (60-newSec) , 5)*1000
      print("newInterval=" .. newInterval)
      ptrTimer:interval(newInterval)
    end
       
    
    local difGMIN = -1
    if (encoder.GMIN()~=nil and rtcGMIN~=nil) then 
       -- calcula atraso ou adianto
       difGMIN = calcDif(encoder.GMIN(), rtcGMIN)
       print("L-dif GMIN:" .. difGMIN)       
    end
    
	-- testa se ha uma falha mecanica 
	-- (chegou o proximo minuto sem desligar o motor)
	if not falhaMotor then
      if (not pausado) then 
        if (difGMIN < 0) then -- esta atrasado ou certo?
          print('cw')
          motor.ligarClockwise()
          
        else
          if (difGMIN > 0) then
            print('ccw')
            motor.ligarCounterClockwise()
          end
        end
      end
	end
  end

  -- aciona o ponteiro a cada minuto do raspberry
  local ponteiroTimer = tmr.create() 
  if not ponteiroTimer:alarm(60*1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
  then  
      print("problemas no ponteiroTimer")
  end

  local function encoderOnChange(GMIN, ptrMin, ptrHora)

    local difGMIN = 0
    if (GMIN~=nil and rtc.GMIN()~=nil) then 
       -- calcula atraso ou adianto
       difGMIN = calcDif(GMIN, rtc.GMIN())
       print("D-dif GMIN:" .. difGMIN)       
    end

    if isBuscaHora then
      if ptrHora ~= nil then
         print("Hr def.")
         motor.desligar()
         isBuscaHora = false
         ponteiroTimer:start()
         led.piscar("normal")
      end
    else
        if (ptrMin == (minutoAlvo or ptrMin)) then
            if (difGMIN == 0) then
      		  motor.desligar()
            end
    		if (minutoAlvo) then
    		  -- atingiu o objetivo, limpa o alvo para voltar ao normal
    		  minutoAlvo = nil
              motor.desligar()
              ponteiroTimer:start()
              led.piscar("normal")
    		end
    	end
    end
	  print(encoder.ptr.toStr())
  end

  encoder.init( encoderOnChange )


  -- move o ponteiro ate chegar ao minuto zero
  local function zeromin() 
    ponteiroTimer:stop()
    minutoAlvo = 0
	acionaPonteiro()
  end

  local function getMinutoAlvo()
    return minutoAlvo
  end

  local function pausar()
    pausado = true
  end

  local function continuar()
    pausado = false
  end

  local function buscarHoraCW()
    ponteiroTimer:stop()
    motor.ligarClockwise()
    isBuscaHora = true
    led.piscar("fast")
  end
  
  local function buscarHoraCCW()
    ponteiroTimer:stop()
    motor.ligarCounterClockwise()
    isBuscaHora = true
    led.piscar("fast")
  end

  local function release()
    ponteiroTimer:stop()
    ponteiroTimer:unregister()
    print("r.release()")
  end

  r.zeromin = zeromin
  r.v = '1.0'
  r.minutoAlvo = getMinutoAlvo
  r.pausar = pausar
  r.continuar = continuar
  r.encoderOnChange = encoderOnChange
  r.release = release
  r.buscarHoraCW = buscarHoraCW
  r.buscarHoraCCW = buscarHoraCCW

  buscarHoraCW()

end