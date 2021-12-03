#!/bin/bash

# Author Frank Montalvo (fmontalvoo)

#Colors
greenColor="\e[0;32m\033[1m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"
endColor="\033[0m\e[0m"

trap ctrl_c INT # Activa una funcion cuando se presiona ctrl + c

function ctrl_c(){
	echo -e "\n${redColor}[!] Exit... \n${endColor}"

	tput cnorm; exit 1
}

function helpPanel(){
	echo -e "\n${yellowColo}[i] Uso: ./btcAnalyzer${endColor}"
	for i in $(seq 1 100); do echo -ne "${blueColor}="; done; echo -ne "${endColor}"
	echo -e "\n\n\t${grayColor}[-e]${endColor}${yellowColor} Modo exploración${endColor}"
	echo -e "\t\t${purpleColor}unconfirmed_transactions${endColor}${yellowColor}:\t Listar transacciones no confirmadas${endColor}"
	echo -e "\t\t${purpleColor}inspect${endColor}${yellowColor}:\t\t\t Inspeccionar hash de transacción${endColor}"
	echo -e "\t\t${purpleColor}address${endColor}${yellowColor}:\t\t\t Inspeccionar dirección de transacción${endColor}"
	echo -e "\n\t${grayColor}[-h]${endColor}${yellowColor} Mostrar ayuda${endColor}\n"

	tput cnorm; exit 1
}

# Variables globales
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_tracsaction_url="https://www.blockchain.com/es/btc/tx/"
inspect_address_url="https://www.blockchain.com/es/btc/address/"

function unconfirmedTransactions(){
	echo "Transacciones no confirmadas."
	tput cnorm
}

args_counter=0
while getopts "e:h:" arg; do

	case $arg in
		e) exploration_mode=$OPTARG; let args_counter+=1;;
		h) helpPanel;;
	esac

done

if [ $args_counter -eq 0 ]; then
	helpPanel
else
	if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
		unconfirmedTransactions
	fi
fi
