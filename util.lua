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
 