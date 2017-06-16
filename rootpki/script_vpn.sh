#! /bin/bash

#### Script permettant de générer, activer, désactiver ou supprimer la configuration du serveur vpn // générer les configurations clients et révoquer les clients // activation et désactivation de l'option client to client ####

cat <<- FIN
Choissisez une option :

1 - Configuration serveur
2 - Configuration client
3 - Option client-to-client
0 - Quitter

FIN
echo -n "Votre choix: "
read vpnun
case "$vpnun" in
	"1" ) cat <<- FIN
    	
Choissisez une option pour la configuration serveur :
1 - Générer
2 - Activer
3 - Désactiver
4 - Révoquer
0 - Quitter		

FIN
	;;
	"2" ) cat <<- FIN
    	
Choissisez une option pour la configuration client :
1 - Générer
2 - Révoquer
0 - Quitter

FIN
	;;
	"3" ) cat <<- FIN
    	
Choissisez une option pour l'option client-to-client:
1 - Activer
2 - Désactiver
0 - Quitter

FIN
	;;
	"0" ) echo "Au revoir"; exit 0 ;;
	* ) echo "Inconnu, je ne comprends pas.";;
esac
echo -n "Votre choix: "
read vpnde

# Déclaration des répertoires principaux
RSA_DIR=/usr/share/easy-rsa
KEYS_DIR=$RSA_DIR/keys
if [[ ( -n $vpnun ) && ( -n $vpnde ) ]]
then
	if [[ ( "$vpnun" -eq 1 ) && ( "$vpnde" -eq 1 ) ]]
	then
	# Générer la configuration OpenVPN serveur
		# Vérification que ce certificat n'existe pas déjà
		if [ -f $KEYS_DIR/Serveur.crt ]
		then
			echo "Ce projet existe déjà dans le système."
			exit
		else
			# Déplacement vers le répertoire /usr/share/easy-rsa/
			cd $RSA_DIR
			source ./vars > /dev/null
			export EASY_RSA="${EASY_RSA:-.}"
			"$EASY_RSA/pkitool" --server --batch Serveur
			cp /usr/share/easy-rsa/keys/{Serveur.crt,Serveur.key} /opt/vpn/x.509/server/ 
		fi	
	fi
	if [[ ( "$vpnun" -eq 1 ) && ( "$vpnde" -eq 2 ) ]]
	then
	# Activation de la configuration du serveur
		rsync /opt/vpn/x.509/server/server_x509.conf  /etc/openvpn/server_x509.conf
		systemctl start openvpn@server_x509.service
	fi
	if [[ ( "$vpnun" -eq 1 ) && ( "$vpnde" -eq 3 ) ]]
	then
	# Désactivation de la configuration du serveur
		rsync /opt/vpn/x.509/server/server_x509.conf  /etc/openvpn/server_x509.conf
		systemctl stop openvpn@server_x509.service
	fi
	if [[ ( "$vpnun" -eq 1 ) && ( "$vpnde" -eq 4 ) ]]
	then
	# Révoquer les certificats
		if [ -f $KEYS_DIR/Serveur.crt ]
        	then

			# On se place dans le répertoire easy-rsa pour lancer le script vars
			cd $RSA_DIR
			source ./vars > /dev/null

			# On lance le script revoke-full
			source ./revoke-full Serveur

			# On se place dans le répertoire keys pour upprimer tous les fichiers liés au projet
			cd $KEYS_DIR
			rm Serveur.*
		else
			echo "Ce certificat n'existe pas."
			exit
		fi
	fi
	if [[ ( "$vpnun" -eq 2 ) && ( "$vpnde" -eq 1 ) ]]
	then
	# Générer la configuration des clients
		echo "Nom du nouveau client : "
		read nom	
		if [ ! -z "$nom" ]
		then
			# Vérification que ce certificat n'existe pas déjà
			if [ -f $KEYS_DIR/$nom.crt ]
			then
				echo "Ce projet existe déjà dans le système."
				exit
			else
				# Déplacement vers le répertoire /usr/share/easy-rsa/
				cd $RSA_DIR
				source ./vars > /dev/null

				export EASY_RSA="${EASY_RSA:-.}"
				"$EASY_RSA/pkitool" --batch $nom
		
				# Création du fichier .ovpn
				touch $KEYS_DIR/$nom.ovpn
				echo -e "client\ndev tun1\nproto udp\nremote 10.10.10.195 1194\nresolv-retry infinite\nnobind\npersist-key\npersist-tun\nca ca.crt\ncert $nom.crt\nkey $nom.key\ncomp-lzo\nverb 1" > $KEYS_DIR/$nom.ovpn
				mkdir /opt/vpn/x.509/clients/$nom/
				cp /usr/share/easy-rsa/keys/{ca.crt,$nom.ovpn,$nom.crt,$nom.key} /opt/vpn/x.509/clients/$nom/ 
			fi
		fi
	fi
	if [[ ( "$vpnun" -eq 2 ) && ( "$vpnde" -eq 2 ) ]]
	then
	# Révoquer la configuration des clients
		echo "Nom du nouveau client : "
		read nom	
		if [ -f $KEYS_DIR/$nom.crt ]
                then

                        # On se place dans le répertoire easy-rsa pour lancer le script vars
                        cd $RSA_DIR
                        source ./vars > /dev/null

                        # On lance le script revoke-full
                        source ./revoke-full $nom

                        # On se place dans le répertoire keys pour upprimer tous les fichiers liés au projet
                        cd $KEYS_DIR
                        rm $nom.*
			rm -rf /opt/vpn/x.509/clients/$nom/
                else
                        echo "Ce certificat n'existe pas."
                        exit
                fi
	fi
	if [[ ( "$vpnun" -eq 3 ) && ( "$vpnde" -eq 1 ) ]]
	then
	# Activation de l'option client-to-client
		echo 'client-to-client' >> /opt/vpn/x.509/server/server_x509.conf
		rsync /opt/vpn/x.509/server/server_x509.conf  /etc/openvpn/server_x509.conf
	fi
	if [[ ( "$vpnun" -eq 3 ) && ( "$vpnde" -eq 2 ) ]]
	then
	# Désactivation de l'option client-to-client
		sed -i -e '/client-to-client/d' /opt/vpn/x.509/server/server_x509.conf
		rsync /opt/vpn/x.509/server/server_x509.conf  /etc/openvpn/server_x509.conf
	fi
	if [[ ( ( "$vpnun" -eq 1 ) || ( "$vpnun" -eq 2 ) || ( "$vpnun" -eq 3 ) ) && ( "$vpnde" -eq 0 ) ]]
	then
		echo "Au revoir"
		exit
	fi
	
else
	echo "Erreur :("
fi
