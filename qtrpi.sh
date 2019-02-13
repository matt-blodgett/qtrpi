#!/usr/bin/env bash


# -------------------------------------------------- GLOBALS
declare -A COMMON_FLAGS
declare -A COMMAND_BUILD_FLAGS
declare -A COMMAND_CONFIG_FLAGS
declare -A COMMAND_RESET_FLAGS
declare -A COMMAND_DEVICE_FLAGS

COMMON_FLAGS=(
    ["--help"]="-h"
    ["--verbose"]="-v"
)
COMMAND_BUILD_FLAGS=(
    ["install"]=""
    ["rebuild"]=""
)
COMMAND_CONFIG_FLAGS=(
    ["local-path:"]=""
    ["target-path:"]=""
    ["target-host:"]=""
    ["target-device:"]=""
    ["qt-branch:"]=""
    ["qt-tag:"]=""
)
COMMAND_RESET_FLAGS=(
    ["all"]="a"
    ["build"]="b"
    ["config"]="c"
)
COMMAND_DEVICE_FLAGS=(
    ["sync-sysroot"]="y"
    ["send-file:"]="f:"
    ["send-script:"]="s:"
    ["send-command:"]="c:"
    ["set-ssh-auth"]="a"
)


declare -n FLAG_MAP
readonly COMMAND="$1"


# -------------------------------------------------- UTILS
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


# -------------------------------------------------- USAGE
function show_usage() {
    cat <<EOF
usage: qtrpi.py [options]
qtrpi: scripts for building and deploying Qt to Raspberry Pi devices

optional flags:
 -h| --help              display help text

command flags:

build                    build scripts
   | --install           install qtbase, build tools and create sysroot
   | --rebuild           rebuild qtbase and sync sysroot

config                   set configuration variables
   | --local-path        local build path for modules and sysroot
   | --target-path       target install path for built Qt libs
   | --target-host       device address <"host@address">
   | --target-device     target device flag for cross compiling
   | --qt-branch         Qt version branch
   | --qt-tag            Qt version tag

reset                    reset and clean
 -a| --all               reset both build and config
 -b| --build             reset qtrpi build process and clean
 -c| --config            reset all config variables to default

device                   device utils
 -y| --sync-sysroot      sync sysroot directory
 -f| --send-file         send file to device
 -s| --send-script       send bash shell script to run on device
 -c| --send-command      send shell command to run on device
 -a| --set-ssh-auth      set ssh key and add to known hosts

git: <https://github.com/matt-blodgett/qtrpi.git>
EOF

    exit $1
}


# -------------------------------------------------- ERRORS
function show_error() {
    if [[ "$1" ]]; then echo "$1"; fi
    echo "use 'qtrpi.sh --help' for show_usage"
    exit 1
}


function should_error() {
    if [[ (($1 != 0)) ]]; then show_error; fi
}


function invalid_command() {
    if [[ "$COMMAND" != "" ]]; then show_error "invalid command '$COMMAND'";
    else show_error "missing required positional argument 'command'"; fi
}


function invalid_flag() {
    show_error "unrecognized flag '$1'"
}


# -------------------------------------------------- CHECKS
function check_duplicate_flags() {
    local -n _args=$1
    local flag1="$2"
    local flag2="$3"

    if [[ $(in_array "$flag1" _args) && $(in_array "$flag2" _args) ]]; then
        show_error "duplicate flags '$flag1' and '$flag2'"
    fi
}


function check_required_flags() {
    local -n _args=$1
    local -n _flags=$2

    local found=0
    for arg in "${_args[@]}"; do
        if [[ "$arg" == -* ]]; then
            if [[ $(in_array "$arg" _flags) ]]; then
                found=1
                break
            fi
        fi
    done

    if [[ (("$found" == 0)) ]]; then
        show_error "missing required flags"
    fi
}


function check_mutually_exclusive_flags() {
    local -n _args=$1
    local -n _flags=$2

    local found=""
    for arg in "${_args[@]}"; do
        if [[ "$arg" == -* ]]; then
            if [[ $(in_array "$arg" _flags) ]]; then
                if [[ "$found" != "" ]]; then
                    show_error "cannot use both flags '$found' and '$arg'"
                fi
                found="$arg"
            fi
        fi
    done
}


function check_unrecognized_flags() {
    local -n _args=$1
    local -n _flags=$2

    for arg in "${_args[@]}"; do
        if [[ "$arg" == -* ]]; then
            if [[ ! $(in_array "$arg" _flags) ]]; then
                invalid_flag "$arg"
            fi
        fi
    done
}


# -------------------------------------------------- VALIDATION
function validate_args() {
    local -a args=()
    for arg in $@; do
        if [[ "$arg" =~ ^(-h|--help)$ ]]; then
            show_usage 0
        fi

        if [[ "$arg" == -* && "$arg" != --* && "${#arg}" > 2 ]]; then
            for c in $(echo "${arg:1}" | sed -e 's/\(.\)/\1\n/g'); do
                if [[ ! $(in_array "-$c" _flags_short) ]]; then
                    args+=( "-$c" )
                fi
            done
        else
            args+=( "$arg" )
        fi
    done

    local mutex=true
    case "$COMMAND" in
        build  ) FLAG_MAP=COMMAND_BUILD_FLAGS ;;
        config ) FLAG_MAP=COMMAND_CONFIG_FLAGS; mutex=false ;;
        reset  ) FLAG_MAP=COMMAND_RESET_FLAGS; mutex=false ;;
        device ) FLAG_MAP=COMMAND_DEVICE_FLAGS ;;
        *      ) invalid_command ;;
    esac

    local -a flags=()
    for key in "${!FLAG_MAP[@]}"; do
        flags+=( "--$(cut -f1 -d: <<<"$key")" )
        value="${FLAG_MAP[$key]}"
        if [[ "$value" ]]; then
            flags+=( "-$(cut -f1 -d: <<<"$value")" )
            check_duplicate_flags args "$key" "$value"
        fi
    done

    check_unrecognized_flags args flags
    check_required_flags args flags
    if [[ "$mutex" == true ]]; then
        check_mutually_exclusive_flags args flags
    fi
}


# -------------------------------------------------- COMMANDS
function cmd_build() {
    source ${0%/*}/utils/build.sh
    source ${0%/*}/utils/device.sh

    local cwd="$PWD"

    case "$1" in
        --install )
            init_local
            init_device
            sync_sysroot
            build_qtbase
            cd "$cwd"
            install_device
            sync_sysroot
        ;;
        --rebuild )
            sync_sysroot
            clean_module "qtbase"
            build_qtbase
            cd "$cwd"
            sync_sysroot
        ;;
    esac
}


function cmd_config() {
    source ${0%/*}/utils/config.sh

    case "$1" in
        --local-path    ) set_local_path "$2" ;;
        --target-path   ) set_target_path "$2" ;;
        --target-host   ) set_target_host "$2" ;;
        --target-device ) set_target_device "$2" ;;
        --qt-branch     ) set_qt_branch "$2" ;;
        --qt-tag        ) set_qt_tag "$2" ;;
    esac
}


function cmd_reset() {
    source ${0%/*}/utils/config.sh
    source ${0%/*}/utils/build.sh

    if [[ "$1" =~ ^(-a|--all)$ ]]; then
        reset_config
        reset_build
        exit 0
    fi

    for arg in $@; do
        case "$arg" in
            -b|--build  ) reset_build ;;
            -c|--config ) reset_config ;;
        esac
    done
}


function cmd_device() {
    source ${0%/*}/utils/device.sh

    case "$1" in
        -y|--sync-sysroot ) sync_sysroot ;;
        -f|--send-file    ) send_file "$2" "$3" ;;
        -s|--send-script  ) send_script "$2" ;;
        -c|--send-command ) send_command "$2" ;;
        -a|--set-ssh-auth ) set_ssh_auth ;;
    esac
}


function check_variables() {
    var_path=$PWD/utils/source/variables.sh
    if [[ ! -f "$var_path" ]]; then
        source ${0%/*}/utils/config.sh
        reset_config
    fi
}


# -------------------------------------------------- MAIN
function main() {
    check_variables

    local args="${@:1}"
    validate_args "$args"

    args_array=()
    for arg in $args; do
        args_array+=( "$arg" )
    done

    local -n args=args_array
    local flags_short="$(join_by "" "${FLAG_MAP[@]}")"
    local flags_long="$(join_by "," "${!FLAG_MAP[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "$@")
    should_error $?

    eval set -- "$flags_getopt"
    should_error $?

    case "$COMMAND" in
        build )
            cmd_build "$1"
        ;;
        config )
            while true; do
                if [[ "$1" == "--" ]]; then break; fi
                cmd_config "$1" "$2"
                shift 2
            done
        ;;
        reset )
            local resets=()
            while true; do
                case "$1" in
                    -a|--all )
                        cmd_reset "-a"
                        break
                    ;;
                    -b|--build )
                        resets+=( "-b" )
                        shift
                    ;;
                    -c|--config )
                        resets+=( "-c" )
                        shift
                    ;;
                    -- ) shift ;;
                    *  ) break ;;
                esac
            done

            cmd_reset "${resets[@]}"
        ;;
        device )
            case "$1" in
                -y|--sync-sysroot )
                    cmd_device "$1"
                ;;
                -f|--send-file )
                    local arg1=$(index_offset "$1" 1 args)
                    local arg2=$(index_offset "$1" 2 args)
                    cmd_device "$1" "$arg1" "$arg2"
                ;;
                -s|--send-script )
                    cmd_device "$1" "$2"
                ;;
                -c|--send-command )
                    cmd_device "$1" "$2"
                ;;
                -a|--set-ssh-auth )
                    cmd_device "$1"
                ;;
            esac
        ;;
        * )
            invalid_command
        ;;
    esac
}



main "$@"



