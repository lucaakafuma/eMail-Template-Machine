#!/bin/bash

# Cleaning the workspace up
clear

# Set some working variables up
# [TODO] to put them in a separate file
. $(dirname "$0")/functions.sh

workingPath=$(dirname "$(readlink -f "$0")")

ourEmailServer=(
	'82.193.37.20'
	'82.193.37.21'
	'82.193.37.22'
	'82.193.33.204'
	'82.193.33.205'	
)
declare -A cPanelServers=( 
	['82.193.33.204']='cpanel02.inasset.net'
	['82.193.33.205']='cpanel03.inasset.net'
)

# puts the choice into $answer variable 
getRequests choice

#[TODO] transform it into case sintax
case $choice in 
	1)
		clear
		
		echo "Inserisci email:"
		read email;
		
		getDomain $email
		
		mailSrvIPAddr=$(dig mx $domain +short | awk {'print $2'} | xargs dig +short)
		getMailSrvIPAddresses $domain

		for mailSrvIp in $mailSrvIPAddresses; do			

			if [[ ! " ${ourEmailServer[@]} " =~ " $mailSrvIp " ]]; then
				echo "The mail server '$mailSrvIp' of the domain $domain is not managed by us."
			
			elif [[ $mailSrvIp == "82.193.33.20"* ]]; then		
				if [[ $mailSrvIp = "82.193.33.204" ]]; then
					cpName="cp02.inasset.net"

				elif [[ $mailSrvIp = "82.193.33.205" ]]; then				
					cpName="cp03.inasset.net"

				else
					echo "Not a cPanel Server"

				fi
				
				user="$(ssh -t root@$mailSrvIp "/scripts/whoowns $domain" | tail -n -1)"
				cpUser=$(echo $user | tr -d '\x{d}')
				#echo " CPUSER: $cpUser"; exit 0
				contactEmails=$(ssh -tT root@$mailSrvIp "uapi --user=$cpUser Variables get_user_information | grep contact_email | awk '{print $3}' | cut -d ':' -f 2")
				echo "1 error"
				contactEmail1=${contactEmails[0]}
				contactEmail2=${contactEmails[1]}
				
				#echo "EMAIL1: $contactEmails[0] - $contactEmail1"
				sed "s/{{utente}}/$user/g;s/{{email}}/$contactEmail1/g;s/{{domain}}/$domain/g;s/{{cpName}}/$cpName/g" $workingPath/assets/emailTemplates/spam.txt
				
			elif [[ $mailSrvIp == "82.193.37.2"* ]]; then
				mailSrvHostName=$(dig -x $mailSrvIp +short)
				echo "The mail server $mailSrvHostName with ip $mailSrvIp of the domain $domain is hosted by Zimbra"
				
			else
				echo "Boh??? $mailSrvIp"
			fi

		done

		echo "Bye..."
		exit 0
	;;
2)
	###
	# 2) Invio AUTH/CODE
	###

	clear
	echo "Inserisci dominio:"

	read domain;
	echo "Inserisci authcode:"

	read authcode;

	clear
	#authCodeExcaped=${printf '%q' $authcode}

	sed "s/{{dominio}}/$domain/g;s/{{authcode}}/${authcode}/g" $workingPath/assets/richiestaAuthcode/authcode.txt

	echo ""
;;
3)
	###
	# 3) Avviso di chiusura ticket
	###

	clear

	cat $workingPath/assets/emailTemplates/chiusura.txt

	echo ""
;;
4)
	###
	# 4) Attivazione account cPanel
	###

	clear

	echo "Inserisci dominio:"
	read domain

	echo "Inserisci cPanel:"
	read cPanel

	echo "Inserisci il nome utente:"
	read user

	echo "Inserisci la password:"
	read password


	sed "s/{{dominio}}/$domain/g;s/{{user}}/$user/g;s/{{password}}/$password/g;s/{{cPanel}}/$cPanel/g" $workingPath/assets/emailTemplates/attivazioneCpanel.txt
;;
5)
	###
	# 5) Configurazione caselle email cPanel
	###

	clear

	echo "Inserisci email:"
	read email;

	domain=$(echo "$email" | awk -F'[@]' '{print $2}')
	mxSrvAddress=$(dig mx $domain +short | awk {'print $2'} | xargs dig +short)

	if [ $mxSrvAddress == 'zmw.inasset.net.' ] ; then #[TODO] da sistemare il ciclo in array
		sed "s/{{dominio}}/$domain/g;s/{{mxSrvAddress}}/$mxSrvAddress/g" $workingPath/assets/emailTemplates/configurazioneEmail.txt
	fi

	if [ $mxSrvAddress == "82.193.33.203" ] ; then
		cpName="cp01.inasset.net"
	
	elif [ "$mxSrvAddress" == "82.193.33.204" ] ; then
		cpName="cp02.inasset.net"
	
	elif [ "$mxSrvAddress" == "82.193.33.205" ] ; then
		cpName="cp03.inasset.net"
		
	else  echo "$domain - $mxSrvAddress - Non in cPanel" ; exit 0 ;

	fi
	user=$(ssh -t root@$mxSrvAddress "/scripts/whoowns gate133.com" | tail -n -1)
	sed "s/{{utente}}/$user/g;s/{{dominio}}/$domain/g;s/{{cPanel}}/$cpName/g" $workingPath/assets/emailTemplates/configurazioneEmail.txt
;;
6)
	###
	# 6) Creazione account email cPanel
	###

	clear

	echo "Inserisci email:"
	read email;

	domain=$(echo "$email" | awk -F'[@]' '{print $2}') # OK
	cpIpAddress=$(dig mx $domain +short | awk {'print $2'} | xargs dig +short) # OK

	if [ $cpIpAddress == "82.193.33.203" ] ; then
		cpName="cp01.inasset.net"
	
		elif [ "$cpIpAddress" == "82.193.33.204" ] ; then
			cpName="cp02.inasset.net"
	
		elif [ "$cpIpAddress" == "82.193.33.205" ] ; then
			cpName="cp03.inasset.net"
		
		else  echo "$domain - $cpIpAddress - Non in cPanel" ; exit 0;
	fi
	user=$(ssh -t root@$cpIpAddress "/scripts/whoowns $domain" | tail -n -1)
	sed "s/{{utente}}/$user/g;s/{{dominio}}/$domain/g;s/{{cPanel}}/$cpName/g" $workingPath/assets/emailTemplates/creaMail.txt
;;
7)
	###
	# 7) Reinvio credenziali account cPanel [TODO]
	###

	clear

	echo "Inserisci dominio:"
	read domain;
	
	cpIpAddress=$(dig cpanel.$domain +short)

	if [ $cpIpAddress == "82.193.33.203" ] ; then
		cpName="cp01.inasset.net"
	
		elif [ "$cpIpAddress" == "82.193.33.204" ] ; then
			cpName="cp02.inasset.net"
	
		elif [ "$cpIpAddress" == "82.193.33.205" ] ; then
			cpName="cp03.inasset.net"
		
		else  echo "$domain - $cpIpAddress - Non in cPanel" ; exit 0;
	fi

	user="$(ssh -t root@$cpName '/scripts/whoowns '$domain | tail -n -1)"
	echo "Nome Utente: $user";
	echo "cPanel: $cpName";
	echo "Start";
	command="cpapi2 --user=$user CustInfo displaycontactinfo | grep value | head -1 | tr -d '\x{d}'";
	eMail=$(ssh -t root@$cpName "$command");
	echo "***Contact email:*** $eMail ";
	

	#sed "s/{{user}}/$user/g;s/{{dominio}}/$domain/g;s/{{cPanel}}/$cpName/g" $workingPath/assets/emailTemplates/recuperoPasswordcPanel.txt
	#sed "s/{{user}}/$user/g;s/{{eMail}}/$eMail/g;s/{{dominio}}/$domain/g;s/{{cPanel}}/$cpName/g" $workingPath/assets/emailTemplates/recuperoPasswordcPanel.txt
;;
8)
	###
	# 8) Rilascio servizio cloud
	###

	clear
	echo "Inserisci cliente:"
	read cliente;

	echo "Inserisci vCPU:"
	read vCPU;
	
	echo "Inserisci ram:"
	read ram;

	echo "Inserisci Storage Tier 0 in GB:"
	read stor0_gb;

	echo "Inserisci Storage Tier 1 in GB:"
	read stor0_gb;

	echo "Inserisci Storage Tier 0 in GB:"
	read stor0_gb;

	echo "Inserisci Storage Tier 0 in GB:"
	read stor0_gb;

	clear

	sed "s/{{dominio}}/'$domain'/g;s/{{authcode}}/'$authcode'/g" $workingPath/assets/richiestaAuthcode/authcode.txt

	echo ""
;;
	*) echo "errore"
esac
