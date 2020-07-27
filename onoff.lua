do
  if file.exists('ok.flag') then
    if file.rename('ok.flag', 'not.flag') then
       print("mode is OFF!")
    else 
       print("falha ao fazer OFF")
    end
  else
    if file.rename('not.flag','ok.flag') then
       print("mode is ON!")
    else 
       print("falha ao fazer ON")
    end
  end
end
