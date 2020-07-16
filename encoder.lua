print("loading encoder")
require("motor")

encoder = {}
do
	local pinMinuto, pinHora = 5, 6

	gpio.mode(pinMinuto,gpio.INT,gpio.PULLUP)
	gpio.mode(pinHora,gpio.INPUT,gpio.PULLUP)

	local pMinuto = 0;
	local pHora = nil;
	local fOnChange = nil;
    local lastHrLevel = gpio.read(pinHora)

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

    local HorMinCode = {minCount = 0,                        
                        minArray = {},
                        currHour = 'n/a'
                        }

  	-- usDelay do motor - 
	local P_Delay_Min = 200*1000 -- 200000μs => 200ms
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
    return pHora and (((pHora%12)*60) + pMinuto)
  end

    local function OnHoraDetected(level)
        print("H")
        if (level == gpio.LOW) then
            if (math.abs(HorMinCode.minCount) > 11) then 
               print("Hora Inicio")
               --[[ 
               indica o primeiro sinal de Hora depois de muito tempo.
               --]]
               
               -- hora desconhecida, pois, começou o calculo agora
               HorMinCode.currHour = 'n/a'
               HorMinCode.minCount = 0
               HorMinCode.minArray = {}
            else 
               print("Hora: " .. math.abs( HorMinCode.minCount ))
            end
            table.insert(HorMinCode.minArray, math.abs( HorMinCode.minCount ))            
        end
    end
 
	local function OnMinutoDetected(level, when, eventCount)
		print("M")
		if (level == gpio.LOW) then
            print("Minuto.")
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
                print(HorMinCode.currHour)
                
                local lHoraDetect
                if vMinInc == 1 then 
                  -- cw
                  lHoraDetect = cwHTbl[HorMinCode.currHour]
                else 
                  -- ccw
                  lHoraDetect = ccwHTbl[HorMinCode.currHour]
                end
                
                print('Hora detectada:' .. (lHoraDetect or "!"))
                HorMinCode.minArray = {}
                HorMinCode.minCount = 100
                if (lHoraDetect~=nil) then
                  if vMinInc == 1 then
                     -- cw
                     pMinuto = 0
                  else 
                     -- ccw
                     pMinuto = 46
                  end
                  if (pHora == nil) then
                    -- acerta a hora
                    pHora = lHoraDetect
                  end
                end
            end

            if (fOnChange) then
                fOnChange(calcGMIN(), pMinuto, pHora)
            end
            
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

  local function setMin(newMinuto)
    pMinuto = newMinuto
  end
 
  local function getHr() 
    return pHora
  end
  
  local function setHr(newHora)
    pHora = newHora
  end
  
  local function toStr() 
    return (pHora or '-') .. ":" .. pMinuto
  end

  encoder.init = init
  encoder.getMin = getMin
  encoder.setMin = setMin
  encoder.getHr = getHr
  encoder.setHr = setHr
  encoder.GMIN = calcGMIN
  encoder.toStr = toStr
  encoder.code = HorMinCode
  
end

