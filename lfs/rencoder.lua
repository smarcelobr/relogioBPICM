print("loading rencoder")
require("motor")
require("configuracoes")

rencoder = {}
do
	local pinMinuto, pinHora = 5, 6

	gpio.mode(pinMinuto,gpio.INT,gpio.PULLUP)
	gpio.mode(pinHora,gpio.INPUT,gpio.PULLUP)

	local pMinuto = 0;  -- valor dos minutos no encoder (sem diferenca)
	local pHora = nil;  -- valor das horas no encoder (sem diferenca)
	local fOnChange = nil;
    local lastHrLevel = gpio.read(pinHora)
    local difMinutos = 0 -- diferença entre a hora do encoder e dos ponteiros (em minutos)
    local savePendent = false

    local cwHTbl = { -- clockwise table
    h0246810 = 0,
    h02810= 1,
    h04610= 2,
    h02410= 3,
    h026810= 4,
    h04810= 5,
    h024610= 6,
    h0210= 7,
    h046810= 8,
    h024810= 9,
    h02610= 10,
    h0410= 11
    }

    local ccwHTbl = { -- counter-clockwise table
    h0246810 = 11,
    h02810= 0,
    h04610= 1,
    h06810= 2,
    h024810= 3,
    h02610= 4,
    h046810= 5,
    h0810= 6,
    h024610= 7,
    h026810= 8,
    h04810= 9,
    h0610= 10
    }

    local HorMinCode = {minCount = 100,                        
                        minArray = {},
                        currHour = 'n/a',
                        ultimaHoraDetectada = nil
                        }

  	-- usDelay do motor - 
	local P_Delay_Min = 600*1000 -- 200000μs => 200ms
	--local P_Delay_Hr = 200*1000 -- 50000μs => 50ms

	function debounce (func, usDelay)
		local last = 0
		local delay = usDelay -- 50000 = 50ms * 1000 as tmr.now() has μs resolution

		return function (...)
			local now = tmr.now()
			local delta = now - last
			if delta < 0 then delta = delta + 2147483647 end; 
			--[[ proposed because of delta rolling over, 
			https://github.com/hackhitchin/esp8266-co-uk/issues/2
            --]]
			if delta < delay then return end;

			last = now
			return func(...)
		end
	end
 
  local function calcGMIN()
    -- usando 'and', se pHora é nil, retorna nil.
    return pHora and (((pHora%12)*60) + pMinuto + difMinutos) % 720
  end

    local function notifyChange()
        if (fOnChange) then
            fOnChange(calcGMIN(), pMinuto, pHora)
        end
    end

    local function OnHoraDetected(level)
        if (level == gpio.LOW) then
            if (math.abs(HorMinCode.minCount) > 11) then 
               --[[
               indica o primeiro sinal de Hora depois de muito tempo.
               --]]
               
               -- hora desconhecida, pois, começou o calculo agora
               HorMinCode.currHour = 'n/a'
               HorMinCode.minCount = 0
               HorMinCode.minArray = {}
            else 
--               print("Hora: " .. math.abs( HorMinCode.minCount ))
            end
            table.insert(HorMinCode.minArray, math.abs( HorMinCode.minCount ))            
        end
    end
 
	local function OnMinutoDetected(level, when, eventCount)
		if (level == gpio.LOW) then
            -- clockwise or counterclockwise ?
            if (motor.isClockwise()) then                
               vMinInc = 1  -- cw
            else 
               vMinInc = -1 -- ccw
            end

			if (pMinuto ~= nil) then
               pMinuto = pMinuto + vMinInc
               if (pMinuto>=60) then
                 pHora = pHora and (pHora + 1)
                 pMinuto = 0
               elseif (pMinuto<0) then
                   pHora = pHora and (pHora - 1)
                   pMinuto = 59
               end
               if (pHora or 0)>11 then
                 pHora = 0
               elseif (pHora or 0)<0 then
                   pHora = 11
               end
			end

            HorMinCode.minCount = HorMinCode.minCount + vMinInc
            local hrLevel = gpio.read(pinHora)
            if (lastHrLevel == gpio.HIGH) and (hrLevel == gpio.LOW) then
              OnHoraDetected(hrLevel)
            end
            lastHrLevel = hrLevel
            
            if (#HorMinCode.minArray > 0) and 
                  (math.abs(HorMinCode.minCount) > 11) then
                -- terminou de codificar a hora
                HorMinCode.currHour = 'h'
                for k,v in pairs(HorMinCode.minArray) do
                    HorMinCode.currHour = HorMinCode.currHour .. v
                end
                --print(HorMinCode.currHour)
                
                local lHoraDetect
                if vMinInc == 1 then 
                  -- cw
                  lHoraDetect = cwHTbl[HorMinCode.currHour]
                else 
                  -- ccw
                  lHoraDetect = ccwHTbl[HorMinCode.currHour]
                end
                
                --print('Hora detectada:' .. (lHoraDetect or "!"))
                HorMinCode.minArray = {}
                HorMinCode.minCount = 100
                if (lHoraDetect~=nil) then
                    if vMinInc == 1 then
                        -- cw
                        pMinuto = 0
                    else
                        -- ccw
                        pMinuto = 45
                    end
                    if (pHora == nil) then
                        -- acerta a hora
                        pHora = lHoraDetect
                    else
                        -- confere pHora a cada duas horas
                        if HorMinCode.ultimaHoraDetectada and lHoraDetect == ((HorMinCode.ultimaHoraDetectada+vMinInc) % 12) then
                            if pHora ~= lHoraDetect then
                                -- ajuste da hora dos ponteiros na conferencia.
                                pHora = lHoraDetect
                            end
                        end
                    end
                    HorMinCode.ultimaHoraDetectada = lHoraDetect
                else
                    HorMinCode.ultimaHoraDetectada = nil
                end
            end

            notifyChange();
		end
	end
 
  local function init(pOnChange) 
    fOnChange = pOnChange
	-- estabelece a interrupcao na subida do sinal.
	gpio.trig(pinMinuto, "down", debounce(OnMinutoDetected, P_Delay_Min )) 
	--gpio.trig(pinHora, "down", debounce(OnHoraDetected, P_Delay_Hr )) 
  end

  local function getMin() 
    return pMinuto
  end

  rencoder.ptr = {} -- funcoes para calcular a diferenca com ponteiros
  --[[
    encoder.ptr.set(hora, minuto) - funcao para informar as horas
    no ponteiro do relogio. Com isso, o encoder saberá calcular a
    diferença entre o horário do encoder e dos ponteiros do relógio.
    Atenção: Não é para informar a hora local atual e sim as horas que
    estão no ponteiro do relógio. A hora local, o sistema pega da internet.
    
    Quando chegar o próximo ciclo, automaticamente o relógio irá posicionar
    os ponteiros na hora correta.
    
    Retorna false caso não consiga calcular a diferença ou true
    caso consiga.
    
    Exemplo: 
    
    Digamos que nos ponteiros do relógio são 6:32. 
    
    >=encoder.ptr.set(6,32)
    true 
    
    No próximo ciclo, o relógio se movimentará até atingir 
    a hora correta.
  --]]
  rencoder.ptr.set = function (hora, minuto)
    if (pHora == nil) then
       --print("Hora do encoder ainda é desconhecida.")
       return false
    end
    -- calcula apenas a diferenca entre o encoder os ponteiros
    local difMinutosForward = ((hora*60)+minuto) - ((pHora*60)+pMinuto)
    local difMinutosReverse = ((hora*60)+minuto) - ((pHora*60)+pMinuto+720)
    if math.abs(difMinutosReverse) > math.abs(difMinutosForward) then
      difMinutos = difMinutosForward
    else 
      difMinutos = difMinutosReverse
    end

    savePendent = true;
    notifyChange();

    return true
  end

  rencoder.ptr.incrementDifMinutos = function(increment)
      difMinutos = difMinutos + increment;
      savePendent = true;
      notifyChange();
  end

  rencoder.ptr.saveDifMinutos = function()
      cfg.set({"encoder",'dif'},difMinutos)
      savePendent = false;
      notifyChange();
  end

  rencoder.ptr.getHora = function ()
    if pHora == nil then
       return nil
    end
    return (math.floor(((pHora*60)+pMinuto+difMinutos)/60) % 12)
  end

  rencoder.ptr.getMinuto = function ()
    if pHora == nil then
       return nil
    end
    return (((pHora*60)+pMinuto+difMinutos) % 60)
  end

  rencoder.ptr.toStr = function ()
    return (rencoder.ptr.getHora() or '-') .. ":" .. (rencoder.ptr.getMinuto() or '-')
  end
 
  local function getHr() 
    return pHora
  end
  
  local function toStr() 
    return (pHora or '-') .. ":" .. pMinuto
  end

  rencoder.updConfig = function ()
      -- lê a diferença em minutos do encoder com os ponteiros do relogio
      cfg.get({'encoder','dif'}, function (config) 
          if config ~= nil and 
             config.encoder ~= nil and 
             config.encoder.dif ~= nil then
                difMinutos=config.encoder.dif
                --print(("encoder dif = %d \n"):format(difMinutos))
                savePendent = false;
                notifyChange();
          end
      end)
  end

  rencoder.status = function ()
    return {
        time = rencoder.ptr.toStr(),
        difMinutos = difMinutos,
        savePendent = savePendent,
        ultHora = HorMinCode.ultimaHoraDetectada,
        ultCod=HorMinCode.currHour
    }
  end
  
  rencoder.updConfig()
  
  rencoder.init = init
  rencoder.getMin = getMin
  rencoder.getHr = getHr
  rencoder.GMIN = calcGMIN
  rencoder.toStr = toStr
  rencoder.code = HorMinCode
  
end
