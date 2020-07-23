do

   local NTPlist = {'200.160.7.186', -- já funcionou
   
   '200.160.0.8', -- já funcionou
--   '200.189.40.8',     -- não sei se funcionou
--   '200.192.232.8',    -- não sei se funcionou
--   '200.160.7.193',    -- não sei se funcionou
--   '201.49.148.135',   -- não sei se funcionou
   '200.186.125.195',  -- já funcionou 
   '200.20.186.76'}    -- já funcionou
	-- parametros do rotary encoder
	
	-- usDelay do motor - 
	local P_DEBOUNCE_MOTOR_USDELAY = 200*1000 -- 200000μs => 200ms

	function debounce (func, usDelay)
		local last = 0
		local delay = usDelay -- 50000 = 50ms * 1000 as tmr.now() has μs resolution

		return function (...)
			local now = tmr.now()
			local delta = now - last
			if delta < 0 then delta = delta + 2147483647 end; -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
			if delta < delay then return end;

			last = now
			return func(...)
		end
	end

  -- setup 
  
  -- use pin 1 as the input pulse width counter
  local now, trig = tmr.now, gpio.trig

  local wifiON = false
  
  local pinRotary, pinMotor, pinMinuto, pinHora, pinStatusLED = 7, 6, 1, 2, 0
  local falhaSincronismo, falhaMotor = false, false

  print( tmr.now() )
  gpio.mode(pinMinuto, gpio.INT, gpio.PULLUP)
  gpio.mode(pinHora, gpio.INT, gpio.PULLUP)
  gpio.mode(pinMotor, gpio.OUTPUT) 
  gpio.mode(pinRotary,gpio.OUTPUT)
  gpio.mode(pinStatusLED,gpio.OUTPUT)
  
  -- desliga rele
  gpio.write(pinMotor, gpio.LOW)
  -- desliga rotary encoder
  gpio.write(pinRotary,gpio.LOW)
  -- desliga LED
  gpio.write(pinStatusLED, gpio.HIGH)
  
  --sntp.setoffset(-3*60*60)  -- fuso horario -03:00
  local SntpSyncTentativas = 0
  -- funcao quando o sntp sincroniza a hora
  local function sntpSyncSuccess(sec, usec, server, info) 	
	print('sync', sec, usec, server)
  end

  local function sntpSyncError(codError, complemento) 	
	print('sntp error sync. cod:', codError)
	if (complemento ~= nil) then
		print('sntp error compl:', complemento)
	end
	
	if (codError == 4) then 
		-- 4 = timeout
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		SntpSyncTentativas = SntpSyncTentativas + 1
	end
	
  end
  
  -- funcao quando o wifi for conectado
  local function wifiOnConnect()
	print("wifi conectado")
	wifiON = true
	
	-- inicia o sync com SNTP caso já não tenha iniciado
	if SntpSyncTentativas == 0 then
		print ("sincronizando com o NTP server")
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		SntpSyncTentativas = SntpSyncTentativas + 1
	end
  end
  
   -- exibe a hora de tempos e tempos
	local function exibeHora() 
		local tm = rtctime.epoch2cal(rtctime.get())
		print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
	end
  
  local exibeHoraTimer = tmr.create()  
   if not exibeHoraTimer:alarm(20*1000, tmr.ALARM_AUTO, exibeHora) -- 20 segundos
   then  
      print("problemas no exibeHoraTimer")
   end
   
  -- conecta no WIFI para pegar a hora
  wifi.sta.disconnect()
  wifi.eventmon.register( wifi.eventmon.STA_CONNECTED, wifiOnConnect )
  wifi.setmode(wifi.STATION)
  wifi.sta.autoconnect(0) -- desabilita a conexão automatica  
  
  local station_cfg={}
  station_cfg.ssid="jardimdomeier"
  station_cfg.pwd="sergioeluciene"
  station_cfg.save=true

  wifi.sta.config(station_cfg)

  -- agora tenta conectar no wifi
  wifi.sta.connect()

  -- configura a parte que movimenta o motor a cada minuto.  
  local ponteiroTimer = tmr.create()  
  local minuto, emMovimento = 0, false
  local minutoNaMarcaDaHora, minutosParaAjuste = -1, 0 -- inicialmente é indefinido

  local function falhouMotor()
	-- entra em modo de falha.
	print("Falha motor/encoder nao responde.")
	gpio.write(pinMotor, gpio.LOW)
	gpio.write(pinRotary, gpio.LOW)
	falhaMotor = true
	-- TODO piscar LED rapidamente.
  end
  
  local function desligaPonteiro(level, when, eventCount)
    if (level == gpio.HIGH) then
		-- verifica se tem ajuste
		if (minutosParaAjuste>0) then 
			-- é para adiantar o relogio, então, deixa-o correr mais um minuto.
			minutosParaAjuste = minutosParaAjuste - 1 
			print ("~.")
		else 
			-- funcionamento normal, pode desligar
			emMovimento = false
			-- caso tenha detectado falha no Motor, pode desfazer, pois foi destravado
			falhaMotor = false
			print(".")
			-- desliga o motor
			gpio.write(pinMotor, gpio.LOW)
			gpio.write(pinStatusLED, gpio.HIGH) -- desliga o LED
		end
	end
  end
  
  local function acionaPonteiro()
	-- testa se há uma falha mecanica 
	-- (chegou o próximo minuto sem desligar o motor)
	if (emMovimento) then
		-- o motor está em movimento desde o ultimo minuto... entra em modo de falha
		falhouMotor()
	end
  
	-- verifica se é para manter o motor parado para auto ajuste
	if (minutosParaAjuste<0)
	then
	    -- deixa parado até zerar o ajuste
		minutosParaAjuste = minutosParaAjuste + 1 
		print ("<<")
	else
		-- Aciona o motor
		minuto = minuto + 1
		print('ponteiro',minuto)
		emMovimento = true
		gpio.write(pinMotor, gpio.HIGH)
	end	
  end
  -- estabelece a interrupcao na subida do sinal.
  trig(pinMinuto, "up", debounce(desligaPonteiro, P_DEBOUNCE_MOTOR_USDELAY )) 
  
  if not ponteiroTimer:alarm(60*1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
  then  
      print("problemas no ponteiroTimer")
  end
  
	-- funcao para acertar a hora (o relogio está no minuto 0)
	local function marcaHoraDetected()
		-- aciona led de status
		gpio.write(pinStatusLED, gpio.LOW) -- liga o LED
		
		minuto = 0 -- zera o minuto
	
		local tm = rtctime.epoch2cal(rtctime.get())
		local minutoReal = tm["min"]
		
		-- faz os ajustes, parando ou adiantando o relogio
		if (minutoReal~=0) then
			-- precisa ajustar. Adiantar ou atrasar?
			if (minutoReal < 10) then
				minutosParaAjuste = minutoReal -- relogio da igreja está atrasado (ajuste positivo para adiantar)
			else if (minutoReal >50) then
				minutosParaAjuste = minutoReal-60 -- relogio da igreja está adiantado (ajuste negativo para atrasar)
				else 
					-- Há falha critica de sincronismo (>10 minutos). Não tenta nenhum ajuste automatico.
					-- O ajuste deve ser manual.
					falhaSincronismo = true
				end -- se esta adiantado
			end -- se está atrasado
		end -- se precisa ajustar
		
		print("MARCA DA HORA: minuto real: ", minutoReal, "/ajuste: ", minutosParaAjuste)
	end
	
	-- detecta a Hora (quando o ponteiro dos minutos chega no 0)
	trig(pinHora, "down", debounce(marcaHoraDetected, 2*60*1000000)) -- 2 minutos de debounce

  -- Carrega módulo com a implementação dos webServices.
  require("rotarysvc").init()
	
  print("tudo configurado")
  
end

