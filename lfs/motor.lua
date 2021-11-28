print("loading motor")
if (motor and motor.release) then
  motor.release()
end

motor = {}
do
	local pinMotor1, pinMotor2 = 1, 2
	local motor_ON, motor_OFF = gpio.HIGH, gpio.LOW
    if file.exists("motorOnIsLOW.flag") then
       motor_ON, motor_OFF = gpio.LOW, gpio.HIGH
    end

	gpio.mode(pinMotor1,gpio.OUTPUT)
	gpio.mode(pinMotor2,gpio.OUTPUT)  
	gpio.write(pinMotor1,motor_OFF)
	gpio.write(pinMotor2,motor_OFF)

	local status, pinLigando = 0, -1

  motor.isClockwise = function ()
    return status==1
  end

  motor.isCounterClockwise = function ()
    return status==2
  end

  motor.isEmMovimento = function ()
    return status ~= 0
  end

  local motorTmr = tmr.create()
  motorTmr:register(200, tmr.ALARM_SEMI,
    function()
      if (pinLigando == pinMotor1) or (pinLigando == pinMotor2) then
          gpio.write(pinLigando, motor_ON)
          pinLigando = -1
      end
      ligando = false
    end)


  motor.ligarClockwise = function ()
	-- Aciona o motor
	status = 1 -- clockwise
	gpio.write(pinMotor1, motor_OFF)
    --gpio.write(pinMotor2, motor_OFF)
    pinLigando = pinMotor2
    motorTmr:start()    
  end    
	
  motor.ligarCounterClockwise = function ()
    -- Aciona o motor
    status = 2 -- counterclockwise
    ligando = true
    gpio.write(pinMotor2, motor_OFF)
    --gpio.write(pinMotor1, motor_OFF)
    pinLigando = pinMotor1
    motorTmr:start()    
  end

  motor.desligar = function ()
	-- desliga o motor
    pinLigando = -1
    gpio.write(pinMotor1, motor_OFF)
	gpio.write(pinMotor2, motor_OFF)
	status = 0
  end

  motor.release = function ()
    motorTmr:stop()
    motorTmr:unregister()
    --print("motor.release()")
  end

end
