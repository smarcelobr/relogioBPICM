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
        css = 'text/css'
    }

    local function sendJson(res, httpStatus, json)
        res:send(nil, httpStatus)
        res:send_header("Connection", "close")
        res:send_header("Content-Type", "application/json")
        if (json) then
            res:send(json)
        end
        res:finish()
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

    local function methodNotAllowedOnExecute(handlerData)
        sendJson(handlerData.res, 405, '{"msg":"http method inválido"}')
    end

    local function notFoundOnExecute(handlerData)
        sendJson(handlerData.res, 404, '{"msg":"não achei"}')
    end

    local function incOnExecute(handlerData, bodyObj)
        if (bodyObj and bodyObj.min) then
            rencoder.ptr.incrementDifMinutos(bodyObj.min)
            statusOnExecute(handlerData)
        else
            badRequestOnExecute(handlerData.res, {json='{"msg":"\'min\' não definido"}'});
        end
    end

    local srvTbl = {
        inc = { method = 'POST', onExecute = incOnExecute },
        status = { method = 'GET', onExecute = statusOnExecute }
    }

    local function sendFileOnExecute(handlerData)
        local fileName = handlerData.req.url:sub(2)
        local pontoPos = fileName:find('.')
        local extensao = 'txt'; -- padrão
        if pontoPos then
            extensao = fileName:sub(pontoPos + 1);
        end
        local fh = file.open(fileName)
        if fh then
            handlerData.res:send(nil, 200)
            handlerData.res:send_header("Connection", "close")
            handlerData.res:send_header("Content-Type", mimeTypeTbl[extensao])
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
            handlerData.res:send_header("Content-Type", 'text/plain')
            handlerData.res.finish("Falhou ao ler arquivo.") -- falhou ao abrir controle.html
        end

    end

    httpserver.createServer(80, function(req, res)
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

                node.task.post(node.task.LOW_PRIORITY, function()
                    handlerData:onExecute(bodyObj)
                    bodyObj = nil
                end)
            end
        end

        local nome = req.url:sub(2)
        local expectedMethod = "GET"
        if (file.exists(nome)) then
            handlerData.onExecute = sendFileOnExecute
        else
            if (srvTbl[nome]) then
                -- testa se é serviço
                handlerData.onExecute = srvTbl[nome].onExecute
                expectedMethod = srvTbl[nome].method
            else
                handlerData.onExecute = notFoundOnExecute
            end
        end

        if not req.method == expectedMethod then
            -- metodo HTTP invalido?
            handlerData.onExecute = methodNotAllowedOnExecute
        end

    end)
end
