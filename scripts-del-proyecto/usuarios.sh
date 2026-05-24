#!/bin/bash

id=$(id -u)
if (( $id != 0 ))
then
	echo "Tienes que ser administrador"
	exit 0
fi

echo "¿Que quieres hacer?"
echo "1 - Crear un usuario del sistema"
echo "2 - Crear un usuario en LDAP"
echo "3 - Borrar un usuario del sistema"
echo "4 - Borrar un elemento del ldap"
echo -n "Elige un numero:"
read opcion

case $opcion in
	1)
                echo "Este usuario no existe"
		echo "Creando un usuario"
        	echo -n "Nombre de usuario: "
        	read usuario
	        existe=$(getent passwd $usuario | wc -l)
		if [ $existe -eq 0 ]
        	then
		        echo -n "Grupo: "
		        read grupo
			if grep -w ^$grupo /etc/group > /dev/null
			then
				echo "El grupo ya existe"
				echo "Añadiendo el usuario al grupo"
			else
				echo "El grupo no existe"
				echo "Creando $grupo"
		        	groupadd $grupo
			fi
		        useradd $usuario -G $grupo -s /bin/bash -m -N
			echo "La contraseña es $usuario se recomienda cambiarla lo antes posible"
		        echo "$usuario:$usuario" | chpasswd -c SHA512
		        echo "Usuario $usuario creado quieres que este usuario solo pueda sftp?"
		        echo "1 - Si"
		        echo "2 - No"
		        echo -n "Elige un numero: "
		        read sftp
		        case $sftp in
		            1)
		                usermod -aG users-sftp $usuario
		                mkdir /sftp/documentos/$usuario
		                chown $usuario:users-sftp /sftp/documentos/$usuario
			        ;;
		            *)
		            ;;
		        esac
		else
			echo "El usuario ya existe"
		fi
    ;;
    2)
        echo "Creando un usuario en LDAP"
        dn="dc=arquitectotec,dc=es"
        sino=2
        while (( $sino != 1 ))
        do
            listado=$(ldapsearch -xLLL -b "$dn" | grep "dn" | awk '{print $2}')
            numero=1
            echo "En que ruta quieres crear el usuario?"
            for i in $listado
            do
                echo -n "$numero - "
                echo $i
                ((numero++))
            done
            echo -n "Elige un numero: "
            read opcion
            numero=1
            for i in $listado
            do
                if [ $numero -eq $opcion ]
                then
                    dn=$i
                fi
                ((numero++))
            done
            echo "Quieres crear el usuario en $dn?"
            echo "1 - Si"
            echo "2 - No"
            echo -n "Elige un numero: "
            read sino
            ((veces++))
        done
        echo -n "Nombre de usuario:"
        read nombre
        echo -n "Numero de uid:"
        read uid
        echo -n "Numero de gid:"
        read gid
	echo -n "Nombre de la unidad organizativa:"
	read ou
        echo "dn: uid=$nombre,$dn" > usuario.ldif
        echo "objectClass: top" >> usuario.ldif
        echo "objectClass: posixAccount" >> usuario.ldif
        echo "objectClass: inetOrgPerson" >> usuario.ldif
        echo "objectClass: person" >> usuario.ldif
        echo "cn: $nombre" >> usuario.ldif
        echo "uid: $nombre" >> usuario.ldif
        echo "ou: $ou" >> usuario.ldif
        echo "uidNumber: $uid" >> usuario.ldif
        echo "gidNumber: $gid" >> usuario.ldif
        echo "homeDirectory: /home/$nombre" >> usuario.ldif
        echo "loginShell: /bin/bash" >> usuario.ldif
        echo -n "userPassword: " >> usuario.ldif
        slappasswd -h '{CRYPT}' -c '$6$' >> usuario.ldif
        echo "sn: $nombre" >> usuario.ldif
        echo "givenName: $nombre" >> usuario.ldif
	ldapadd -x -D cn=admin,dc=arquitectotec,dc=es -W -f usuario.ldif
    ;;
    3)
        echo "Borrando un usuario del sistema"
	echo -n "Que usario quieres borrar: "
	read usuario
	existe=$(getent passwd $usuario | wc -l)
	if [ $existe -gt 0 ]
	then
		echo "Este usuario existe"
		grupo=$(groups $usuario | grep -c "users-sftp")
		if [ $grupo -gt 0 ]
		then
			echo "Borrando directorio sftp"
			sftpdir="/sftp/documentos/$usuario/"
			contenido=$(ls $sftpdir | wc -l)
			if [ $contenido -gt 0 ]
			then
				echo "Este directorio tiene contenido dentro"
				echo "Estas seguro de que quires borrar el directorio"
				echo "1 - Si"
				echo "2 - No"
				echo -n "Elige un número: "
				read sino
				case $sino in
					1)
						rm -rf $sftpdir
					;;
					*)
					;;
				esac
			elif [ $contenido -eq 0 ]
			then
				echo "Este directorio no tiene contenido dentro"
                                echo "Estas seguro de que quires borrar el directorio"
                                echo "1 - Si"
                                echo "2 - No"
                                echo -n "Elige un número: "
                                read sino
                                case $sino in
                                        1)
                                                rmdir $sftpdir
                                        ;;
                                        *)
                                        ;;
				esac
			else
				echo "Este usuario no tiene una carpeta existente"
			fi
		else
			echo "Este usuario no pertenece al grupo sftp"
		fi
		userdel -r $usuario
	else
		echo "Este usuario no existe"
	fi
    ;;
    4)
        echo "Borrar un elemento del ldap"
	dn="dc=arquitectotec,dc=es"
        sino=2
        while (( $sino != 1 ))
        do
            listado=$(ldapsearch -xLLL -b "$dn" | grep "dn" | awk '{print $2}')
            numero=1
            echo "En que ruta quieres borrar el elemento?"
            for i in $listado
            do
                echo -n "$numero - "
                echo $i
                ((numero++))
            done
            echo -n "Elige un numero: "
            read opcion
            numero=1
            for i in $listado
            do
                if [ $numero -eq $opcion ]
                then
                    dn=$i
                fi
                ((numero++))
            done
            echo "Quieres borrar el elemento $dn?"
            echo "1 - Si"
            echo "2 - No"
            echo -n "Elige un numero: "
            read sino
            ((veces++))
        done
	ldapdelete -x -D cn=admin,dc=arquitectotec,dc=es -W $dn
    ;;
    *)
        echo "Opcion no valida"
    ;;
esac
