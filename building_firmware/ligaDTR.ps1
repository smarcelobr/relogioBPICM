
$port = New-Object System.IO.Ports.SerialPort
$port.PortName = "COM3"
$port.BaudRate = "74880"
$port.Parity = "None"
$port.DataBits = 8
$port.StopBits = 1
$port.ReadTimeout = 9000 # 9 seconds
$port.DtrEnable = $false

$port.open() #opens serial connection

Start-Sleep 2 # wait 2 seconds until Arduino is ready

# $port.Write("93c") #writes your content to the serial connection

try
{
  while($myinput = $port.ReadLine())
  {
  $myinput
  }
}

catch [TimeoutException]
{
# Error handling code here
}

finally
{
# Any cleanup code goes here
}

$port.Close() #closes serial connection
