-- util.lua - Varias funcoes utilitarias

-- converte uma table em string
function pairToStr(k, v)
  local str
     str = (k or 'nil') .. "="
  if type(v)=="table" then
    str = str .. "{"
    local primeiro=true
	for vk,vv in pairs(v) do
	  if primeiro then
	     primeiro=false
	  else
	     str = str .. ","
	  end
	  str = str .. pairToStr(vk, vv) 
	end
	str = str .. "}"
  else
    local strFmt = '%s%s'
    if type(v)=="string" then
      strFmt = '%s"%s"'
    end
    str = strFmt:format(str, tostring(v))
  end
  return str
end
 
function listfs()
    local l = file.list();
    for k,v in pairs(l) do
        print("name:"..k..", size:"..v)
    end
end

-- mostra o conteudo de um arquivo no SPIFFS
function cat(filename)
    local fh = file.open(filename)
    if fh then
        local acabou = false
        while (not acabou) do
            local linha = fh:readline()
            acabou = (linha==nil)
            if (not acabou) then
              print(linha)
            end
        end
        file.close()
    end
end

function listAPs()

    local function callbackGetAp(t)
      local ap_list = "ap-list:["
      local primeiro = true
      for k,v in pairs(t) do
        if (primeiro) then
          primeiro = false
        else
          ap_list = ap_list .. ","
        end
        ap_list = ap_list .. '"'..k..'"'
      end
      print(ap_list .. "]")
    end

    wifi.sta.getap(callbackGetAp)
end

-- funcoes para transferir arquivos
-- inicia uma area temporaria para transferencia
function fto()
  ft = file.open("tranfer.tmp", "w+")
end
-- transfere um texto
function ftt(dado)
  if (ft) then
    ft:write(dado)
  end
end
-- transfere um binario (base64)
function ftb(dadoBase64)
  if (ft) then
    ft:write(encoder.fromBase64(dadoBase64))
  end
end
-- finaliza dando o nome finaliza
function ftc(nome)
  if (ft) then
    ft:close()
    file.rename("transfer.tmp", nome)
  end
end
