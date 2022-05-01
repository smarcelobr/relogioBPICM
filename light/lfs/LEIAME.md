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

    $ cd /home/sergio/IdeaProjects/relogioBPICM/light
    $ nodemcu-tool -p COM3 upload *.lua
    $ nodemcu-tool -p COM3 