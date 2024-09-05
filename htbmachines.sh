#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Ctrl + C
function ctrl_c(){
  echo -e "\n${redColour}[!]Saliendo...${endColour}"
  tput cnorm && exit 1
}
trap ctrl_c INT

function helpPanel() {
  echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Panel de ayuda: ${endColour}"
  echo -e "\t${purpleColour}-u)${endColour} ${greenColour}Descargar o actualizar archivos necesarios${endColour}"
  echo -e "\t${purpleColour}-m)${endColour} ${greenColour}Buscar por un nombre de máquina${endColour}"
  echo -e "\t${purpleColour}-i)${endColour} ${greenColour}Buscar por número IP de máquina${endColour}"
  echo -e "\t${purpleColour}-d)${endColour} ${greenColour}Buscar máquina filtrando por dificultad: f m d i"
  echo -e "\t${purpleColour}-s)${endColour} ${greenColour}Buscar máquina filtrando por skill${endColour}"
  echo -e "\t${purpleColour}-y)${endColour} ${greenColour}Buscar link del video de Youtube de la máquina${endColour}"
  echo -e "\t${purpleColour}-h)${endColour} ${greenColour}Mostrar el panel de ayuda${endColour}"
}

function searchMachine() {
  machineName="$1"
  if [ -n "$(cat bundle.js | awk "/name: \"$machineName\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta:" | tr -d '"' | tr -d "," | sed 's/^ *//')" ] ; then
    echo -e "\n${yellowColour}[+]${endColour} Datos de la máquina${yellowColour} $machineName${endColour}:\n"
    cat bundle.js | awk "/name: \"$machineName\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta:" | tr -d '"' | tr -d "," | sed 's/^ *//'
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado la máquina: ${yellowColour}$machineName${endColour}\n"
    exit 1
  fi
}

function updateFiles(){
  tput civis
  if [ ! -f bundle.js ]; then  
  echo -e "\n${yellowColour}[+]${endColour} Comenzando la descarga de '${yellowColour}bundle.js${endColour}'...\n"
  curl "https://htbmachines.github.io/bundle.js" > bundle.js
  js-beautify bundle.js | sponge bundle.js
  echo -e "\n${yellowColour}[+]${endColour} Todos los archivos han sido descargados [1/1]"
  else
    echo -e "\n${yellowColour}[!]${endColour} Comprobando si hay actualizaciones pendientes..."
    curl -s "https://htbmachines.github.io/bundle.js" > bundle_temp.js
    js-beautify bundle_temp.js | sponge bundle_temp.js
    if [ $(md5sum bundle_temp.js | awk '{ print $1 }') == $(md5sum bundle.js | awk '{ print $1 }') ]; then
      echo -e "\n${yellowColour}[+]${endColour} El archivo ya está actualizado, no se han realizado cambios."
      rm bundle_temp.js
    else
      rm bundle.js
      mv bundle_temp.js ./bundle.js
      echo -e "\n${yellowColour}[+]${endColour} Se ha actualizado el archivo '${yellowColour}bundle.js${endColour}' [1/1]" 
    fi
  fi
  tput cnorm
}

function searchMachineByIP () {
  machineIPNumber=$1
  machineName=$(cat bundle.js | grep "ip: \"$machineIPNumber\"" -B 3 | grep "name:" | tr -d "," | tr -d '"' | sed 's/^ *//' | awk '{print $2}')
  if [ -n "$(cat bundle.js | grep "ip: \"$machineIPNumber\"" -B 3 | grep "name:" | tr -d "," | tr -d '"' | sed 's/^ *//' | awk '{print $2}')" ]; then 
    echo -e "\n${yellowColour}[+]${endColour} El número IP: ${purpleColour}$machineIPNumber${endColour} corresponde a la máquina: ${yellowColour}$machineName${endColour}\n"
   
    read -p "¿Quieres listar los datos de la máquina $machineName? (s/n): " respuesta
    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
      searchMachine $machineName
    else
      : # No hace nada si pones 2 puntos
    fi

    else
      echo -e "\n${redColour}[!]${endColour} No se ha encontrado la máquina con número de IP: ${purpleColour}$machineIPNumber${endColour}\n"
      exit 1
  fi
}

function searchYTLink () {
  machineName=$1
  ytLink="$(cat bundle.js | awk "/name: \"$machineName\"/,/youtube/" | grep "youtube" | awk '{print $2}' | tr -d '"' | tr -d ",")"

  if [ -n "$ytLink" ]; then
  echo -e "\n${yellowColour}[+]${endColour} El link al video de ${redColour}Youtube${endColour} de la máquina ${yellowColour}$machineName${endColour} es:\n"
  echo -e "${purpleColour}$ytLink${endColour}\n"
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado la máquina: ${yellowColour}$machineName${endColour}\n"
    exit 1
  fi
}

function searchDifficulty () {
  difficulty=$1
  if [[ "$difficulty" == f || "$difficulty" == F ]]; then
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas de dificultad ${greenColour}Fácil${endColour}:\n"
    echo -e "$(cat bundle.js | grep "dificultad: \"Fácil\"" -B 6 | grep "name:" | sed 's/^ *//' | awk '{print $2}' | tr -d '"' | tr -d "," | column)"
  elif [[ "$difficulty" == m || "$difficulty" == M ]]; then
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas de dificultad ${yellowColour}Media${endColour}:\n"
    echo -e "$(cat bundle.js | grep "dificultad: \"Media\"" -B 6 | grep "name:" | sed 's/^ *//' | awk '{print $2}' | tr -d '"' | tr -d "," | column)"
  elif [[ "$difficulty" == d || "$difficulty" == D ]]; then
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas de dificultad ${redColour}Difícil${endColour}:\n"
    echo -e "$(cat bundle.js | grep "dificultad: \"Difícil\"" -B 6 | grep "name:" | sed 's/^ *//' | awk '{print $2}' | tr -d '"' | tr -d "," | column)"
  elif [[ "$difficulty" == i || "$difficulty" == I ]]; then
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas de dificultad ${purpleColour}Insane${endColour}:\n"
    echo -e "$(cat bundle.js | grep "dificultad: \"Insane\"" -B 6 | grep "name:" | sed 's/^ *//' | awk '{print $2}' | tr -d '"' | tr -d "," | column)"
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado la dificultad: ${yellowColour}$difficulty${endColour}\n"
    exit 1 
  fi
}

function searchMachineByOS () {
  os=$1
  if [[ "$os" == l || "$os" == L ]]; then 
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas con sistema operativo ${turquoiseColour}Linux${endColour}:\n"
    cat bundle.js | grep "so: \"Linux\"" -B 5 | grep "name: " | awk '{print $2}' | tr -d "," | tr -d '"' | column
  elif [[ "$os" == w || "$os" == W ]]; then 
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas con sistema operativo ${blueColour}Windows${endColour}:\n"
    cat bundle.js | grep "so: \"Windows\"" -B 5 | grep "name: " | awk '{print $2}' | tr -d "," | tr -d '"' | column
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado el sistema operativo: ${yellowColour}$os${endColour}\n"
    exit 1 
  fi
}

function searchMachineByOSDifficulty () {  
  os=$1
  difficulty=$2

  if [[ "$os" == l || "$os" == L ]]; then
    os="Linux"
  elif [[ "$os" == w || "$os" == W ]]; then
    os="Windows"
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado el sistema operativo: ${yellowColour}$os${endColour}\n"
    exit 1
  fi 

  if [[ "$difficulty" == f || "$difficulty" == F ]]; then
    difficulty="Fácil"
  elif [[ "$difficulty" == m || "$difficulty" == M ]]; then
    difficulty="Media"
  elif [[ "$difficulty" == d || "$difficulty" == D ]]; then
    difficulty="Difícil"
  elif [[ "$difficulty" == i || "$difficulty" == I ]]; then
    difficulty="Insane"
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado la dificultad: ${yellowColour}$difficulty${endColour}\n"
    exit 1
  fi
  echo -e "\n${yellowColour}[+]${endColour} Se está realizando una petición de sistema operativo ${turquoiseColour}$os${endColour} y de dificultad ${blueColour}$difficulty${endColour}\n"
  echo -e "$(cat bundle.js | grep "so: \"$os\"" -C 4 | grep "dificultad: \"$difficulty\"" -B 5 | grep "name: " | tr -d "," | tr -d '"' | sed 's/^ *//' | awk '{print $2}' | column)\n"
} 

function searchMachineBySkill () {
  skill=$1

  if [ -n "$(cat bundle.js | grep "skills: " -C 5 | grep "$skill" -i -B 6 | grep "name: ")" ]; then
    echo -e "\n${yellowColour}[+]${endColour} Filtrando por la skill: ${yellowColour}$skill${endColour}\n"
    echo -e "$(cat bundle.js | grep "skills: " -C 5 | grep "$skill" -i -B 6 | grep "name: " | awk '{print $2}' | tr -d "," | tr -d '"' | sed 's/^ *//' | column)\n"
  else
    echo -e "\n${redColour}[!]${endColour} No se ha encontrado la skill: ${yellowColour}$skill${endColour}\n"
  fi
}

# Indicadores
declare -i parameter_counter=0

#Chivatos
declare -i chivato_os=0
declare -i chivato_difficulty=0

while getopts "m:i:y:d:o:s:uh" arg 2>/dev/null; do
  case $arg in
    m) machineName=$OPTARG; let parameter_counter+=1;;
    u) let parameter_counter+=2;;
    i) machineIPNumber=$OPTARG; let parameter_counter+=3;;
    y) machineName=$OPTARG; let parameter_counter+=4;;
    d) difficulty=$OPTARG; chivato_difficulty=1; let parameter_counter+=5;;
    o) os=$OPTARG; chivato_os=1 ;let parameter_counter+=6;;
    s) skill=$OPTARG ; let parameter_counter+=7;; 
    h) ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then
  searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
  updateFiles
elif [ $parameter_counter -eq 3 ]; then
  searchMachineByIP $machineIPNumber
elif [ $parameter_counter -eq 4 ]; then
  searchYTLink $machineName
elif [ $parameter_counter -eq 5 ]; then
  searchDifficulty $difficulty
elif [ $parameter_counter -eq 6 ]; then
  searchMachineByOS $os
elif [[ chivato_os -eq 1 || chivato_difficulty -eq 1 ]]; then
  searchMachineByOSDifficulty $os $difficulty
elif [ $parameter_counter -eq 7 ]; then
  searchMachineBySkill "$skill"
else
  helpPanel
fi
