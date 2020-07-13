print("loading rotary2020")
if (r and r.release)~=nil then 
  r.release()
end
r = {}
do

  require("app_led")
  require("motor")
  require("ponteiros")
  require("relogioInternet")

  require("app_wifi")

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
	-- TODO piscar LED rapidamente.
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
    if (ponteiros.GMIN()~=nil and rtcGMIN~=nil) then 
       -- calcula atraso ou adianto
       difGMIN = ponteiros.GMIN()-rtcGMIN
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
  if not ponteiroTimer:alarm(5*1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
  then  
      print("problemas no ponteiroTimer")
  end

  local function ponteirosOnChange(GMIN, ptrMin, ptrHora)

    local difGMIN = 0
    if (GMIN~=nil and rtc.GMIN()~=nil) then 
       -- calcula atraso ou adianto
       difGMIN = GMIN-rtc.GMIN()
       print("D-dif GMIN:" .. difGMIN)       
    end

    if isBuscaHora then
      if ptrHora ~= nil then
         motor.desligar()
         isBuscaHora = false
         ponteiroTimer:start()
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
    		end
    	end
    end
	print(ponteiros.toStr())
  end

  ponteiros.init( ponteirosOnChange )


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
  end
  
  local function buscarHoraCCW()
    ponteiroTimer:stop()
    motor.ligarCounterClockwise()
    isBuscaHora = true
  end

  local function release()
    ponteiroTimer:stop()
    ponteiroTimer:unregister()
    piscaLedTimer:stop()
    piscaLedTimer:unregister()
    print("r.release()")
  end

  r.zeromin = zeromin
  r.v = '1.0'
  r.minutoAlvo = getMinutoAlvo
  r.pausar = pausar
  r.continuar = continuar
  r.ponteirosOnChange = ponteirosOnChange
  r.release = release
  r.buscarHoraCW = buscarHoraCW
  r.buscarHoraCCW = buscarHoraCCW

end


