# Relogio Essencial 

Pasta com o arquivo com o que é essencial para o 
funcionamento do relógio. Essa versão se mostrou 
necessária depois de muitas falhas na versão original 
que havia muitas features, inclusive interface com o 
usuario. Essa versão busca ser mínima e deixar 
que facilidades como a interface ao usuário fique 
sob responsabilidade de outro computador mais livre
como um Raspberry PI.

## Firmware nodemcu

Para criar o firmware:

1. vá até https://nodemcu-build.com/.

2. Escolher os módulos:

- bit, encoder, file, GPIO, HTTP, net, node, RTC time, SJSON, SNTP, SPI, timer, UART, WiFi.

3. LFS options:

- LFS Size: 128KB
- SPIFFS base: 0, start right after firmware
- SPIFFS size: all free flash

4. Aguarde o aviso por e-mail e realize o download.

5. Faz o upload no ESP8266 usando o comando:

_(powershell)_

    esptool.py --port COM3 write_flash -fm dio 0x00000 C:\Users\smarc\Downloads\nodemcu-release-14-modules-2021-11-27-23-49-50-integer.bin
    esptool.py --port COM3 write_flash -fm dio 0x00000 D:\smarc\Projetos\github\smarcelobr\relogioBPICM\building_firmware\nodemcu-release-14-modules-2021-12-20-22-38-55-integer.bin

## Build & Deploy

### Build

Ao executar o script build-light.sh, a pasta out-light terá
o conteúdo para ser copiado para o SSPIFS do nodemcu.

    [No terminal Ubuntu / XeonLing]

    $ cd /home/sergio/IdeaProjects/relogioBPICM/light
    $ ./build-light.sh


### Deploy

    [cmd / XeonLing ]
    D:\>cd D:\smarc\Projetos\github\smarcelobr\relogioBPICM\light
    D:\smarc\Projetos\github\smarcelobr\relogioBPICM\light>nodemcu-tool -p COM3 upload out/*
    [NodeMCU-Tool]~ Connected
    [device]      ~ Arch: esp8266 | Version: 3.0.0 | ChipID: 0x64b562 | FlashID: 0x16405e
    [NodeMCU-Tool]~ Uploading "out/config.lua" >> "config.lua"...
    [connector]   ~ Transfer-Mode: base64
    [NodeMCU-Tool]~ Uploading "out/init.lua" >> "init.lua"...
    [NodeMCU-Tool]~ Uploading "out/lfs.img" >> "lfs.img"...
    [NodeMCU-Tool]~ Uploading "out/util.lua" >> "util.lua"...
    [NodeMCU-Tool]~ Bulk File Transfer complete!
    [NodeMCU-Tool]~ disconnecting

### LFS load 

    [cmd / XeonLing ]
    D:\smarc\Projetos\github\smarcelobr\relogioBPICM\light>nodemcu-tool -p COM3 terminal
    [terminal]    ~ Starting Terminal Mode - press ctrl+c to exit
    
    > file.rename('not_ok.flag','ok.flag'); print(node.LFS.reload("lfs.img"))