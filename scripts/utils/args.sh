#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/array.sh
source "$SCRIPT_DIR"/msgs.sh


function args::usage_error() {
    local error_message="$1"
    msgs::error_message "$error_message"
    msgs::status_message "use 'qtrpi.sh --help' for usage"
    exit 1
}


function args::check_exit_code() {
    local exit_code="$1"
    if [[ "$exit_code" != 0 ]]; then
        msgs::error_message "the process finished with exit code $1"
        exit $1
    fi
}


function args::check_duplicate_flags() {
    local -n _args=$1
    local flag1="$2"
    local flag2="$3"

    if [[ $(array::contains "$flag1" _args) && $(array::contains "$flag2" _args) ]]; then
        args::usage_error "duplicate flags '$flag1' and '$flag2'"
    fi
}


function args::check_required_flags() {
    local -n _args=$1
    local -n _flags=$2

    local found=false
    for arg in ${_args[@]}; do
        if [[ "$arg" == -* ]]; then
            if [[ $(array::contains "$arg" _flags) ]]; then
                found=true
                break
            fi
        fi
    done

    if [[ "$found" == false ]]; then
        args::usage_error "missing required flags"
    fi
}


function args::check_mutually_exclusive_flags() {
    local -n _args=$1
    local -n _flags=$2

    local found=""
    for arg in ${_args[@]}; do
        if [[ "$arg" == -* ]]; then
            if [[ $(array::contains "$arg" _flags) ]]; then
                if [[ "$found" != "" ]]; then
                    args::usage_error "cannot use both flags '$found' and '$arg'"
                fi
                found="$arg"
            fi
        fi
    done
}


function args::check_unrecognized_flags() {
    local -n _args=$1
    local -n _flags=$2

    for arg in ${_args[@]}; do
        if [[ "$arg" == -* ]]; then
            if [[ ! $(array::contains "$arg" _flags) ]]; then
                args::usage_error "unrecognized flag '$arg'"
            fi
        fi
    done
}


function args::check_valid_choice() {
    local choice_value="$1"
    local -n choice_list=$2
    local choice_type="$3"

    local is_valid=false
    for ch in ${choice_list[@]}; do
        if [[ "$ch" == "$choice_value" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" == false ]]; then
        local valid_choices="valid choices are [$(array::join "," ${choice_list[@]})]"
        args::usage_error "invalid value '$choice_value' for positional argument '$choice_type' -- $valid_choices"
    fi
}


function args::parse_short_flags() {
    local -n args=$1

    local -a args_parsed=()
    for arg in ${args[@]}; do
        if [[ "$arg" == -* && "$arg" != --* && "${#arg}" > 2 ]]; then
            for c in $(echo "${arg:1}" | sed -e 's/\(.\)/\1\n/g'); do
                args_parsed+=( "-$c" )
            done
        else
            args_parsed+=( "$arg" )
        fi
    done

    echo ${args_parsed[@]}
}