r = {}
do
	local pinStatusLED = 0

    gpio.mode(pinStatusLED,gpio.OUTPUT)
	gpio.write(pinStatusLED,gpio.LOW)

  local motor = require("motor")
  local ponteiros = require("ponteiros")
  local relogioInternet = require("relogioInternet")
	
  -- conecta no WIFI para pegar a hora
  wifi.sta.disconnect()
  wifi.eventmon.register( wifi.eventmon.STA_CONNECTED, relogioInternet.wifiOnConnect )
  wifi.setmode(wifi.STATION)
  wifi.sta.autoconnect(0) -- desabilita a conexão automatica  
  
  local station_cfg={}
  station_cfg.ssid="jardimdomeier"
  station_cfg.pwd="sergioeluciene"
  station_cfg.save=true

  wifi.sta.config(station_cfg)

  -- agora tenta conectar no wifi
  wifi.sta.connect()
	
  local falhaMotor = false
  local minutoAlvo = nil
	
  local function falhouMotor()
	-- entra em modo de falha.
	print("Falha motor/encoder nao responde.")
	motor.desligaMotor()
	falhaMotor = true
	-- TODO piscar LED rapidamente.
  end

  local function acionaPonteiro()
    print('minuto timer')
	-- testa se há uma falha mecanica 
	-- (chegou o próximo minuto sem desligar o motor)
	if not falhaMotor then
		if (not minutoAlvo) and motor.emMovimento() then
			-- o motor está em movimento desde o ultimo minuto... entra em modo de falha
			falhouMotor()
		else 
			motor.ligaMotor()
		end
	end
  end

  -- aciona o ponteiro a cada minuto do raspberry
  local ponteiroTimer = tmr.create() 
  if not ponteiroTimer:alarm(60*1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
  then  
      print("problemas no ponteiroTimer")
  end

  local function ponteirosOnChange(ptrMin, ptrHora, flag)
    if ptrMin == (minutoAlvo or ptrMin) then
		motor.desligaMotor()
		if (minutoAlvo) then
		  -- atingiu o objetivo, limpa o alvo para voltar ao normal
		  minutoAlvo = nil
		end
	end
	print(flag .. ponteiros.toStr())
  end
  
  ponteiros.init( ponteirosOnChange )

  gpio.write(pinStatusLED,gpio.HIGH)

  local ledAceso = false
  
  local function piscaLed() 
    if ledAceso then
		gpio.write(pinStatusLED,gpio.HIGH)
		ledAceso = false
	else 
		gpio.write(pinStatusLED,gpio.LOW)
		ledAceso = true
	end
  end
  
  local piscaLedTimer = tmr.create() 
  if not piscaLedTimer:alarm(500, tmr.ALARM_AUTO, piscaLed) -- a cada meio segundo
  then  
      print("problemas no piscaLedTimer")
  end

  -- move o ponteiro até chegar ao minuto zero
  local function zeromin() 
    minutoAlvo = 0
	acionaPonteiro()
  end

  local function getMinutoAlvo()
    return minutoAlvo
  end

  r.zeromin = zeromin
  r.v = '1.0'
  r.minutoAlvo = getMinutoAlvo
  r.setHora = ponteiros.setHr

end


