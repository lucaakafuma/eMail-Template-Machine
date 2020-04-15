#!/bin/bash

function getRequests (){
    ###Printing out the choices menu
    echo "Scegli il template:
    1) Avviso di SPAM
    2) Invio AUTH/CODE
    3) Avviso di chiusura ticket
    4) Attivazione account cPanel
    5) Configurazione caselle email (cPanel o Zimbra)
    6) Creazione account email cPanel
    7) Recupero credenziali account cPanel
    8) Rilascio servizio cloud" > /dev/tty

    read choice
}

function getDomain (){
    # Returns the domain stripped out from the email address
    # Param $1: email address
    # Output: a domain name
    domain=$(echo "$1" | awk -F'[@]' '{print $2}')

}

function getMailSrvIPAddresses (){
    # Returns the mail servers ip addresses (MX records)
    # Param $1: domain
    # Output: all MX records dsds
    mailSrvIPAddresses=$(dig mx $1 +short | awk {'print $2'} | xargs dig +short)
}