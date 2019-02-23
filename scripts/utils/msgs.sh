#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/ofmt.sh


declare -A MSGS_PREFIX=(
    ["main"]="qtrpi | main   |"
    ["build"]="qtrpi | build  |"
    ["config"]="qtrpi | config |"
    ["device"]="qtrpi | device |"
    ["reset"]="qtrpi | reset  |"
)


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
    local status_msg="$1"
    if [[ "$status_msg" ]]; then
        ofmt::set_format -b --foreground "cyan" >&3
        echo "$status_msg" >&3
        ofmt::clr_format -a >&3

        sleep 1
    fi
}


function msgs::verbose() {
    local verbose_message="$1"
    if [[ "$verbose_message" && "$OPT_VERBOSE" ]]; then
        echo "$verbose_message" >&3
    fi
}


function msgs::error() {
    local error_msg="$1"
    if [[ "$error_msg" ]]; then
        ofmt::set_format -b --foreground "red" >&3
        echo "$error_msg" >&3
        ofmt::clr_format -a >&3
    fi
}


function msgs::check_exit_code() {
    local exit_code="$1"
    if [[ "$exit_code" != 0 ]]; then
        msgs::error "the program exited unexpectedly with code $1"
        exit "$1"
    fi
}
