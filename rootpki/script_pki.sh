#! /bin/bash

#### Script permettant de créer ou supprimer de nouvelles autorités filles et de créer ou supprimer de nouveaux certificats pour serveurs ou clients ####

while true
do
	cat <<- FIN
	Choissisez une option :

	1 - Créer une nouvelle autorité fille
	2 - Supprimer une autorité fille
	3 - Créer un certificat serveur
	4 - Créer un certificat client
	5 - Supprimer un certificat serveur ou client
	0 - Quitter

	FIN

	echo -n "Votre choix: "
	read reponse
	case "$reponse" in
		"1" )	echo -n "Nom de la nouvelle autorité fille [espace] Mot de passe de la clé [espace] Common name du cerificat: "
			read nom mdp cn
			# Création des répertoires et fichiers nécessaires à la nouvelle autorité fille
			mkdir -p $nom/newcerts
			touch $nom/index.txt
			echo '01' > $nom/serial
			# Création d'un couple de clés
			openssl genrsa -passout pass:"$mdp" -out $nom/$nom.key -des3 2048
			# Création d'un certificat non-signé
			openssl req -new -key $nom/$nom.key -passin pass:"$mdp" -subj "/C=FR/ST=Ile-de-France/L=Paris/O=INTECH/CN=$cn" -out $nom/$nom.crs -config ./openssl.cnf
			# Signature du certificat avec la clé privée de l'autorité
			openssl ca -batch -out $nom/$nom.pem -passin pass:"azerty" -config ./openssl.cnf -extensions ROOT_CBI -infiles $nom/$nom.crs
			# Insertion de la nouvelle configuration dans openssl.cnf
			echo -e "\n[ CA_$nom ]\ndir             = .\ncerts           = \$dir/$nom/certs\nnew_certs_dir   = \$dir/$nom/newcerts\ndatabase        = \$dir/$nom/index.txt\ncertificate     = \$dir/$nom/$nom.pem\nserial          = \$dir/$nom/serial\nprivate_key     = \$dir/$nom/$nom.key\ndefault_days    = 365\ndefault_md      = sha1\npreserve        = no\npolicy          = policy_match" >> openssl.cnf
			;;
		"2" )	echo -n "Nom de l'autorité fille : "
			read nom
			# Révoquer le certificat
			openssl ca -revoke $nom/$nom.pem -passin pass:"azerty" -config ./openssl.cnf
			# Supprimer tous les fichiers associés
			rm -rf $nom/
			# Trouver cette autorité fille dans le fichier de configuration et la retirer
			sed "/CA_$nom/,/policy_match/d" openssl.cnf > tmp
			mv tmp openssl.cnf
			;; 
		"3" )	echo -n "Nom du certificat pour le serveur [espace] Mot de passe [espace] Common name [espace] Nom de l'autorité fille à utiliser pour signer [espace] Mdp de le clé de cette autorité : "
			read nom mdp cn fille mdp_fille
			# Création du couple de clés
			openssl genrsa -passout pass:"$mdp" -out $fille/$nom.key -des3 1024
			# Création du certificat
			openssl req -new -key $fille/$nom.key -passin pass:"$mdp" -subj "/C=FR/ST=Ile-de-France/L=Paris/O=INTECH/CN=$cn" -out $fille/$nom.crs -config ./openssl.cnf
			# Signature du certificat
			openssl ca -batch -out $fille/$nom.pem -passin pass:"$mdp_fille" -name CA_$fille -config ./openssl.cnf -extensions SERVER_RSA_SSL -infiles $fille/$nom.crs
			;; 
		"4" )	echo -n "Nom du certificat pour le serveur [espace] Mot de passe [espace] Common name [espace] Nom de l'autorité fille à utiliser pour signer [espace] Mdp de le clé de cette autorité : "
			read nom mdp cn fille mdp_fille
			# Création du couple de clés
			openssl genrsa -passout pass:"$mdp" -out $fille/$nom.key -des3 1024
			# Création du certificat
			openssl req -new -key $fille/$nom.key -passin pass:"$mdp" -subj "/C=FR/ST=Ile-de-France/L=Paris/O=INTECH/CN=$cn" -out $fille/$nom.crs -config ./openssl.cnf
			# Signature du certificat
			openssl ca -batch -out $fille/$nom.pem -passin pass:"$mdp_fille" -name CA_$fille -config ./openssl.cnf -extensions CLIENT_RSA_SSL -infiles $fille/$nom.crs
			;;
		"5" )	echo -n "Nom du certificat serveur à supprimer [espace] Nom autorité de certification [espace] mdp de la clé de l'autorité : "
			read nom fille mdp_fille
			# Révocation du certificat
			openssl ca -revoke $fille/$nom.pem -config ./openssl.cnf -name CA_$fille -passin pass:"$mdp_fille"	
			# Supprimer tous les fichiers associés
			rm $fille/$nom.*
			;;
		"0" ) echo "Au revoir"; exit 0;;
		* ) echo "Inconnu, je ne comprends pas.";;
	esac
done
