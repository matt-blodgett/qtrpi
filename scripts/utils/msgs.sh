#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/ofmt.sh


function msgs::initialize() {
    local level="$1"
    local logfile="$2"

    case "$level" in
        all )
            exec 3>&1
        ;;
        quiet )
            exec 3>&1 4>&2
            trap 'exec 2>&4 1>&3' 0 1 2 3

            if [[ ! "$logfile" ]]; then
                exec 1>"$logfile" 2>&1
            else
                exec 1>/dev/null 2>&1
            fi
        ;;
        silent )
            exec 1>/dev/null
            exec 2>/dev/null
            exec 3>/dev/null
        ;;
    esac
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