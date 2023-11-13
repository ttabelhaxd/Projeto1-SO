#!/bin/bash

input_args="$@"
regex=".*" #regex padrão, todo o tipo de arquivo, se não existir -n + regex de input
date=""
size="0"
sort="-k1,1nr" #sort padrão, ordena por tamanho maior para o menor, se não existir -r de input
limit_lines=""

usage() {
    echo "Usage: $0 [-n <'.*fileFormat'>] [-d <'Month Day hh:mm'>] [-s <'size'>] [-l <'number of lines'>] [-r] [-a] <dir>
    -n Sort by file format
    -d Sort by date
    -s Sort by size
    -l Limit of printed lines
    -r Sort by size, smallest to largest
    -a Sort by name, alphabetically" #help
    exit 1
}

while getopts "n:d:s:l:ra" opt; do
    case $opt in
        n)
            regex="$OPTARG" ;; # -n + regex, exemplo -n ".*\.txt", -n ".*\.sh"
        d)
            date="$OPTARG" ;; #guarda a data na variavel date
        s)
            size="$OPTARG" ;; #filtra os ficheiros com tamanho superior a -s + size
        l)
            limit_lines="$OPTARG" ;; #-l + nlinhas, numero maximo de linhas
        r)
            sort="-k1,1n" ;; #sort reverse, ordena por tamanho dos bytes inverso do menor para o maior
        a)
            sort="-k2,2" ;; #sort por nome alfabeticamente dos diretorios
        *)
            usage ;;   
    esac
done
shift $((OPTIND - 1)) #shift para ignorar as opções e ficar apenas com os argumentos

calc_file_space() {
    du -b "$1" 2>/dev/null | cut -f1  #calcula o tamanho do ficheiro em bytes
    return "${PIPESTATUS[0]}" #retorna o valor de erro do du
}

calc_dir_space() {
    local dir="$1"
    local total_space=0

    while read file; do
        file_space=$(calc_file_space "$file")
        if [ $? -ne 0 ]; then
            total_space="NA"
            break;
        else
            total_space=$((total_space + file_space))
        fi
    done < <(find "$dir" -type f -regex "$regex") #encontra todos os ficheiros que correspondem ao regex

    echo "$total_space"

}

echo -e "SIZE\tNAME\t$(date +%Y%m%d)\t$input_args"

for dir in "$@"; do
    if [ -d "$dir" ]; then
        if [ -z "$date" ]; then #se a data não for especificada
            find "$dir" -type d | while read line; do
            echo -e "$(calc_dir_space "$line")\t$line\t"
        done | sort $sort | awk -v size="$size" '{if ($1 >= size) print $1"\t"$2"\t"}' | head -$limit_lines
        else
            find "$dir" -type d -newermt "$date" | while read line; do
            echo -e "$(calc_dir_space "$line")\t$line\t"
        done | sort $sort | awk -v size="$size" '{if ($1 >= size) print $1"\t"$2"\t"}' | head -$limit_lines
        fi   
    else
        echo "$dir: O diretório não existe."
        usage
    fi
done 