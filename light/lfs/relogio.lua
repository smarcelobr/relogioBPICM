do
    -- carrega as configurações
    local config = require('config.lua')

    -- usDelay do motor -
    local P_Delay_Min = 800 * 1000 -- 800000μs => 800ms => 0.8seg
    local lastHrLevel = gpio.LOW

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

    local function ligarMotor()
      gpio.write(relePin, motorON)
      motorLigado = true;
      gpio.write(ledPin, ledON)
    end

    local function desligarMotor()
      gpio.write(relePin, motorOFF)
      motorLigado = false
      gpio.write(ledPin, ledOFF)
    end

    local function onMinutoDetected(level, when, eventCount)
        if (level == gpio.LOW) then
          print('minuto')
          print(level, when, eventCount)

          local hrLevel = gpio.read(horaPin)
          if (lastHrLevel == gpio.HIGH) and (hrLevel == gpio.LOW) then
            print('hora')
          end
          lastHrLevel = hrLevel

          if not tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
                              -- desliga o motor apos 500ms para distanciar um pouco do edge.
                              desligarMotor()
                          end) then
            -- timer não funcionou... desliga agora.
            desligarMotor()
          end

          return true
        else
          return false
        end
    end

    lastHrLevel = gpio.read(horaPin)

    gpio.trig(minutosPin, "down", debounce(onMinutoDetected, P_Delay_Min))

    print('...')

  -- SNTP
  local sntpAcionado = false
  local sntpSucesso = false

  -- funcao quando o sntp sincroniza a hora
  local function sntpSyncSuccess(sec, usec, server, info)
    sntpSucesso = true
  end

  local function sntpSyncError(codError, complemento)
	if (codError == 4) then
		-- 4 = timeout
		sntp.sync(NTPlist, sntpSyncSuccess, sntpSyncError, 1) -- com autorepeat
		sntpAcionado=true
	end
  end

  sntpGMIN = function ()
    if (not sntpSucesso) then
      return nil
    end
    local local_now = rtctime.get() + (difTimezone*60) -- converte a diferença de minutos para segundos.
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
        sntpAcionado = false
    end
  end

  wifi.setphymode(wifi.PHYMODE_G)
  wifi.setmode(wifi.STATION)
  wifi.sta.config(config.wifi)
  -- agora tenta conectar no wifi
  wifi.sta.connect(wifiOnConnect)

  -- acionaPonteiro
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

  local motorLigado = false;
    local function acionaPonteiro(ptrTimer)

        local rtcGMIN, newSec = sntpGMIN()

        if (newSec ~= nil) then
            local newInterval = math.max((60 - newSec), 5) * 1000
            ptrTimer:interval(newInterval)
        end

        if not motorLigado then
          if (difGMIN < 0) then -- se atrasado ou certo
            ligarMotor()
          end
        else
           -- motor ainda ligado? falha: para tudo.
           ptrTimer:unregister()
           desligarMotor()
        end
    end

  -- time a cada minuto
  local ponteiroTimer = tmr.create()
  if not ponteiroTimer:alarm(60 * 1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
  then
      print("problemas no ponteiroTimer")
  end

  ligarMotor()
end
