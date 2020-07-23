do 
        function startup()
            if file.open("rotary2020.lua") == nil then
                print("rotary2020.lua foi apagado ou renomeado.")
            else
                print("Running")
                file.close("rotary2020.lua")
                -- the actual application is stored in 'application.lua'
                require("rotary2020")
            end
        end
        
        uart.setup(0,115200,8,0,1,0)
        
        require("motor")
        -- antes de tudo, desligar os reles que controlam o motor
        motor.desligar()
          
        file.remove('init.paused')
        print("Se quiser cancelar a inicialização, digite rapidamente:")
        print("file.rename('rotary2020.lua','rotary2020.paused')")
        print("You have 20 seconds to abort")
        print("Waiting...")
        tmrStartup = tmr.create()
        if not tmrStartup:alarm(20*1000, tmr.ALARM_SINGLE, startup) -- 10 segundos
        then  
            print("init.lua: Problemas no tmrStartup")
        end
end
