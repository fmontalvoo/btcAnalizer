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

	rm ut.* 2>/dev/null
    rm it.* 2>/dev/null
    rm ia.* 2>/dev/null
	tput cnorm; exit 1
}

# Variables globales
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_tracsaction_url="https://www.blockchain.com/es/btc/tx"
inspect_address_url="https://www.blockchain.com/es/btc/address"

function printTable(){
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){
    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){
    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function helpPanel(){
	echo -e "\n${yellowColo}[i] Uso: ./btcAnalyzer${endColor}"
	for i in $(seq 1 100); do echo -ne "${blueColor}="; done; echo -ne "${endColor}"
	echo -e "\n\n\t${grayColor}[-e]${endColor}${yellowColor} Modo exploración${endColor}"
	echo -e "\t\t${purpleColor}unconfirmed_transactions${endColor}${yellowColor}:\t Listar transacciones no confirmadas${endColor}"
	echo -e "\t\t${purpleColor}inspect${endColor}${yellowColor}:\t\t\t Inspeccionar hash de transacción${endColor}"
	echo -e "\t\t${purpleColor}address${endColor}${yellowColor}:\t\t\t Inspeccionar dirección de transacción${endColor}"
	echo -e "\n\t${grayColor}[-a]${endColor}${yellowColor} Requiere hash de dirección de transacción${endColor}\n"
	echo -e "\n\t${grayColor}[-i]${endColor}${yellowColor} Requiere hash de transacción${endColor}\n"
	echo -e "\n\t${grayColor}[-n]${endColor}${yellowColor} Limita el número de resultados${endColor}\n"
	echo -e "\n\t${grayColor}[-h]${endColor}${yellowColor} Mostrar ayuda${endColor}\n"

	tput cnorm; exit 1
}


function unconfirmedTransactions(){
    number_output=$1
	echo '' > ut.tmp
	while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
		curl -s "$unconfirmed_transactions" | html2text > ut.tmp
	done

	hashes=$(cat ut.tmp | grep 'Hash' -A 1 | grep -v -E "Hash|\--|Tiempo" | head -n $number_output)

	echo 'Hash_Cantidad_Bitcoin_Tiempo' > ut.table.tmp

	for hash in $hashes; do
		cantidad=$(cat ut.tmp | grep "$hash" -A 6 | tail -1)
		bitcoin=$(cat ut.tmp | grep "$hash" -A 4 | tail -1)
		tiempo=$(cat ut.tmp | grep "$hash" -A 2 | tail -1)
		echo "${hash}_\$${cantidad::-5}_${bitcoin}_${tiempo}" >> ut.table.tmp
	done

    cat ut.table.tmp | tr '_' ' ' | awk '{print $2}' | grep -v 'Cantidad' | tr -d '$' | sed 's/\,.*//g' | tr -d '.' > ut.total.tmp
    total=0; cat ut.total.tmp | while read total_in_line; do
        let total+=$total_in_line
        echo $total > ut.total.sum.tmp
    done

    echo "Catidad total_\$$(printf "%'.d\n" $(cat ut.total.sum.tmp))" > ut.total.table.tmp

    if [ "$(cat ut.table.tmp | wc -l)" != "1" ]; then
        echo -ne "${blueColor}"
        printTable '_' "$(cat ut.table.tmp)"
        echo -ne "${endColor}"
        echo -ne "${redColor}"
        printTable '_' "$(cat ut.total.table.tmp)"
        echo -ne "${endColor}"
        rm ut.* 2>/dev/null
        tput cnorm; exit 0
    fi
    
    rm ut.* 2>/dev/null
	tput cnorm; exit 1
}

function inspectTransaction(){
    transaction_hash=$1

    echo "Entradas totales_Gastos totales" > it.total_in_out.tmp

    while [ "$(cat it.total_in_out.tmp | wc -l)" == "1" ]; do
        curl -s "${inspect_tracsaction_url}/${transaction_hash}" | html2text | grep -E 'Entradas totales|Gastos totales' -A 1 \
         | grep -v -E 'Entradas totales|Gastos totales' | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> it.total_in_out.tmp
    done
    
    echo -ne "${greenColor}"
    printTable '_' "$(cat it.total_in_out.tmp)"
    echo -ne "${endColor}"

    echo "Dirección (Entradas)_Valor" > it.inputs.tmp
    while [ "$(cat it.inputs.tmp | wc -l)" == "1" ]; do
        curl -s "${inspect_tracsaction_url}/${transaction_hash}" | html2text | grep 'Entradas' -A 50 \
         | grep 'Gastos' -B 50 | grep 'Direcci' -A 3 | grep -v -E 'Direcci|Valor|\--' | awk 'NR%2{printf "%s ",$0;next;}1' \
         | awk '{print $1 "_" $2 " " $3}' >> it.inputs.tmp
    done

    echo -ne "${blueColor}"
    printTable '_' "$(cat it.inputs.tmp)"
    echo -ne "${endColor}"

     echo "Dirección (Gastos)_Valor" > it.outputs.tmp
    while [ "$(cat it.outputs.tmp | wc -l)" == "1" ]; do
        curl -s "${inspect_tracsaction_url}/${transaction_hash}" | html2text | grep 'Gastos' -A 50 \
         | grep 'Ya lo has pensado' -B 50 | grep 'Direcci' -A 3 | grep -v -E 'Direcci|Valor|\--' | awk 'NR%2{printf "%s ",$0;next;}1' \
         | awk '{print $1 "_" $2 " " $3}' >> it.outputs.tmp
    done

    echo -ne "${redColor}"
    printTable '_' "$(cat it.outputs.tmp)"
    echo -ne "${endColor}"

    rm it.* 2>/dev/null
	tput cnorm; exit 0
}

function inspectAddress(){
    address_hash=$1
    bitcoin_value=$(curl -s "https://cointelegraph.com/bitcoin-price" | html2text | grep "BTC_" \
     | head -1 | tr '$' ' ' | awk '{print $3}' | sed 's/\,//')

    echo "Transacciones realizadas_Cantidad total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total en la cuenta (BTC)" \
     > ia.information.tmp

    while [ "$(cat ia.information.tmp | wc -l)" == "1" ]; do
        curl -s "${inspect_address_url}/${address_hash}" | html2text \
         | grep -E 'Transacciones|Total recibido|Total enviado|Saldo final' -A 1 | head -n -2 \
         | grep -v -E 'Transacciones|Total recibido|Total enviado|Saldo final' | xargs | tr ' ' '_' \
         | sed 's/_BTC/ BTC/g' >> ia.information.tmp
    done

    echo -ne "${yellowColor}"
    printTable '_' "$(cat ia.information.tmp)"
    echo -ne "${endColor}"

    echo '' > ia.information.tmp

    curl -s "${inspect_address_url}/${address_hash}" | html2text | grep 'Transacciones' -A 1 | head -n -2 \
     | grep -v -E 'Transacciones|\--' > ia.information.tmp

    curl -s "${inspect_address_url}/${address_hash}" | html2text | grep -E 'Total recibido|Total enviado|Saldo final' -A 1 \
     | grep -v -E 'Total recibido|Total enviado|Saldo final|\--' > ia.btc_to_usd.tmp

    cat ia.btc_to_usd.tmp | while read value; do
        btc=$(echo $value | awk '{print $1}' | sed 's/\./\,/') 
        echo "\$$(printf "%'.d\n" $(echo $(($btc*$bitcoin_value)) | bc) 2>/dev/null)" >> ia.information.tmp
    done

    line_none=$(cat ia.information.tmp | grep -n "^\$$" | awk '{print $1}' FS=":")

    if [ $line_none ]; then
        sed "${line_none}s/\$/0/" -i ia.information.tmp
    fi

    cat ia.information.tmp | xargs | tr ' ' '_' > ia.inf.tmp
    rm ia.information.tmp 2>/dev/null && mv ia.inf.tmp ia.information.tmp
    sed '1iTransacciones realizadas_Cantidad total recibida (USD)_Cantidad total enviada (USD)_Saldo total en la cuenta (USD)' -i ia.information.tmp

    echo -ne "${turquoiseColor}"
    printTable '_' "$(cat ia.information.tmp)"
    echo -ne "${endColor}"

    rm ia.* 2>/dev/null
    tput cnorm; exit 0
}

args_counter=0
while getopts "a:e:n:i:h" arg; do

	case $arg in
		a) inspect_address=$OPTARG; let args_counter+=1;;
		e) exploration_mode=$OPTARG; let args_counter+=1;;
		h) helpPanel;;
		i) inspect_tracsaction=$OPTARG; let args_counter+=1;;
		n) number_output=$OPTARG; let args_counter+=1;;
	esac

done

if [ $args_counter -eq 0 ]; then
	helpPanel
else
	if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
		if [ ! "$number_output" ]; then
            number_output=100
            unconfirmedTransactions $number_output
        else
            unconfirmedTransactions $number_output
        fi
	elif [ "$(echo $exploration_mode)" == "inspect" ]; then
        inspectTransaction $inspect_tracsaction
	elif [ "$(echo $exploration_mode)" == "address" ]; then
        inspectAddress $inspect_address
    fi
fi
