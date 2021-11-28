do
    do
      -- desliga o motor do relogio caso esteja ligado...
        gpio.mode(1,gpio.OUTPUT)
        gpio.mode(2,gpio.OUTPUT)

        local levelDesliga = gpio.LOW
        if file.exists("motorOnIsLOW.flag") then
           levelDesliga = gpio.HIGH
        end
        gpio.write(1,levelDesliga)
        gpio.write(2,levelDesliga)
    end

    -- liga o LED: GPIO(0,LOW)
    gpio.write(0,gpio.LOW)

  function startup()
    tmrStartup = nil
    if file.open("ok.flag") == nil then
	    print("ok.flag foi apagado ou renomeado.")
    else
	    print("Running")
	    file.close("ok.flag")
	    -- the actual application is stored in 'application.lua'
	    pcall(node.LFS.get("_init"))
--        LFS.HTTP_OTA('www.cachambi.com.br','/relogioBPICM/','LFS.img')
        LFS.rotary2020()
    end
  end

  print("Se quiser cancelar a inicializacao, digite rapidamente:")
  print("file.rename('ok.flag','not_ok.flag')")
  print("Waiting ...")
  
  tmrStartup = tmr.create()
  if not tmrStartup:alarm(5*1000, tmr.ALARM_SINGLE, startup) -- 5 segundos
  then  
    print("init.lua: Problemas no tmrStartup")
  end
        
end
