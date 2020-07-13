print("loading motor")
if (motor and motor.release) then
  motor.release()
end

motor = {}
do
	local pinMotor1, pinMotor2 = 1, 2

	gpio.mode(pinMotor1,gpio.OUTPUT)
	gpio.mode(pinMotor2,gpio.OUTPUT)  
	gpio.write(pinMotor1,gpio.HIGH)
	gpio.write(pinMotor2,gpio.HIGH)

	local status, pinLigando = 0, -1

  local function isClockwise()
    return status==1
  end

  local function isCounterClockwise()
    return status==2
  end

  local function isEmMovimento()
    return status ~= 0
  end

    
    local motorTmr = tmr.create()
    motorTmr:register(200, tmr.ALARM_SEMI, 
      function() 
        if (pinLigando == pinMotor1) or (pinLigando == pinMotor2) then
            gpio.write(pinLigando, gpio.LOW)
            pinLigando = -1
        end
        ligando = false
      end)


  local function ligarClockwise()
    if (isEmMovimento()) then
      print('deve desligar motor');
      return
    end
	-- Aciona o motor
	status = 1 -- clockwise
	gpio.write(pinMotor1, gpio.HIGH)
    gpio.write(pinMotor2, gpio.HIGH)
    pinLigando = pinMotor2
    motorTmr:start()    
  end    
	
  local function ligarCounterClockwise()
    if (isEmMovimento()) then
      print('deve desligar motor');
      return
    end
    -- Aciona o motor
    status = 2 -- counterclockwise
    ligando = true
    gpio.write(pinMotor2, gpio.HIGH)
    gpio.write(pinMotor1, gpio.HIGH)
    pinLigando = pinMotor1
    motorTmr:start()    
  end

  local function desligar()
	-- desliga o motor
    pinLigando = -1
    gpio.write(pinMotor1, gpio.HIGH)
	gpio.write(pinMotor2, gpio.HIGH)
	status = 0
  end

  local function release()
    motorTmr:stop()
    motorTmr:unregister()
    print("motor.release()")
  end
  
  motor.isClockwise = isClockwise
  motor.isCounterClockwise = isCounterClockwise
  motor.isEmMovimento = isEmMovimento
  motor.ligarClockwise = ligarClockwise
  motor.ligarCounterClockwise = ligarCounterClockwise
  motor.desligar = desligar
  motor.release = release
  
end

