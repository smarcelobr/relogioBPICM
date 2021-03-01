#!/bin/bash
# Execute esse script no terminal Ubuntu

cd /home/sergio/IdeaProjects/relogioBPICM || exit

# copia conteudo lua
cp init.lua ./out/
cp util.lua ./out/
cp config.json ./out/

# compacta conteudo web
gzip -9 -c configuracao.html >./out/configuracao.html.gz
gzip -9 -c configuracao.js >./out/configuracao.js.gz
gzip -9 -c controle.js >./out/controle.js.gz
gzip -9 -c controle.html >./out/controle.html.gz
gzip -9 -c util.js >./out/util.js.gz
gzip -9 -c styles.css >./out/styles.css.gz

# cria imagem LFS
cd /home/sergio/IdeaProjects/relogioBPICM/lfs/ || exit
//mnt/c/Users/smarc/esp8266/nodemcu-firmware/luac.cross.int -o ../out/lfs.img -f *.lua

