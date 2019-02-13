#!/usr/bin/env bash


function in_array() {
    local value="$1"
    local -n _arr=$2

    for val in "${_arr[@]}"; do
        if [[ "$val" == "$value" ]]; then
            echo 1
        fi
    done
}


function index_of() {
    local value="$1"
    local -n _arr=$2

    local i=0
    for val in "${_arr[@]}"; do
        if [[ "$val" == "$value" ]]; then
            echo "$i"
            break
        fi
        ((i++))
    done
}


function index_offset() {
    local flag="$1"
    local offset="$2"
    local -n __arr=$3
    local index=$(index_of "$flag" __arr)
    echo "${__arr[ (( index + offset )) ]}"
}


function join_by {
    local IFS="$1"; shift; echo "$*";
}