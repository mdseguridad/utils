root@themole:~/scripts# cat test_tunel.sh 
#!/bin/bash

proxyIP=X.X.X.X
# Datos telegram
MASTER=<CHATID>
TOKEN=<TELEGRAM TOKEN>

testResult=$(curl --connect-timeout 5 -s  -x http://$proxyIP:80 http://gateway.zscaler.net/vpntest)
if [ "$testResult" != "OK" ]
then
  echo "Error en el tunnel"
  echo "Probando si ibamos por el tunel 1"
  testTunel=$(ip route get 185.46.212.88 | head -1 | awk '{print $5}')
  if [ "$testTunel" = "gre1" ]
  then
    echo "Se usaba el tunel gre1, se cambia al secundario"
    #Borramos las rutas
    ip route del 185.46.212.88/32 via 172.20.228.130
    ip route del 185.46.212.88/32 via 172.20.228.134
    # Paramos 1 segundo
    sleep 1
    #Creamos las rutas con la nueva prioridad
    ip route add  185.46.212.88/32 via 172.20.228.134 metric 100
    ip route add  185.46.212.88/32 via 172.20.228.130 metric 200
    curl -i -X GET "https://api.telegram.org/bot${TOKEN}/sendMessage?chat_id=${MASTER}&parse_mode\
=Markdown&text=*Estado Tunel*%0ASeñor, ERROR en tunel  GRE1 en el servidor _${HOSTNAME}_, se pasa al backup"
  elif [ "$testTunel" = "gre2" ]
  then
    echo "Se usaba el tunel gre2, se cambia al principal"
    #Borramos las rutas
    ip route del 185.46.212.88/32 via 172.20.228.134
    ip route del 185.46.212.88/32 via 172.20.228.130
    # Paramos 1 segundo
    sleep 1
    #Creamos las rutas con la nueva prioridad
    ip route add  185.46.212.88/32 via 172.20.228.130 metric 100
    ip route add  185.46.212.88/32 via 172.20.228.134 metric 200
    curl -i -X GET "https://api.telegram.org/bot${TOKEN}/sendMessage?chat_id=${MASTER}&parse_mode\
=Markdown&text=*Estado Tunel*%0ASeñor, ERROR en tunel GRE2 en el servidor _${HOSTNAME}_, se vuelve al principal"
  else
    echo "Error terrible!!"
    #Borramos las rutas
    ip route del 185.46.212.88/32 via 172.20.228.134
    ip route del 185.46.212.88/32 via 172.20.228.130
    # Paramos 1 segundo
    sleep 1
    #Creamos las rutas con la nueva prioridad
    ip route add  185.46.212.88/32 via 172.20.228.130 metric 100
    ip route add  185.46.212.88/32 via 172.20.228.134 metric 200
    curl -i -X GET "https://api.telegram.org/bot${TOKEN}/sendMessage?chat_id=${MASTER}&parse_mode\
=Markdown&text=*Estado Tunel*%0ASeñor, ERROR TERRIBLE GRE, en el servidor _${HOSTNAME}_"
  fi
else
  echo "Todo OK"
  #curl -i -X GET "https://api.telegram.org/bot${TOKEN}/sendMessage?chat_id=${MASTER}&parse_mode\
 #=Markdown&text=*Estado Tunel*%0ASeñor, tunel GRE en el servidor _${HOSTNAME}_, correcto"
fi
