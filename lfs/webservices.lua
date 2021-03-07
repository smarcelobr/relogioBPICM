---
--- Webservices para controle do relógio
--- Created by Sergio.
--- DateTime: 17/02/2021 13:44
---
do
    httpserver = require("httpserver")

    local mimeTypeTbl = {
        txt = 'text/plain',
        html = 'text/html',
        js = 'text/javascript',
        css = 'text/css',
        json = 'application/json'
    }

    local function sendJson(res, httpStatus, json)
        res:send(nil, httpStatus)
        res:send_header("Connection", "close")
        res:send_header("Content-Type", mimeTypeTbl.json)
        res:finish(json)
    end

    local function statusOnExecute(handlerData)
        local httpStatus = 200
        local ok, json = pcall(sjson.encode, r.status())
        if not ok then
            httpStatus = 500
            json = '{"msg":"falhou o encode"}'
        end
        sendJson(handlerData.res, httpStatus, json)
    end

    local function badRequestOnExecute(handlerData, bodyObj)
        -- 400: bad request
        sendJson(handlerData.res, 400, bodyObj.json or '{"msg":"json invalido no body"}')
    end

    --local function methodNotAllowedOnExecute(handlerData)
    --    sendJson(handlerData.res, 405, '{"msg":"http method inválido"}')
    --end
    --
    local function notFoundOnExecute(handlerData)
        sendJson(handlerData.res, 404, '{"msg":"não achei"}')
    end

    local function sendFileOnExecute(handlerData, bodyObj)
        local fileName = handlerData.req.url:sub(2)
        local posIni, posFim, extensao = fileName:find('%.(%a+)$')
        local fh = file.open(fileName..handlerData.tipoGZ)
        if fh then
            handlerData.res:send(nil, 200)
            handlerData.res:send_header("Connection", "close")
            handlerData.res:send_header("Content-Type", mimeTypeTbl[extensao or 'txt'])
            if (handlerData.tipoGZ=='.gz') then
                handlerData.res:send_header("Content-Encoding","gzip")
            end
            local acabou = false
            while (not acabou) do
                local linha = fh:readline()
                acabou = (linha == nil)
                if (not acabou) then
                    handlerData.res:send(linha);
                end
            end
            fh:close()
            fh = nil
            handlerData.res.finish()
        else
            handlerData.res:send(nil, 500)
            handlerData.res:send_header("Connection", "close")
            handlerData.res:send_header("Content-Type", mimeTypeTbl.txt)
            handlerData.res.finish("Falhou ao ler arquivo.") -- falhou ao abrir controle.html
        end

    end

    local function incOnExecute(handlerData, bodyObj)
        if (bodyObj and bodyObj.min) then
            rencoder.ptr.incrementDifMinutos(bodyObj.min)
            statusOnExecute(handlerData)
        else
            badRequestOnExecute(handlerData.res, {json='{"msg":"\'min\' não definido"}'})
        end
    end

    local function gdmOnExecute(handlerData, bodyObj)
        -- grava a diferenca em minutos entre o rencoder e os ponteiros no config.json
        rencoder.ptr.saveDifMinutos()
        statusOnExecute(handlerData)
    end

    local function lfmOnExecute(handlerData, bodyObj)
        r.lfm(); -- limpa o flag de erro no motor permitindo a retomada do funcionamento.
        statusOnExecute(handlerData)
    end

    local function setWifiOnExecute(handlerData, bodyObj)
        if (bodyObj and bodyObj.ssid and bodyObj.pwd) then
            cfg.set({'wifi','sta','ssid'}, bodyObj.ssid)
            cfg.set({'wifi','sta','pwd'}, bodyObj.pwd)
            sendJson(handlerData.res, 200, '{"ssid":"'.. bodyObj.ssid ..'","pwd":"'.. bodyObj.pwd ..'"}')
        else
            badRequestOnExecute(handlerData.res, {json='{"msg":"\'ssid\' ou \'pwd\' não definido"}'})
        end
    end

    local function getNomeOnExecute(handlerData, bodyObj)
        cfg.get({"nome"},
                function(v)
                    sendJson(handlerData.res, 200, '{"nome":"'.. (v.nome or '') ..'"}')
                end
        )
    end

    local function setNomeOnExecute(handlerData, bodyObj)
        if (bodyObj and bodyObj.nome) then
            cfg.set({'nome'}, bodyObj.nome)
            getNomeOnExecute(handlerData, nil)
        else
            badRequestOnExecute(handlerData.res, {json='{"msg":"\'nome\' não definido"}'})
        end
    end

    local function getWifiAps(handlerData, bodyObj)
        local function callbackGetAp(t)
            local ap_list = "["
            local primeiro = true
            for k, v in pairs(t) do
                if (primeiro) then
                    primeiro = false
                else
                    ap_list = ap_list .. ","
                end
                ap_list = ap_list .. '"' .. k .. '"'
            end
            sendJson(handlerData.res, 200,  (ap_list .. "]"));
        end

        wifi.sta.getap(callbackGetAp)
    end

    --[[
    Ajusta a hora do RTC em Unix Epoch (segundos)
    Body request: (exemplo abaixo muda para 19/03/2021 18:00:00 GMT-3:00)
      {"epoch": 1616187600 }
    --]]
    local function setTimeOnExecute(handlerData, bodyObj)
        if (bodyObj and bodyObj.epoch) then
            rtc.set(bodyObj.epoch)
            statusOnExecute(handlerData)
        else
            badRequestOnExecute(handlerData.res, {json='{"msg":"\'epoch\' não definido"}'})
        end
    end

    --[[
    Pausa o sistema (não movimenta a cada minuto).
    --]]
    local function pausarOnExecute(handlerData, bodyObj)
        r.pausar();
        statusOnExecute(handlerData)
    end

    --[[
    Continua o sistema após a pausa (movimenta a cada minuto).
    --]]
    local function continuarOnExecute(handlerData, bodyObj)
        r.continuar();
        statusOnExecute(handlerData)
    end

    local srvTbl = {
        GET_status = { onExecute = statusOnExecute },
        POST_nome = { onExecute = setNomeOnExecute },
        GET_nome = { onExecute = getNomeOnExecute },
        POST_inc = { onExecute = incOnExecute },
        POST_gdm = { onExecute = gdmOnExecute },
        POST_lfm = { onExecute = lfmOnExecute },
        POST_setwifi = { onExecute = setWifiOnExecute },
        GET_wifiAPs = { onExecute = getWifiAps},
        GET_File = { onExecute = sendFileOnExecute },
        POST_time = { onExecute = setTimeOnExecute },
        POST_pausar = { onExecute = pausarOnExecute},
        POST_continuar = { onExecute = continuarOnExecute}
    }

    httpserver.createServer(80, function(req, res)
        if req==nil or res==nil then
            return
        end
        print('http:{"t"="+R","m"="' .. req.method .. '","u"="' .. req.url .. '","h"="' .. node.heap() .. '"}')
        local handlerData = {
            req = req, res = res,
            bodyData = '',
            onExecute = nil
        }
        if (req.url == '/') then
            req.url = '/controle.html' -- pagina default
        end

        req.ondata = function(self, chunk)
            if (chunk) then
                -- concatena o bodydata (limitando a qtd de chars para nao travar o microcontrolador)
                if (#handlerData.bodyData < 300) then
                    handlerData.bodyData = handlerData.bodyData .. chunk
                end
            else
                -- terminou os dados, entao converte json para obj e executa
                local bodyObj = nil
                local ok = true
                if #handlerData.bodyData > 0 then
                    print('log:'..handlerData.bodyData)
                    ok, bodyObj = pcall(sjson.decode, handlerData.bodyData)
                end
                handlerData.bodyData = nil -- permite GC tirar da memoria
                if not ok then
                    handlerData.onExecute = badRequestOnExecute
                end
                collectgarbage()
                node.task.post(node.task.LOW_PRIORITY, function()
                    handlerData:onExecute(bodyObj)
                    bodyObj = nil
                    handlerData = nil
                end)
            end
        end

        local nome = req.url:sub(2)
        local serviceIdent = req.method .. '_' .. nome
        if (file.exists(nome..'.gz')) then
            handlerData.tipoGZ = '.gz';
            serviceIdent = req.method .. '_File' -- GET_File
        else if (file.exists(nome)) then
            handlerData.tipoGZ = '';
            serviceIdent = req.method .. '_File' -- GET_File
            end
        end
        if (srvTbl[serviceIdent]) then
            -- se o serviço estiver implementado:
            handlerData.onExecute = srvTbl[serviceIdent].onExecute
        else
            handlerData.onExecute = notFoundOnExecute
        end

    end)
end
