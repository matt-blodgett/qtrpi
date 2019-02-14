#!/usr/bin/env bash


source ./utils.sh


declare -A MARKUP_MAP=(
    ["bold"]="\e[1m"
    ["dim"]="\e[2m"
    ["underlined"]="\e[4m"
    ["blinking"]="\e[5m"
    ["hidden"]="\e[8m"
)
declare -A FOREGROUND_MAP=(
    ["default"]="\e[39m"
    ["black"]="\e[30m"
    ["red"]="\e[31m"
    ["green"]="\e[32m"
    ["yellow"]="\e[33m"
    ["blue"]="\e[34m"
    ["magenta"]="\e[35m"
    ["cyan"]="\e[36m"
    ["light_gray"]="\e[37m"
    ["dark_gray"]="\e[90m"
    ["light_red"]="\e[91m"
    ["light_green"]="\e[92m"
    ["light_yellow"]="\e[93m"
    ["light_blue"]="\e[94m"
    ["light_magenta"]="\e[95m"
    ["light_cyan"]="\e[96m"
    ["white"]="\e[97m"
)
declare -A BACKGROUND_MAP=(
    ["default"]="\e[49m"
    ["black"]="\e[40m"
    ["red"]="\e[41m"
    ["green"]="\e[42m"
    ["yellow"]="\e[43m"
    ["blue"]="\e[44m"
    ["magenta"]="\e[45m"
    ["cyan"]="\e[46m"
    ["light_gray"]="\e[47m"
    ["dark_gray"]="\e[100m"
    ["light_red"]="\e[101m"
    ["light_green"]="\e[102m"
    ["light_yellow"]="\e[103m"
    ["light_blue"]="\e[104m"
    ["light_magenta"]="\e[105m"
    ["light_cyan"]="\e[106m"
    ["white"]="\e[107m"
)
declare -A CLEAR_MAP=(
    ["all"]="\e[0m"
    ["text"]="\e[20m"
    ["foreground"]="\e[39m"
    ["background"]="\e[49m"
)


function set_clear() { echo -ne "${CLEAR_MAP[$1]}"; }
function set_markup() { echo -ne "${MARKUP_MAP[$1]}"; }
function set_foreground() { echo -ne "${FOREGROUND_MAP[$1]}"; }
function set_background() { echo -ne "${BACKGROUND_MAP[$1]}"; }
function set_console_title() { echo -ne '\033]2;'$1'\007'; }


function set_ofmt() {
    declare -A flag_map=(
        ["bold"]="b"
        ["dim"]="d"
        ["underlined"]="u"
        ["blinking"]=""
        ["foreground:"]=""
        ["background:"]=""
        ["title:"]=""
    )

    local flags_short="$(join_by "" "${flag_map[@]}")"
    local flags_long="$(join_by "," "${!flag_map[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "$@")

    eval set -- "$flags_getopt"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--bold       ) set_markup "bold"; shift ;;
            -d|--dim        ) set_markup "dim"; shift ;;
            -u|--underlined ) set_markup "underlined"; shift ;;
            --blinking      ) set_markup "blinking"; shift ;;
            --hidden        ) set_markup "hidden"; shift ;;
            --foreground    ) set_foreground "$2"; shift 2 ;;
            --background    ) set_background "$2"; shift 2 ;;
            --title         ) set_console_title "$2"; shift 2 ;;
            * ) break ;;
        esac
    done
}


function clr_ofmt() {
    if [[ "$#" == 0 ]]; then
        set_clear "all"
        exit 0
    fi

    declare -A flag_map=(
        ["all"]="a"
        ["text"]="t"
        ["foreground"]="f"
        ["background"]="b"
    )

    local flags_short="$(join_by "" "${flag_map[@]}")"
    local flags_long="$(join_by "," "${!flag_map[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "$@")

    eval set -- "$flags_getopt"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all        ) set_clear "all"; shift ;;
            -t|--text       ) set_clear "text"; shift ;;
            -f|--foreground ) set_clear "foreground"; shift ;;
            -b|--background ) set_clear "background"; shift ;;
            * ) break ;;
        esac
    done
}