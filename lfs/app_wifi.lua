print("loading wifi")
require("configuracoes")
do  
  local connectWiFi = function( config )
    print("connectWiFi: BEGIN")
    print(pairToStr("config",config))
    local configDefault = {wifi={
       sta=nil,
       ap={
           ssid= "Relogio BPICM",
           auth= wifi.OPEN,
           channel= 6,
           hidden= false,
           save=false
        }
      }}
    
    if config==nil then
      print("connectWiFi: use default")
      config = configDefault
    end
    
    setmetatable(config, {
       __index = function (table, key)
           print("connectWiFi: get " .. key .. " default")
           return configDefault[key]
       end
    })
    
    if config.wifi.sta ~= nil then
      print("modo station")
      wifi.setmode(wifi.STATION)
    
      print("wifi connecting: ssid=" .. config.wifi.sta.ssid)
      wifi.sta.config(config.wifi.sta)

      -- agora tenta conectar no wifi
      wifi.sta.connect()
    else
      wifi.setmode(wifi.SOFTAP)
      wifi.ap.config(config.wifi.ap)
      
      local cfgIP =
      {
        ip="192.168.1.1",
        netmask="255.255.255.0",
        gateway="192.168.1.1"
      }
      wifi.ap.setip(cfgIP)

      local dhcp_config ={}
      dhcp_config.start = "192.168.1.100"
      wifi.ap.dhcp.config(dhcp_config)
      
      wifi.ap.dhcp.start()
      
      print("wifi em modo AP: ssid=" .. config.wifi.ap.ssid)
    end
    print("connectWiFi: END")
  end

  wifi.sta.disconnect()
  wifi.sta.autoconnect(0) -- desabilita a conexao automatica  
  wifi.setphymode(wifi.PHYMODE_G)
  
  local country_info={}
  country_info.country="BR"
  country_info.start_ch=1
  country_info.end_ch=13
  country_info.policy=wifi.COUNTRY_AUTO;
  wifi.setcountry(country_info)
        
  print("wifi.cfg:GET")
  cfg.get({"wifi"}, connectWiFi)
end
