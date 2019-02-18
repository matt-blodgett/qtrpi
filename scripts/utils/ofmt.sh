#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/array.sh


declare -A MARKUP_MAP=(
    ["bold"]="1"
    ["dim"]="2"
    ["underlined"]="4"
    ["blinking"]="5"
    ["hidden"]="8"
)
declare -A FOREGROUND_MAP=(
    ["default"]="39"
    ["black"]="30"
    ["red"]="31"
    ["green"]="32"
    ["yellow"]="33"
    ["blue"]="34"
    ["magenta"]="35"
    ["cyan"]="36"
    ["light_gray"]="37"
    ["dark_gray"]="90"
    ["light_red"]="91"
    ["light_green"]="92"
    ["light_yellow"]="93"
    ["light_blue"]="94"
    ["light_magenta"]="95"
    ["light_cyan"]="96"
    ["white"]="97"
)
declare -A BACKGROUND_MAP=(
    ["default"]="49"
    ["black"]="40"
    ["red"]="41"
    ["green"]="42"
    ["yellow"]="43"
    ["blue"]="44"
    ["magenta"]="45"
    ["cyan"]="46"
    ["light_gray"]="47"
    ["dark_gray"]="100"
    ["light_red"]="101"
    ["light_green"]="102"
    ["light_yellow"]="103"
    ["light_blue"]="104"
    ["light_magenta"]="105"
    ["light_cyan"]="106"
    ["white"]="107"
)
declare -A CLEAR_MAP=(
    ["all"]="0"
    ["text"]="20"
    ["foreground"]="39"
    ["background"]="49"
)


function ofmt::set_escape() { echo -ne "\e[$1m"; }
function ofmt::set_clear() { ofmt::set_escape "${CLEAR_MAP[$1]}"; }
function ofmt::set_markup() { ofmt::set_escape "${MARKUP_MAP[$1]}"; }
function ofmt::set_foreground() { ofmt::set_escape "${FOREGROUND_MAP[$1]}"; }
function ofmt::set_background() { ofmt::set_escape "${BACKGROUND_MAP[$1]}"; }
function ofmt::set_console_title() { echo -ne '\033]2;'$1'\007'; }


function ofmt::set_format() {
    declare -A flag_map=(
        ["bold"]="b"
        ["dim"]="d"
        ["underlined"]="u"
        ["blinking"]=""
        ["foreground:"]=""
        ["background:"]=""
        ["title:"]=""
    )

    local flags_short="$(array::join "" "${flag_map[@]}")"
    local flags_long="$(array::join "," "${!flag_map[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "$@")

    eval set -- "$flags_getopt"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--bold       ) ofmt::set_markup "bold"; shift ;;
            -d|--dim        ) ofmt::set_markup "dim"; shift ;;
            -u|--underlined ) ofmt::set_markup "underlined"; shift ;;
            --blinking      ) ofmt::set_markup "blinking"; shift ;;
            --hidden        ) ofmt::set_markup "hidden"; shift ;;
            --foreground    ) ofmt::set_foreground "$2"; shift 2 ;;
            --background    ) ofmt::set_background "$2"; shift 2 ;;
            --title         ) ofmt::set_console_title "$2"; shift 2 ;;
            * ) break ;;
        esac
    done
}


function ofmt::clr_format() {
    if [[ "$#" == 0 ]]; then
        ofmt::set_clear "all"
        return 0
    fi

    declare -A flag_map=(
        ["all"]="a"
        ["text"]="t"
        ["foreground"]="f"
        ["background"]="b"
    )

    local flags_short="$(array::join "" "${flag_map[@]}")"
    local flags_long="$(array::join "," "${!flag_map[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "$@")

    eval set -- "$flags_getopt"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all        ) ofmt::set_clear "all"; shift ;;
            -t|--text       ) ofmt::set_clear "text"; shift ;;
            -f|--foreground ) ofmt::set_clear "foreground"; shift ;;
            -b|--background ) ofmt::set_clear "background"; shift ;;
            * ) break ;;
        esac
    done
}