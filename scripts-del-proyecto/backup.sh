#!/bin/bash

id=$(id -u)
if (( $id != 0 ))
then
        echo "Tienes que ser administrador"
        exit 0
fi

fecha=$(date +"%d-%m-%Y_%H-%M")
backup=("backup-web" "backup-home" "backup-sftp")

for i in ${backup[@]}
do
	case $i in
		backup-web)
			directorio="/var/www/arquitectotec.es"
		;;
		backup-home)
			directorio="/home/hectorad"
		;;
		backup-sftp)
			directorio="/sftp/documentos"
		;;
		*)
			echo "error"
		;;
	esac
	nombre="/backups/$i/$i$fecha.tar.gz"
	ruta="/backups/$i"
	tar -zcf $nombre $directorio > /dev/null 2>&1
	find "$ruta" -type f -mtime +30 -delete
done
