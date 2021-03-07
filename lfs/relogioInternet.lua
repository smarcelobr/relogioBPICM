print("loading rtc")
require("app_wifi")
require("configuracoes")
rtc = {}
do

   local NTPlist = {'200.160.7.186', -- já funcionou
   '200.160.0.8', -- já funcionou
--   '200.189.40.8',     -- não sei se funcionou
--   '200.192.232.8',    -- não sei se funcionou
--   '200.160.7.193',    -- não sei se funcionou
--   '201.49.148.135',   -- não sei se funcionou
   '200.186.125.195',  -- já funcionou 
   '200.20.186.76'}    -- já funcionou

  local SntpSyncTentativas = 0
  local sucesso = false
  local difTimezone = -180
  local fOnChange = nil

  local function notifyChange()
      if (fOnChange) then
          fOnChange()
      end
  end
  
   --[[
    atualizaDifTimezone - Esta função pega a diferença dependendo do valor do epoch timestamp
    atual pois a diferença de horário varia se estivermos em horário de 
    verão. 
  --]]
  local function atualizaDifTimezone(rtcConfig)
   --[[
    
    A tabela de horários de verão está no arquivo config.json que deve ser
    atualizado sempre que houver alguma mudança ou divulgação.
    
    Exemplo:

{
...
  "rtc": {
      "difTimezone": [
         {"epochTimestamp":1549850400, "dif": -180},
         {"epochTimestamp":1541556000, "dif": -120},
         {"epochTimestamp":0, "dif": -180}
      ]
  },
  ...
}

    O elemento difTimezone tem um array com o valor a partir do qual passou a 
    valer determinada diferença em minutos. No exemplo acima, o epoch timezone
    1549850400 corresponde a 11/02/2019 em Brasília que foi quando 
    terminou o horário de verão 
    iniciado em 7/11/2018 (ou epoch tz= 1541556000).
    
   
     Sugiro usar o site https://www.epochconverter.com/ para converter dia/mes/ano
     para um "Epoch timestamp" e vice-versa
   --]]
   
   -- percorro toda a tabela até encontrar um timezone menor ou igual 
   -- ao epoch corrente
   if rtcConfig ~= nil and 
      rtcConfig.rtc ~= nil and 
      rtcConfig.rtc.dif ~= nil then
       local now = rtctime.get()
       for i,timezone in ipairs(rtcConfig.rtc.dif) do
          if timezone.epoch <= now then
             difTimezone = timezone.dif
             --print(("{\"epoch\"=\"%d\",\"difRTC\"=\"%d\"}"):format(timezone.epoch, timezone.dif))
             notifyChange()
             break
          end
       end   
   end
   
  end
  
  -- funcao quando o sntp sincroniza a hora
  local function sntpSyncSuccess(sec, usec, server, info) 	
    --print('sync', sec, usec, server)
    sucesso = true
    
    -- atualiza os minutos de diferença por causa do 
    -- fuso horário e horário de verão.
    cfg.get({"rtc","dif"}, atualizaDifTimezone)
  end

  local function sntpSyncError(codError, complemento) 	
	--print('sntp error sync. cod:', codError)
	if (complemento ~= nil) then
		--print('sntp error compl:', complemento)
	end
	
	if (codError == 4) then 
		-- 4 = timeout
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		SntpSyncTentativas = SntpSyncTentativas + 1
	end
	
  end
  
  -- funcao quando o wifi for conectado
  local function wifiOnConnect()
	--print("wifi conectado")
	
	-- inicia o sync com SNTP caso já não tenha iniciado
	if SntpSyncTentativas == 0 then
		--print ("sincronizando com o NTP server")
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		SntpSyncTentativas = SntpSyncTentativas + 1
	end
  end
  wifi.eventmon.register( wifi.eventmon.STA_CONNECTED, wifiOnConnect )

  rtc.GMIN = function ()
    if (not sucesso) then
      return nil
    end 
    local local_now = rtctime.get() + (difTimezone*60) -- converte a diferença de minutos para segundos.
    local tm = rtctime.epoch2cal(local_now)

    return ((tm["hour"]%12)*60) + tm["min"], tm["sec"]
  end

  rtc.toStr = function ()
    if (not sucesso) then
      return 'n/a'
    end 

    local local_now = rtctime.get() + (difTimezone*60) -- converte a diferença de minutos para segundos.
    tm = rtctime.epoch2cal(local_now)

    return string.format("%04d-%02d-%02dT%02d:%02d:%02d",
      tm["year"], tm["mon"], tm["day"],
      tm["hour"], tm["min"], tm["sec"])
  end

    rtc.status = function()
        return {
          time=rtc.toStr(),
          difTimezone=difTimezone
       }
    end

    rtc.set = function(epochSec)
        rtctime.set(epochSec, 0);
        cfg.get({"rtc","dif"}, atualizaDifTimezone);
        sucesso = true;
    end

    rtc.init = function(pOnChange)
        fOnChange=pOnChange
    end

end
