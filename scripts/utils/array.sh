#!/usr/bin/env bash


function array::contains() {
    local value="$1"
    local -n array=$2

    for val in ${array[@]}; do
        if [[ "$val" == "$value" ]]; then
            echo 1
        fi
    done
}


function array::index_of() {
    local value="$1"
    local -n arr=$2

    local i=0
    for val in ${arr[@]}; do
        if [[ "$val" == "$value" ]]; then
            echo "$i"
            break
        fi
        ((i++))
    done
}


function array::value_offset() {
    local value="$1"
    local offset="$2"
    local -n array=$3
    local index=$(array::index_of "$value" array)
    echo "${array[((index+offset))]}"
}


function array::join {
    local IFS="$1"; shift; echo "$*";
}
