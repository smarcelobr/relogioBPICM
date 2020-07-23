do 

  function startup()
    if file.open("ok.flag") == nil then
	print("ok.flag foi apagado ou renomeado.")
    else
	print("Running")
	file.close("ok.flag")
	-- the actual application is stored in 'application.lua'
	pcall(node.flashindex("_init"))
        LFS.rotary2020()
    end
  end

  print("Se quiser cancelar a inicialização, digite rapidamente:")
  print("file.rename('ok.flag','not_ok.flag')")
  print("Waiting ...")
  
  tmrStartup = tmr.create()
  if not tmrStartup:alarm(20*1000, tmr.ALARM_SINGLE, startup) -- 20 segundos
  then  
    print("init.lua: Problemas no tmrStartup")
  end
        
end
