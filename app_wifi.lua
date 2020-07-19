print("loading wifi")
require("relogioInternet")
  
  wifi.sta.disconnect()
  wifi.eventmon.register( wifi.eventmon.STA_CONNECTED, rtc.wifiOnConnect )
  wifi.setmode(wifi.STATION)
  wifi.sta.autoconnect(0) -- desabilita a conexao automatica  
  
  local station_cfg={}
  station_cfg.ssid="jardimdomeier"
  station_cfg.pwd="sergioeluciene"
  station_cfg.save=true

  wifi.sta.config(station_cfg)

  -- agora tenta conectar no wifi
  wifi.sta.connect()
