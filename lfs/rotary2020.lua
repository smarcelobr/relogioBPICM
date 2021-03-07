print("loading rotary2020")
if (r and r.release) ~= nil then
    r.release()
end
r = {}
do

    require("motor")
    motor.desligar()
    require("util")
    require("app_led")
    require("app_wifi")
    require("gdate")
    require("relogioInternet")
    --require("configuracoes")
    require("rencoder")
    require("telnet"):open()
    require("webservices")

    led.piscar("loading")

    local falhaMotor = false
    local contaEncoder = 1 -- valor inicial deve ser maior que zero para nao pensar que o encoder esteja com defeito.
    local pausado = false
    local isBuscaHora = false

    local function status()
        return {
            ptr = rencoder.status(),
            rtc = rtc.status(),
            falhaMotor = falhaMotor,
            pausado = pausado,
            led = led.status(),
        }
    end

    local function printStatusJson()
        local ok, json = pcall(sjson.encode, status())
        print(json)
        json = nil
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

    local function acionaPonteiro(ptrTimer)

        local rtcGMIN, newSec = rtc.GMIN()

        if (newSec ~= nil) then
            local newInterval = math.max((60 - newSec), 5) * 1000
            ptrTimer:interval(newInterval)
        end

        local difGMIN = nil
        if (rencoder.GMIN() ~= nil and rtcGMIN ~= nil) then
            -- calcula atraso ou adianto
            difGMIN = calcDif(rencoder.GMIN(), rtcGMIN)
        end

        -- testa se ha uma falha mecanica
        -- (chegou o proximo minuto sem desligar o motor)
        if not pausado and contaEncoder == 0 then
            -- quando o contaEncoder é zero, indica que o motor não está girando com o encoder
            -- detectou falha no motor
            motor.desligar() -- desliga os motores por segurança.
            led.piscar("error1") -- Algo errado no mecanismo dos minutos.
            falhaMotor = true
        end

        if not falhaMotor then
            if not pausado and difGMIN then
                if (difGMIN < 0) then
                    -- esta atrasado ou certo?
                    contaEncoder = 0 -- reseta o contador. Quem incrementa é a funcao callback chamada pelo encoder
                    motor.ligarClockwise()
                else
                    if (difGMIN > 0) then
                        contaEncoder = 0 -- reseta o contador. Quem incrementa é a funcao callback chamada pelo encoder
                        motor.ligarCounterClockwise()
                    end
                end
            end
        end
    end

    -- aciona o ponteiro a cada minuto do raspberry
    local ponteiroTimer = tmr.create()
    if not ponteiroTimer:alarm(60 * 1000, tmr.ALARM_AUTO, acionaPonteiro) -- a cada minuto
    then
        print("problemas no ponteiroTimer")
    end

    local function encoderOnChange(GMIN, ptrMin, ptrHora)
        contaEncoder = contaEncoder + 1 -- indica que o motor e o encoder estão girando perfeitamente
        local difGMIN = 0
        if (GMIN ~= nil and rtc.GMIN() ~= nil) then
            -- calcula atraso ou adianto
            difGMIN = calcDif(GMIN, rtc.GMIN())
        end

        if isBuscaHora then
            if ptrHora ~= nil then
                -- Detectou a hora. Não precisa mais buscar.
                motor.desligar()
                isBuscaHora = false
                led.piscar("normal")
            else
                -- testa falha no mecanismo de deteção da hora
                if contaEncoder > 180 then
                    -- já rodou 180 minutos (3 voltas) e não achou a marcação da hora? Algum problema no mecanismo das horas
                    -- detectou falha no motor
                    motor.desligar() -- desliga os motores por segurança.
                    led.piscar("error2") -- algo errado no mecanismo das horas
                    falhaMotor = true
                end
            end
        else
            if (difGMIN == 0) then
                if not tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
                    -- desliga o motor apos 500ms para distanciar um pouco do edge.
                    motor.desligar()
                    led.piscar("normal")
                end)
                then
                    -- timer não funcionou... desliga agora.
                    motor.desligar()
                end
            end
        end
        printStatusJson();
    end

    rencoder.init(encoderOnChange)
    rtc.init(printStatusJson)

    local function pausar()
        pausado = true
    end

    local function continuar()
        pausado = false
    end

    local function buscarHoraCW()
        contaEncoder = 0 -- reseta o contador. Quem incrementa é a funcao callback chamada pelo encoder
        motor.ligarClockwise()
        isBuscaHora = true
        led.piscar("fast")
    end

    local function release()
        ponteiroTimer:stop()
        ponteiroTimer:unregister()
    end

    r.v = '1.0'
    r.pausar = pausar
    r.continuar = continuar
    r.encoderOnChange = encoderOnChange
    r.release = release
    r.buscarHoraCW = buscarHoraCW
    r.printStatusJson = printStatusJson
    r.status = status
    r.lfm = function() -- Retomar o funcionamento do motor
        -- limpa o flag de erro do motor permitindo a retomada do funcionamento.
        falhaMotor = false
        -- se estava buscando a hora, religa o motor
        if isBuscaHora then
            buscarHoraCW()
        end
    end

    buscarHoraCW()

end
