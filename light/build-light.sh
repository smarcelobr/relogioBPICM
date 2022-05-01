#!/bin/bash
# Execute esse script no terminal Ubuntu

# Xeonling / ubuntu
firmware_base=//mnt/d/smarc/Projetos/github/nodemcu/nodemcu-firmware
project_base=//mnt/d/smarc/Projetos/github/smarcelobr/relogioBPICM/light

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

# cria imagem LFS
echo Criando imagem LFS ...
cd ${project_base}/lfs/ || exit
${firmware_base}/luac.cross.int -o ../out/lfs.img -f *.lua

