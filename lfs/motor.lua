print("loading motor")
if (motor and motor.release) then
  motor.release()
end

motor = {}
do
	local pinMotorCW, pinMotorCCW = 1, 2
	local motor_ON, motor_OFF = gpio.HIGH, gpio.LOW
    if file.exists("motorOnIsLOW.flag") then
       motor_ON, motor_OFF = gpio.LOW, gpio.HIGH
    end

	gpio.mode(pinMotorCCW,gpio.OUTPUT)
	gpio.mode(pinMotorCW,gpio.OUTPUT)
	gpio.write(pinMotorCCW,motor_OFF)
	gpio.write(pinMotorCW,motor_OFF)

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
      if (pinLigando == pinMotorCCW) or (pinLigando == pinMotorCW) then
          gpio.write(pinLigando, motor_ON)
          pinLigando = -1
      end
      ligando = false
    end)


  motor.ligarClockwise = function ()
	-- Aciona o motor
	status = 1 -- clockwise
	gpio.write(pinMotorCCW, motor_OFF)
    --gpio.write(pinMotorCW, motor_OFF)
    pinLigando = pinMotorCW
    motorTmr:start()    
  end    
	
  motor.ligarCounterClockwise = function ()
    -- Aciona o motor
    status = 2 -- counterclockwise
    ligando = true
    gpio.write(pinMotorCW, motor_OFF)
    --gpio.write(pinMotorCCW, motor_OFF)
    pinLigando = pinMotorCCW
    motorTmr:start()    
  end

  motor.desligar = function ()
	-- desliga o motor
    pinLigando = -1
    gpio.write(pinMotorCCW, motor_OFF)
	gpio.write(pinMotorCW, motor_OFF)
	status = 0
  end

  motor.release = function ()
    motorTmr:stop()
    motorTmr:unregister()
    --print("motor.release()")
  end

end
