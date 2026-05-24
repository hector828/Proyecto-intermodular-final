#!/bin/bash
trap '' SIGINT

source /etc/telegram.conf

msg="$(who -m | awk '{print $1 $5}') ha iniciado de sesión: $(date)"
codigo=$(shuf -i 10000-99999 -n 1)

curl -s -X POST $URL -d chat_id="$CHAT_ID" -d text="$msg" > /dev/null 2>&1
curl -s -X POST $URL -d chat_id="$CHAT_ID" -d text="Codigo de verificacion: $codigo" > /dev/null 2>&1

echo -n "Cual es el codigo de verificacion:"
read veri

if [[ $codigo -eq $veri || $key -eq $veri ]]
then
	echo "Inicio corecto"
elif [ $codigo -ne $veri ]
then
	echo "Codigo de incorecto"
	exit
else
	echo "Solo se puede escribir numeros"
	exit
fi

echo "===Usuarios conectados==="
who  | awk -F" " '{print $1, $2, $3, $4}'
trap - SIGINT
