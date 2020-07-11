local relogioInternet
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
	
	-- inicia o sync com SNTP caso já não tenha iniciado
	if SntpSyncTentativas == 0 then
		print ("sincronizando com o NTP server")
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		SntpSyncTentativas = SntpSyncTentativas + 1
	end
  end
  
  relogioInternet = {
	wifiOnConnect = wifiOnConnect
  }
end
return relogioInternet