print("loading ponteiros")
require("motor")

ponteiros = {}
do
	local pinMinuto, pinHora = 5, 6

	gpio.mode(pinMinuto,gpio.INT,gpio.PULLUP)
	gpio.mode(pinHora,gpio.INT,gpio.PULLUP)

	local pMinuto = 0;
	local pHora = nil;
	local fOnChange = nil;

    local cwHTbl = { -- clockwise table
    h02468 = 0,
    h028= 1,
    h046= 2,
    h024= 3,
    h0268= 4,
    h048= 5,
    h0246= 6,
    h02= 7,
    h0468= 8,
    h0248= 9,
    h026= 10,
    h04= 11
    }

    local ccwHTbl = { -- counter-clockwise table
    h02468 = 0,
    h068= 1,
    h026= 2,
    h024= 3,
    h0268= 4,
    h048= 5,
    h0246= 6,
    h02= 7,
    h0248= 8,
    h0468= 9,
    h046= 10,
    h04= 11
    }

    local HorMinCode = {minCount = 0,                        
                        minArray = {},
                        currHour = 'n/a'
                        }

  	-- usDelay do motor - 
	local P_200_MS = 200*1000 -- 200000μs => 200ms
	local P_50_MS = 50*1000 -- 50000μs => 50ms

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

	local function OnMinutoDetected(level, when, eventCount)
		print("M")
		if (level == gpio.LOW) then
            -- clockwise or counterclockwise ?
            if (motor.isClockwise()) then                
               vMinInc = 1  -- cw
            else 
               vMinInc = -1 -- ccw
            end

            print("Minuto.")
			if (fOnChange) then
				fOnChange(calcGMIN(), pMinuto, pHora)
			end
            
			if (pMinuto ~= nil) then
               pMinuto = pMinuto + vMinInc
               if (pMinuto>=60) then
                 pHora = pHora and (pHora + 1)
                 pMinuto = 0
               else 
                 if (pMinuto<0) then
                   pHora = pHora and (pHora - 1)
                   pMinuto = 59
                 end
               end
               if (pHora or 0)>11 then
                 pHora = 0
               else 
                 if (pHora or 0)<0 then
                   pHora = 11
                 end
               end
			end

            HorMinCode.minCount = HorMinCode.minCount + vMinInc
            if (#HorMinCode.minArray > 0) and 
                  (math.abs(HorMinCode.minCount) > 8) then
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
                if (lHoraDetect~=nil) then
                  pMinuto = 0
                  if (pHora == nil) then
                    -- acerta a hora
                    pHora = lHoraDetect
                  end
                end
            end
            
		end
	end
 
	local function OnHoraDetected(level, when, eventCount)
		print("H")
		if (level == gpio.HIGH) then
            if (math.abs(HorMinCode.minCount) > 8) then 
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
 
  local function init(pOnChange) 
    fOnChange = pOnChange
	-- estabelece a interrupcao na subida do sinal.
	gpio.trig(pinMinuto, "down", debounce(OnMinutoDetected, P_200_MS )) 
	gpio.trig(pinHora, "up", debounce(OnHoraDetected, P_50_MS )) 
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

  ponteiros.init = init
  ponteiros.getMin = getMin
  ponteiros.setMin = setMin
  ponteiros.getHr = getHr
  ponteiros.setHr = setHr
  ponteiros.GMIN = calcGMIN
  ponteiros.toStr = toStr
  ponteiros.code = HorMinCode
  
end

