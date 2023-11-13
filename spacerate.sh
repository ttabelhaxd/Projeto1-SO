#!/bin/bash

function usage() {
    echo "Usage: $0 [-r] [-a] <spacecheck_file1> <spacecheck_file2>
          -r Sort by size, smallest to largest
          -a Sort by name, alphabetically"
    exit 1  
}

sort="-k1,1nr"

while getopts "ra" opt; do
    case $opt in
        r) 
            sort="-k1,1n" ;; #sort pelo tamanho
        a) 
            sort="-k2,2" ;; #sort alfabeticamente
        *) 
            usage ;;
    esac
done

shift $((OPTIND - 1))

file1="$1"
file2="$2"

if [ -z "$file1" ] || [ -z "$file2" ]; then #se um dos ficheiros não for especificado
    usage
fi

if [ ! -e "$file1" ] || [ ! -e "$file2" ]; then #se um dos ficheiros não existir
    echo "One or both of the files do not exist."
    exit 1
fi

echo -e "SIZE\tNAME"

compare(){
    declare -A file1_lines
    declare -A file2_lines

    while IFS=$'\t' read -r size path; do
        file1_lines["$path"]=$size #guarda o tamanho do diretorio no dicionario
    done < <(tail -n +2 "$file1") #ignora a primeira linha do ficheiro

    while IFS=$'\t' read -r size path; do 
        file2_lines["$path"]=$size 
    done < <(tail -n +2 "$file2")

    for i in "${!file1_lines[@]}"; do #para os diretorios que existem nos dois ficheiros
        for j in "${!file2_lines[@]}"; do
            if [[ "$i" == "$j" ]]; then
                if [[ ${file1_lines[$i]} == "NA" ]] || [[ ${file2_lines[$i]} == "NA" ]]; then #se um dos diretorios tiver tamanho NA o resultado é NA
                    echo -e "NA\t$i"
                else
                    echo -e "$((${file1_lines[$i]}-${file2_lines[$i]}))\t$i"
                fi
                break
            fi  
        done
    done

    for i in "${!file2_lines[@]}"; do #para os diretorios que existem no file2 mas não no file1 REMOVED
        if [[ ! "${file1_lines[$i]}" ]]; then
            if [[ ${file2_lines[$i]} == "NA" ]]; then
                echo -e "NA\t${i} REMOVED"
            else
                diff=$((file1_lines[$i] - file2_lines[$i]))
                echo -e "${diff}\t${i} REMOVED"
            fi
        fi
    done

    for i in "${!file1_lines[@]}"; do #para os diretorios que existem no file1 mas não no file2 NEW
        if [[ ! "${file2_lines[$i]}" ]]; then
            if [[ ${file1_lines[$i]} == "NA" ]]; then
                echo -e "NA\t${i} NEW"
            else
                echo -e "${file1_lines[$i]}\t${i} NEW"
            fi 
        fi
    done


}

compare "$file1" "$file2"| sort $sort