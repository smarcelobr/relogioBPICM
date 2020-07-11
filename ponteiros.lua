local ponteiros
do
	local pinMinuto, pinHora = 5, 6

	gpio.mode(pinMinuto,gpio.INT,gpio.PULLUP)
	gpio.mode(pinHora,gpio.INT,gpio.PULLUP)

	local pMinuto = -1;
	local pHora = -1;
	local fOnChange = nil;

  	-- usDelay do motor - 
	local P_200_MS = 200*1000 -- 200000μs => 200ms
	local P_50_MS = 50*1000 -- 200000μs => 200ms

	function debounce (func, usDelay)
		local last = 0
		local delay = usDelay -- 50000 = 50ms * 1000 as tmr.now() has μs resolution

		return function (...)
			local now = tmr.now()
			local delta = now - last
			if delta < 0 then delta = delta + 2147483647 end; -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
			if delta < delay then return end;

			last = now
			return func(...)
		end
	end
 
	local function OnMinutoDetected(level, when, eventCount)
		print("M")
		if (level == gpio.LOW) then
			print("Minuto.")
			if (fOnChange) then
				fOnChange(pMinuto, pHora, 'm')
			end
			if (pMinuto ~= -1) then
				pMinuto = pMinuto + 1
			end
		end
	end
 
	local function OnHoraDetected(level, when, eventCount)
		print("H")
		if (level == gpio.HIGH) then
			print("Hora.")
			if ((pMinuto == -1) or (pMinuto > 8)) then
			   pMinuto = 0
			   pHora = pHora + 1
			end
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
 
  local function getHr() 
    return pHora
  end
  
  local function setHr(newHora)
    pHora = newHora
  end
  
  local function toStr() 
    return pHora .. ":" .. pMinuto
  end

  ponteiros = {
    init = init,
    getMin = getMin,
    getHr = getHr,
	setHr = setHr,
	toStr = toStr
  }
  
end
return ponteiros