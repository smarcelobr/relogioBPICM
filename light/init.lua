-- globals
ledPin, relePin, minutosPin, horaPin = 0,1,5,6
motorON,motorOFF = gpio.HIGH,gpio.LOW
ledON,ledOFF = gpio.LOW,gpio.HIGH

do
  -- inicia o HW
  gpio.mode(ledPin, gpio.OUTPUT)
  gpio.mode(relePin, gpio.OUTPUT)
  gpio.mode(minutosPin, gpio.INT, gpio.PULLUP)
  gpio.mode(horaPin, gpio.INPUT, gpio.PULLUP)

  -- desliga motor
  gpio.write(relePin, motorOFF)

  local tmrStartup = tmr.create()

  function startup()
    tmrStartup = nil
    if file.open("ok.flag") == nil then
	    print("nenhum ok.flag.")
    else
	    print("Ok")
	    file.close("ok.flag")
	    file.rename('ok.flag','not_ok.flag') -- se travar não reinicia
	    -- the actual application is stored in 'application.lua'
	    pcall(node.LFS.get("_init"))

        --[[ Futuramente, terei um botao para escolher entre
            ir para o modo 'relogio' ou modo de 'configuracao'.
        Para o momento, só tem o modo relogio mesmo.
        --]]
        LFS.relogio()
    end
  end

  print("Para cancelar a inicializacao, digite rapidamente:")
  print("file.rename('ok.flag','not_ok.flag')")
  print("...")
  
  if not tmrStartup:alarm(3*1000, tmr.ALARM_SINGLE, startup) -- 3 segundos
  then
    print("init.lua: Problemas no tmrStartup")
  end
        
end
