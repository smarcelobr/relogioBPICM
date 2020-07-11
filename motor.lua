local motor
do
	local pinMotor1, pinMotor2 = 1, 2

	gpio.mode(pinMotor1,gpio.OUTPUT)
	gpio.mode(pinMotor2,gpio.OUTPUT)  
	gpio.write(pinMotor1,gpio.HIGH)
	gpio.write(pinMotor2,gpio.HIGH)

	local emMovimento = false

  local function ligaMotor()
	-- Aciona o motor
	emMovimento = true
	gpio.write(pinMotor1, gpio.LOW)
	gpio.write(pinMotor2, gpio.LOW)
  end

  local function desligaMotor() 
	-- desliga o motor
	gpio.write(pinMotor1, gpio.HIGH)
	gpio.write(pinMotor2, gpio.HIGH)
	emMovimento = false
  end
  
  local function getEmMovimento()
	return emMovimento
  end
  
  motor = {
    emMovimento = getEmMovimento,
	ligaMotor = ligaMotor,
	desligaMotor = desligaMotor
  }
end
return motor