#!/bin/bash
# Execute esse script no terminal Ubuntu

# Xeonling / ubuntu
firmware_base=//mnt/d/smarc/Projetos/github/nodemcu/nodemcu-firmware
project_base=//mnt/d/smarc/Projetos/github/smarcelobr/relogioBPICM

# NATALENE / ubuntu ?
#firmware_base=//mnt/c/Users/smarc/esp8266/nodemcu-firmware/
#project_base=/home/sergio/IdeaProjects/relogioBPICM

cd ${project_base} || exit

if [ ! -d out ]; then
  echo Criando pasta /out ...
  mkdir out
fi

echo Copiando conteudo lua ...
# copia conteudo lua
cp init.lua ./out/
cp util.lua ./out/
cp config.json ./out/

echo Copiando conteudo estático ...
# compacta conteudo web
gzip -9 -c configuracao.html >./out/configuracao.html.gz
gzip -9 -c configuracao.js >./out/configuracao.js.gz
gzip -9 -c controle.js >./out/controle.js.gz
gzip -9 -c controle.html >./out/controle.html.gz
gzip -9 -c util.js >./out/util.js.gz
gzip -9 -c styles.css >./out/styles.css.gz

# cria imagem LFS
echo Criando imagem LFS ...
cd ${project_base}/lfs/ || exit
${firmware_base}/luac.cross.int -o ../out/lfs.img -f *.lua

