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
    if file.open(filename) then
        print(file.read())
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
