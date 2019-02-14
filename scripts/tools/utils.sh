#!/usr/bin/env bash


function in_array() {
    local value="$1"
    local -n array=$2

    for val in "${array[@]}"; do
        if [[ "$val" == "$value" ]]; then
            echo 1
        fi
    done
}


function index_of() {
    local value="$1"
    local -n array=$2

    local i=0
    for val in "${array[@]}"; do
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
    local -n array=$3
    local index=$(index_of "$flag" array)
    echo "${array[((index+offset))]}"
}


function join_array {
    local IFS="$1"; shift; echo "$*";
}