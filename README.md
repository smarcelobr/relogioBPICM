# relogioBPICM

Programa em Lua para controle automatizado do Relógio da Basílica usando ESP8266 (ESP-12) e [nodemcu](https://nodemcu.readthedocs.io).

_O projeto ainda está em desenvolvimento. Vou explicar melhor em breve._

Para contribuir:

    git clone https://github.com/smarcelobr/relogioBPICM.git
    

Putty comandos: 

    cfg.get({"wifi","sss"},
       function(v)
         print(pairToStr("resultado",v))
       end
    )
