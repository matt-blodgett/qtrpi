#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/ofmt.sh


exec 3>&1


function msgs::initialize() {
    local suppress="$1"
    if [[ "$suppress" == true ]]; then
        exec 3>&1 4>&2
        trap 'exec 2>&4 1>&3' 0 1 2 3
        exec 1>log.txt 2>&1
    else
        exec 3>&1
    fi
}


function msgs::status_message() {
    local sts_msg="$1"
    if [[ "$sts_msg" ]]; then
        echo "$sts_msg" >&3
    fi
}


function msgs::error_message() {
    local err_msg="$1"
    if [[ "$err_msg" ]]; then
        ofmt::set_format -b --foreground "red" >&3
        echo "$err_msg" >&3
        ofmt::clr_format -a >&3
    fi
}


function msgs::update_title() {
    ofmt::set_format --title "qtrpi | $OPT_COMMAND | $1"
}


#function cmd_run() {
#    if [[ "$OPT_QUIET" == true ]]; then
#        $1 "${@:2}" &>/dev/null
#    else
#        $1 "${@:2}"
#    fi
#}