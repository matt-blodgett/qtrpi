#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/ofmt.sh


function msgs::initialize() {
    case "$OPT_OUTPUT" in
        all )
            exec 5>&1
            exec 6>&2
            exec 3>&1
        ;;
        quiet )
            exec 3>&1 4>&2
            trap 'exec 2>&4 1>&3' 0 1 2 3

            exec 5>&1 >/dev/null
            exec 6>&2 >/dev/null

            if [[ "$OPT_LOGFILE" ]]; then
                exec 1>"$OPT_LOGFILE" 2>&1
            else
                exec 1>/dev/null 2>&1
            fi
        ;;
        silent )
            exec 5>&1 >/dev/null
            exec 6>&2 >/dev/null

            exec 1>/dev/null
            exec 2>/dev/null
            exec 3>/dev/null
        ;;
    esac
}


function msgs::confirm() {
    local confirm_msg="$1"

    if [[ "$OPT_NOCONFIRM" == true ]]; then
        echo 1;
    else
        exec 2>&6

        while true; do
            read -p "$confirm_msg [Y/n] " yn
            case $yn in
                y|Y) echo 1; break ;;
                n|N) break ;;
                *  ) break ;;
            esac
        done

        exec 6>&2 >/dev/null
        exec 2>/dev/null
    fi
}


function msgs::status() {
    local sts_msg="$1"
    if [[ "$sts_msg" ]]; then
        echo "$sts_msg" >&3
    fi
}


function msgs::error() {
    local err_msg="$1"
    if [[ "$err_msg" ]]; then
        ofmt::set_format -b --foreground "red" >&3
        echo "$err_msg" >&3
        ofmt::clr_format -a >&3
    fi
}


function msgs::title() {
    ofmt::set_format --title "qtrpi | $OPT_COMMAND | $1"
}