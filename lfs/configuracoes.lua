print("loading configuracoes")
require("util")
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
  
  --[[
     atualiza o JSON de configurações com o valor passado no parâmetro.
  --]]
  cfg.set = function(path, valor)
    --[[ 
     exemplo:
     cfg.set({'encoder','dif'}, 34)
     
     atualiza o fragmento:
     {
       ...
       "encoder": {
        "dif": 34
       }
       ...
     }

     outro exemplo:
     cfg.set({'wifi','sta','ssid'}, 'meussidwifi')
     cfg.set({'wifi','sta','pwd'}, 'senhawifi')

    --]]
    
      -- le o json completo:
      local fd_in = file.open("config.json","r")      
      if fd_in then 
        t = sjson.decode(fd_in:read(1024))
        fd_in:close(); fd_in = nil
        
        -- altera ou inclui a propriedade
        if t == nil then
          t = {}
        end
        t2 = t
        for i,p in ipairs(path) do
          if i == #path then
            -- ultimo elemento do path
            t2[path[i]] = valor
          else             
            if t2[path[i]] == nil then
              t2[path[i]] = {}
            end
            t2 = t2[path[i]]            
          end
        end -- for
        print( pairToStr("r",t) )
        ok, json = pcall(sjson.encode, t)
        if ok then
          -- salva no arquivo
          local fd_out = file.open("config.json","w+")
          if fd_out then
            fd_out:write(json)
            fd_out:close(); fd_out = nil
          else
            print("Não foi possível escrever 'config.json'")
          end          
        else
          print("cfg.set(): failed to encode (sem memória)")
        end        
      else 
        print("Não foi possível abrir 'config.json'")
      end
    
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

