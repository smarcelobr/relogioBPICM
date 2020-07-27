print("loading configuracoes")
--[[ 
  Trata de ler e escrever propriedades no arquivo "config.json"
  usando o minimo de memória possivel
  
--]]

cfg = {}
do 
  cfg.get = function(path, callback)
    local encontrada = nil
    local fd = file.open("config.json", "r")
    if fd then
      
      local checkpath = function(pTable, pPath)
         local accept = true
         for i,p in ipairs(path) do
            pP = pPath[i] or path[i]
            if (path[i] ~= pP) then
               accept = false
            end
         end
         return accept
      end
    
      local decoder = sjson.decoder({metatable=
	             {checkpath=checkpath}
	        })

      local linha = fd:readline()
      while (linha) ~= nil do
         decoder:write(linha)
         linha = fd:readline()
      end
      fd:close(); fd = nil
	  
      if callback~=nil then callback(decoder:result()) end
	  
    else
      print("falha ao abrir arquivo.")
    end
  end
  
  cfg.set = function(property)
  end
  
--[[
  cfg.test = function()
    cfg.get({"wifi"},
       function(v)
         print(pairToStr("resultado",v))
       end
    )
  end
--]]  
end

--cfg.test()

