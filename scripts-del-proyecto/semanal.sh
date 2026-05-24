#!/bin/bash

id=$(id -u)
if (( $id != 0 ))
then
        echo "Tienes que ser administrador"
        exit 0
fi

source /etc/telegram.conf
wall "El sistema va realizar el mantenimiento semanal"
servicios=("apache2" "fail2ban" "slapd" "sssd" "ufw")
fichero="/tareas/registros/registro$(date +"%d-%m-%Y_%H-%M").txt"
echo "---Registro semanal: $(date +"%d-%m-%Y_%H:%M")---" > $fichero
apt update && apt upgrade -y

for i in ${servicios[@]}
do
	systemctl restart $i
	echo "Servicio $i reiniciado correctamente" >> $fichero
done
echo >> $fichero
echo "===Usuarios iniciados durante la semana===" >> $fichero
last -s -7days >> $fichero
echo >> $fichero

if [ -f /var/run/reboot-required ]
then
	echo "**Reinicio necesario**" >> $fichero
	echo >> $fichero
fi

ufw default deny incoming
ufw default allow outgoing
echo "===Reconfigurando firewall==="
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 389/tcp
ufw allow 636/tcp

echo >> $fichero
echo "===Puertos abiertos===" >> $fichero
ss -tuln | awk '{print $1, $2, $5}' >> $fichero
echo >> $fichero

msg="$(cat $fichero)"


/tareas/backup.sh

echo "Copia de seguirdad completada" >> $fichero

curl -s -X POST $URL -d chat_id="$CHAT_ID" -d text="$msg" > /dev/null 2>&1

cat $fichero
