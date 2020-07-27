-- baseado em https://github.com/smarcelobr/puredate.js/blob/master/puredate.js
gdate = {}
do
  --[[
     gdate.g(ano, mes, dia) 
     
     Converte uma data em um numero inteiro 
     que representa o numero de dias.
     
     Essa representação, além de ocupar menos memória, facilita 
     descobrir a diferença de dias entre duas datas.     
  --]]
  gdate.g = function (ano, mes, dia) 
     mes = (mes + 9) % 12;
     ano = ano - math.floor(mes/10); -- (a//b) forces integer division at a/b
     return 365*ano + math.floor(ano/4) - math.floor(ano/100) + 
                      math.floor(ano/400) + math.floor((mes*306 + 5)/10) + ( dia - 1 );
  end
  
  --[[
    gdate.gmin(hora, minuto)
    
    Converte uma dada hora num inteiro que representa o minuto. 
    
  --]]
  gdate.gmin = function (hora, minuto)
    return ((hora%24)*60) + minuto
  end
end
