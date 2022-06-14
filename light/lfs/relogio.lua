do
    -- carrega as configurações
    local config = require('config')
    require("telnet"):open()

    local motor = {}
    function motor.ligar()
      gpio.write(relePin, motorON)
      motorLigado = true
      gpio.write(ledPin, ledON)
    end

    function motor.desligar()
      gpio.write(relePin, motorOFF)
      motorLigado = false
      gpio.write(ledPin, ledOFF)
    end

    -- encoder
    local encoder={}
    local pMinuto = 0;  -- valor dos minutos no encoder (sem diferenca)
    local pHora = nil;  -- valor das horas no encoder (sem diferenca)
    local P_Delay_Min = 800 * 1000 -- 800000μs => 800ms => 0.8seg
    local lastHrLevel = gpio.read(horaPin)
    local cwHTbl = { -- clockwise table
        h0246810 = 0,
        h02810 = 1,
        h04610 = 2,
        h02410 = 3,
        h026810 = 4,
        h04810 = 5,
        h024610 = 6,
        h0210 = 7,
        h046810 = 8,
        h024810 = 9,
        h02610 = 10,
        h0410 = 11
    }

    local HorMinCode = {
       minCount = 100,
       minArray = {},
       currHour = 'n/a',
       ultimaHoraDetectada = nil
    }

    function encoder.GMIN()
        -- usando 'and', se pHora é nil, retorna nil.
        return pHora and (((pHora % 12) * 60) + pMinuto + config.difMinutos) % 720
    end

  local function calcDif(gmin1, gmin2)
      -- se +, roda ccw para ajuste
      -- se -, roda cw para ajuste
      local difs = { gmin1 - gmin2,
                     gmin1 - (720 + gmin2),
                     (gmin1 + 720) - gmin2
      }

      local menorDif = difs[1]
      for i, dif in ipairs(difs) do
          if math.abs(menorDif) > math.abs(dif) then
              menorDif = dif
          end
      end
      return menorDif
  end

  function calcDifGMIN()
     local rtcGMIN, newSec = sntpGMIN()
     local encoderGMIN = encoder.GMIN()

     local difGMIN = nil
     if (encoderGMIN ~= nil and rtcGMIN ~= nil) then
         -- calcula atraso ou adianto
         difGMIN = calcDif(encoderGMIN, rtcGMIN)
     end
     return difGMIN, newSec
  end

  function debounce (func, usDelay)
     local last = 0
     local delay = usDelay -- 50000 = 50ms * 1000 as tmr.now() has μs resolution

     return function(...)
         local now = tmr.now()
         local delta = now - last
         if delta < 0 then
             delta = delta + 2147483647
         end
         --[[ proposed because of delta rolling over,
         https://github.com/hackhitchin/esp8266-co-uk/issues/2
         --]]
         if (delta < delay) then
             return
         end

         if func(...) then
             -- a funcao deve retornar true para evitar o bounce
             last = now
         end
     end
  end

  local function verificaHora()
     -- terminou de codificar a hora
     HorMinCode.currHour = 'h'
     for k, v in pairs(HorMinCode.minArray) do
         HorMinCode.currHour = HorMinCode.currHour .. v
     end
     print(HorMinCode.currHour)

     local lHoraDetect = cwHTbl[HorMinCode.currHour]

     if (lHoraDetect ~= nil) then
         if pHora == nil or  -- acerta a hora se não estiver estabelecida
                 (HorMinCode.ultimaHoraDetectada and -- ou confere e acerta pHora a cada duas horas
                 lHoraDetect == ((HorMinCode.ultimaHoraDetectada + 1) % 12)) then
             if pHora ~= lHoraDetect then
                 -- ajuste da hora dos ponteiros na conferencia.
                 pHora = lHoraDetect
             end
             pMinuto = 0
         end
         HorMinCode.ultimaHoraDetectada = lHoraDetect
     end
  end

  local function onHoraDetected()
     if (HorMinCode.minCount > 11) then
        -- hora desconhecida, pois, começou o novo calculo agora
        HorMinCode.currHour = 'n/a'
        HorMinCode.minCount = 0
        HorMinCode.minArray = {}
     end
     table.insert(HorMinCode.minArray, HorMinCode.minCount)
     verificaHora()
  end

  local function desligaPonteiroSeMinutoCerto()
    local difGMIN = calcDifGMIN()
    if (difGMIN or 0) >= 0 and pHora ~= nil then
       -- se já detectou a hora, desliga o motor se os ponteiros estiverem certos ou adiantados entre encoder e hora da internet.
       if not tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
                           -- desliga o motor apos 500ms para distanciar um pouco do edge.
                           motor.desligar()
                       end) then
         -- timer não funcionou... desliga agora.
         motor.desligar()
       end
    end
    print((pHora or '??') .. ':' .. pMinuto)
  end

  local function onMinutoDetected(level, when, eventCount)
     if (level == gpio.LOW) then
       pMinuto = pMinuto + 1
       if (pMinuto >= 60) then
           pHora = pHora and (pHora + 1)
           pMinuto = 0
       end
       if (pHora or 0) > 11 then
           pHora = 0
       end
       -- não usar print((pHora or '??') .. ':' .. pMinuto) dentro de interrupt handler

       HorMinCode.minCount = HorMinCode.minCount + 1
       local hrLevel = gpio.read(horaPin)
       if (lastHrLevel == gpio.HIGH) and (hrLevel == gpio.LOW) then
          node.task.post(node.task.MEDIUM_PRIORITY,onHoraDetected)
       end
       lastHrLevel = hrLevel

       node.task.post(node.task.MEDIUM_PRIORITY,desligaPonteiroSeMinutoCerto)

       return true
     else
       return false
     end
  end

    gpio.trig(minutosPin, "down", debounce(onMinutoDetected, P_Delay_Min))

    print('...')

  -- SNTP
  local sntpAcionado = false
  local sntpSucesso = false

  -- funcao quando o sntp sincroniza a hora
  local function sntpSyncSuccess(sec, usec, server, info)
    print('sntp:' .. (sec or 0))
    sntpSucesso = true
  end

  local function sntpSyncError(codError, complemento)
    print('prob 0x0322:'..(codError or '?')..'-'..(complemento or '?'))
	if (codError == 4) then
		-- 4 = timeout
		sntpSucesso=false
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		sntpAcionado=true
	end
  end

  sntpGMIN = function ()
    if (not sntpSucesso) then
      return nil, nil
    end
    local local_now = rtctime.get() + (config.difTimezone*60) -- converte a diferença de minutos para segundos.
    local tm = rtctime.epoch2cal(local_now)

    return ((tm["hour"]%12)*60) + tm["min"], tm["sec"]
  end

  -- WIFI
  wifi.sta.disconnect()
  wifi.sta.autoconnect(0) -- desabilita a conexao automatica

  local country_info = {}
  country_info.country = "BR"
  country_info.start_ch = 1
  country_info.end_ch = 13
  country_info.policy = wifi.COUNTRY_AUTO
  wifi.setcountry(country_info)

  -- funcao quando o wifi for conectado
  local function wifiOnConnect()
	-- inicia o sync com SNTP caso já não tenha iniciado
	if not sntpAcionado then
        sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
        sntpAcionado = true
    end
  end

  wifi.setphymode(wifi.PHYMODE_G)
  wifi.setmode(wifi.STATION)
  wifi.sta.config(config.wifi)
  -- agora tenta conectar no wifi
  wifi.sta.connect(wifiOnConnect)

  -- acionaPonteiro
  local motorLigado = false;
  local function acionaPonteiro(ptrTimer)

     local difGMIN, newSec = calcDifGMIN()

     if (newSec ~= nil) then
        local newInterval = math.max((60 - newSec), 5) * 1000
        ptrTimer:interval(newInterval)
     end

     if not motorLigado then
       if (pHora == nil) or ((difGMIN or 0) < 0) then -- se atrasado ou certo
         motor.ligar()
       end
     else
        if (pHora ~= nil) then
           -- motor ainda ligado e não está buscando hora? falha: para tudo.
           ptrTimer:unregister()
           motor.desligar()
           print('prob 1672')
        end
     end
  end

  -- time a cada minuto
  local ponteiroTimer = tmr.create()
  if not ponteiroTimer:alarm(60 * 1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
  then
      print("problemas no ponteiroTimer")
  end

end
