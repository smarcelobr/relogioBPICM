--[[SPLIT MODULE telnet]]

--[[  A telnet server   T. Ellison,  June 2019

This version of the telnet server demonstrates the use of the new stdin and stout
pipes, which is a C implementation of the Lua fifosock concept moved into the
Lua core.  These two pipes are referenced in the Lua registry.

]]
--luacheck: no unused args
print("loading telnet")
local M = {}
local modname = ...
local function telnet_session(socket)
  local node = node
  local stdout

  local function output_CB(opipe)   -- upval: socket
    stdout = opipe
    local rec = opipe:read(1400)
    if rec and #rec > 0 then socket:send(rec) end
    return false -- don't repost as the on:sent will do this
  end

  local function onsent_CB(skt)     -- upval: stdout
    local rec = stdout:read(1400)
    if rec and #rec > 0 then skt:send(rec) end
  end

  local function disconnect_CB(skt) -- upval: socket, stdout
    node.output()
    socket, stdout = nil, nil -- set upvals to nl to allow GC
  end

  node.output(output_CB, 1) -- 2o.parâmetro: 0-no serial output / 1- serial output tb
  socket:on("receive", function(_,rec) node.input(rec) end)
  socket:on("sent", onsent_CB)
  socket:on("disconnection", disconnect_CB)
  print(("Bem vindo ao Relogio da Basilica (%d mem free)"):format(
        node.heap()))
end

function M.open(this, ssid, pwd, port)
  local tmr, wifi, uwrite = tmr, wifi, uart.write
  if ssid then
    wifi.setmode(wifi.STATION, false)
    wifi.sta.config { ssid = ssid, pwd  = pwd, save = false }
  end
  local t = tmr.create()
  t:alarm(1000, tmr.ALARM_AUTO, function()
    if (wifi.getmode() == wifi.SOFTAP or 
        wifi.sta.status() == wifi.STA_GOTIP) then
      t:unregister()
      t=nil
      print(("Telnet server started (%d mem free)"):format(
             node.heap()))
      M.svr = net.createServer(net.TCP, 600) 
       --[[ 600 ->10 minutos de inatividade 
             para desconectar automaticamente.
       --]]
      M.svr:listen(port or 23, telnet_session)
    else
      --uwrite(0,".")
    end
  end)
end

function M.close(this)
  if this.svr then this.svr:close() end
  package.loaded[modname] = nil
end

return M
--[[SPLIT HERE]]
