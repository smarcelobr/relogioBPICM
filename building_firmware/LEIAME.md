## BUILDING FIRMWARE 

Primeiro, deve-se fazer as mudanças nos arquivos de header (.h)
como o user_config.h, user_modules.h e outros. Os arquivos que
alterei para o projeto do  relógio estão na mesma página que esse
`LEIAME.md`.

---
## nodemcu-build.com

1. vá até https://nodemcu-build.com/.

2. Escolher os módulos:

 bit encoder file gpio http net node rtctime sjson sntp spi tmr uart wifi.

3. LFS options:

- LFS Size: 128KB
- SPIFFS base: 0, start right after firmware
- SPIFFS size: all free flash

4. Aguarde o aviso por e-mail e realize o download. 

5. Faz o upload no ESP8266 usando o comando:

_(powershell)_

    esptool.py --port COM3 write_flash -fm dio 0x00000 C:\Users\smarc\Downloads\nodemcu-release-14-modules-2021-11-27-23-49-50-integer.bin

## RASPBERRY PI (*nux)

Comandos para compilar o firmware do nodemcu no RASPBERRY:

    $ export PATH=$PATH:/home/pi/aplicativos/esp8266-linux-arm_32-20191111.0/bin

    $ make TOOLCHAIN_ROOT=~/xtensa/esp8266-linux-arm_32-20191111.0/

(ref.: https://github.com/nodemcu/nodemcu-firmware/issues/2958)



### FLASHING FIRMWARE (raspi)

Para saber o tamanho do FLASH:

    $ cd /home/pi/.local/lib/python3.7/site-packages
    $ python3.7 esptool.py --port /dev/ttyUSB0 flash_id

Para fazer a gravação do firmware (flashing):

    esptool.py --port <serial-port-of-ESP8266> write_flash -fm <flash-mode> 0x00000 <nodemcu-firmware>.bin

    $ cd /home/pi/.local/lib/python3.7/site-packages
    $ python3.7 esptool.py --port /dev/ttyUSB0 write_flash -fm dio 0x00000 /home/pi/github/nodemcu-firmware/bin/0x00000.bin
    $ esptool.py --port /dev/ttyUSB0 write_flash -fm dio 0x10000 /home/pi/github/nodemcu-firmware/bin/0x10000.bin

### Fazendo a imagem do LFS (raspi)

    $ cd /home/pi/esp8266/projetos/relogioBPICM/lfs
    $ /home/pi/github/nodemcu-firmware/luac.cross.int -o lfs.img -f *.lua

#### UPLOAD arquivos para SPIFFS (raspi)

    $ nodemcu-tool upload --port=/dev/ttyUSB0 lfs.img

Toda a vez que atualizar a imagem do LFS, deve executar o seguinte comando no nodemcu:

_(terminal do nodemcu)_

    > node.flashreload("lfs.img")

uma alternativa para executar o comando acima usando o nodemcu-tool:

    $ nodemcu-tool --port=/dev/ttyUSB0 run reload_lfs.lua

O nodemcu vai resetar automaticamente.

---
## WINDOWS 10 e Docker 

Instruções no link: https://nodemcu.readthedocs.io/en/master/build/
e https://hub.docker.com/r/marcelstoer/nodemcu-build/

### TESTAR A CONEXÃO COM ESP8266 (win)

NATALENE (power shell):
    
     PS C:\Users\smarc> esptool.py.exe --port COM3 flash_id
     esptool.py v3.0
     Serial port COM3
     Connecting....
     Detecting chip type... ESP8266
     Chip is ESP8266EX
     Features: WiFi
     Crystal is 26MHz
     MAC: 5c:cf:7f:18:d0:70
     Uploading stub...
     Running stub...
     Stub running...
     Manufacturer: e0
     Device: 4016
     Detected flash size: 4MB
     Hard resetting via RTS pin...


### NOVO FIRMWARE 

1) Abrir o PowerShell e ir na pasta onde está o clone de https://github.com/nodemcu/nodemcu-firmware

> D:
> cd \smarc\ESP8266\nodemcu-firmware

2) executar o comando:

#### XPTO bash

    $ docker run --rm -ti -v D:\\smarc\\ESP8266\\nodemcu-firmware:/opt/nodemcu-firmware marcelstoer/nodemcu-build build
    docker run --rm -ti -v c:\\Users\\Public\\trabalho\\projetos\\github\\nodemcu-firmware:/opt/nodemcu-firmware marcelstoer/nodemcu-build build

#### Xeonling Powershell

    docker run --rm -ti -v D:\smarc\Projetos\github\nodemcu\nodemcu-firmware:/opt/nodemcu-firmware marcelstoer/nodemcu-build build

-- alternativa caso a pasta atual ($pwd) já seja a do firmware :

    docker run --rm -ti -v ${pwd}:/opt/nodemcu-firmware marcelstoer/nodemcu-build build

#### NATALENE PowerShell:

    docker run --rm -ti -v c:\Users\smarc\esp8266\nodemcu-firmware:/opt/nodemcu-firmware marcelstoer/nodemcu-build build

_( No windows, o Docker só irá conseguir fazer o mount de "D:\\smarc\\ESP8266\\nodemcu-firmware" se
ele for uma das pastas da lista de sharing das configurações do Docker Desktop.)_

#### NATALENE Ubuntu terminal

    $ cd /home/sergio/IdeaProjects/relogioBPICM/lfs/
    $ //mnt/c/Users/smarc/esp8266/nodemcu-firmware/luac.cross.int -o ../out/lfs.img -f *.lua

3) pegar os dois binários que estarão na pasta D:\smarc\ESP8266\nodemcu-firmware\bin
- 0x00000.bin will contain just the firmware.
- 0x10000.bin will contain the SPIFFS.

### FLASHING FIRMWARE 

Análogo ao do Raspberry, usando o esptool.py

_(powershell ou cmd)_

    > esptool.py --port COM3 write_flash -fm dio 0x00000 D:\smarc\ESP8266\nodemcu-firmware\bin\0x00000.bin
    > esptool.py --port COM3 write_flash -fm dio 0x10000 D:\smarc\ESP8266\nodemcu-firmware\bin\0x10000.bin

#### NATALENE PowerShell:

    $ esptool.py --port COM3 write_flash -fm dio 0x00000 c:\Users\smarc\esp8266\nodemcu-firmware\bin\0x00000.bin
    $ esptool.py --port COM3 write_flash -fm dio 0x10000 c:\Users\smarc\esp8266\nodemcu-firmware\bin\0x10000.bin

Alternativa, gravando o binário completo:

    esptool.py --port COM3 write_flash -fm dio 0x00000 c:\Users\smarc\esp8266\nodemcu-firmware\bin\nodemcu_integer_release_20201227-2216.bin

Apagar o flash antes de gravar pode corrigir problemas de boot

    esptool.py --port COM3 erase_flash


#### NOVO LFS 


    > docker run --rm -ti -v D:\\smarc\\ESP8266\\nodemcu-firmware:/opt/nodemcu-firmware -v D:\\smarc\\IdeaProjects\\relogioBPICM\\lfs:/opt/lua marcelstoer/nodemcu-build lfs-image

NATALENE:

    docker run --rm -ti -v c:\Users\smarc\esp8266\nodemcu-firmware:/opt/nodemcu-firmware -v \\wsl$\Ubuntu\home\sergio\IdeaProjects\relogioBPICM\lfs:/opt/lua marcelstoer/nodemcu-build lfs-image

XeonLing POWERSHELL:

    cd D:\smarc\Projetos\github  (<--pasta atual = $pwd)
    docker run --rm -ti -v ${pwd}\nodemcu\nodemcu-firmware:/opt/nodemcu-firmware -v ${pwd}\smarcelobr\relogioBPICM\lfs:/opt/lua marcelstoer/nodemcu-build lfs-image


#### Uploading files to SPIFFS 

Igual ao do raspberry, usando o nodemcu-tool.

    > cd D:\smarc\IdeaProjects\relogioBPICM\lfs
    > nodemcu-tool upload --port=COM3 LFS_integer_20200921-0058.img --remotename lfs.img
    > nodemcu-tool -p COM3 run reload_lfs.lua
   
ou, no terminal do nodemcu:

    > print(node.LFS.reload("lfs.img"))
    > old: node.flashreload("lfs.img")

---

## NATELENE build script (folder out)

### [No terminal Ubuntu]

    $ cd /home/sergio/IdeaProjects/relogioBPICM
    $ ./build.sh

Esse build.sh copia para a pasta ./out todos os arquivos necessários já compactados e o lua.img já feito.

Para transferir para o nodemcu, tem que ser pelo PowerShell através dos comandos abaixo:

### [No Powershell]

    $ cd \\wsl$\Ubuntu\home\sergio\IdeaProjects\relogioBPICM
    $ nodemcu-tool upload --port=COM3 ./out/lfs.img
    $ nodemcu-tool upload --port=COM3 ./out/*.gz
    $ nodemcu-tool upload --port=COM3 ./out/*.lua
    $ nodemcu-tool upload --port=COM3 ./out/*.json

---

## Comandos uteis para usar no terminal com o ESP8266 

Para acionar o terminal:

    $ nodemcu-tool -p COM3 -b 115200 terminal

_se o baudrate for diferente:_

    $ nodemcu-tool -p COM3 -b 74880 terminal


Listar arquivos: (requer util.lua)

$ dofile("util.lua")    
$ listfs()

Excluir um arquivo:

    $ file.remove("lfs.img")

Renomear Arquivo:

    file.rename("LFS_integer_20200921-0020.img","lfs.img")


desligar o motor:

	gpio.mode(1,gpio.OUTPUT);
	gpio.write(1,gpio.HIGH);
	gpio.mode(2,gpio.OUTPUT);
	gpio.write(2,gpio.HIGH)

cancelar a execução ao iniciar:

    file.rename('ok.flag','not_ok.flag')

retomar a execução normal:

    file.rename('not_ok.flag','ok.flag'); node.restart()

para acertar o ssid do wifi:

    cfg.set({'wifi','sta','ssid'}, 'jardimdomeier'); cfg.set({'wifi','sta','pwd'}, 'sergioeluciene'); node.restart()

modo do wifi:

    print(wifi.getmode());
    print(wifi.sta.getstatus());

Resolver DNS:

    net.dns.resolve("www.cachambi.com.br", function(sk, ip)
        if (ip == nil) then print("DNS fail!") else print(ip) end
    end)

