#!/usr/bin/env bash


source ./utils.sh
source ./ofmt.sh


# -------------------------------------------------- GLOBALS
OPT_QUIET=false
OPT_VERBOSE=false
OPT_OUTPUT="all"
OPT_COMMAND=""

declare -n FLAG_MAP

declare -A COMMON_FLAGS=(
    ["help"]="h"
    ["quiet"]="q"
    ["verbose"]="v"
    ["output:"]=""
)
declare -A COMMAND_BUILD_FLAGS=(
    ["install"]=""
    ["rebuild"]=""
)
declare -A COMMAND_CONFIG_FLAGS=(
    ["local-path:"]=""
    ["target-path:"]=""
    ["target-host:"]=""
    ["target-device:"]=""
    ["qt-branch:"]=""
    ["qt-tag:"]=""
)
declare -A COMMAND_RESET_FLAGS=(
    ["all"]="a"
    ["build"]="b"
    ["config"]="c"
    ["device"]="d"
)
declare -A COMMAND_DEVICE_FLAGS=(
    ["set-ssh-auth"]="a"
    ["sync-sysroot"]="y"
    ["send-script:"]="s:"
    ["send-command:"]="c:"
    ["send-file:"]="f:"
)


# -------------------------------------------------- USAGE
function show_usage() {
    cat <<EOF
Usage: qtrpi.py [-h|-q|-v] [--output level] COMMAND [<options>]
Scripts for building and deploying Qt to RaspberryPi devices

Optional Flags:
 -h| --help              display this help text
 -q| --quiet             suppress all output
 -v| --verbose           output verbose messages
   | --output            set the output style [status,normal,silent,all]

Command Flags:
build                    Build Scripts
   | --install           install qtbase, build tools and create sysroot
   | --rebuild           rebuild qtbase and sync sysroot

config                   Set Configuration Variables
   | --local-path        local build path for modules and sysroot
   | --target-path       target install path for built Qt libs
   | --target-host       device address <"host@address">
   | --target-device     target device flag for cross compiling
   | --qt-branch         Qt version branch
   | --qt-tag            Qt version tag

reset                    Reset And Clean
 -a| --all               reset both build and config
 -b| --build             reset local qtrpi build process and clean
 -c| --config            reset all config variables to default
 -d| --device            reset remote device build process and clean

device                   Device Utils
 -a| --set-ssh-auth      set ssh key and add to known hosts
 -y| --sync-sysroot      sync sysroot directory
 -s| --send-script       send bash shell script to run on device
 -c| --send-command      send shell command to run on device
 -f| --send-file         send file to device

Git: <https://github.com/matt-blodgett/qtrpi.git>
EOF

    if [[ ! "$1" ]]
    then exit 1
    else exit $1; fi
}


# -------------------------------------------------- ERRORS
function show_error() {
    local err_msg="$1"
    if [[ "$err_msg" ]]; then
        set_ofmt -b --foreground "red"
        echo "$err_msg"
        clr_ofmt -a
    fi

    echo "use 'qtrpi.sh --help' for show_usage"
    exit 1
}


function should_error() {
    if [[ (($1 != 0)) ]]; then show_error; fi
}


function invalid_command() {
    if [[ "$OPT_COMMAND" != "" ]]; then
        show_error "invalid command '$OPT_COMMAND'";
    else
        show_error "missing required positional argument 'command'"
    fi
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

    local found=false
    for arg in ${_args[@]}; do
        if [[ "$arg" == -* ]]; then
            if [[ $(in_array "$arg" _flags) ]]; then
                found=true
                break
            fi
        fi
    done

    if [[ "$found" == false ]]; then
        show_error "missing required flags"
    fi
}


function check_mutually_exclusive_flags() {
    local -n _args=$1
    local -n _flags=$2

    local found=""
    for arg in ${_args[@]}; do
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

    for arg in ${_args[@]}; do
        if [[ "$arg" == -* ]]; then
            if [[ ! $(in_array "$arg" _flags) ]]; then
                invalid_flag "$arg"
            fi
        fi
    done
}


# -------------------------------------------------- VALIDATION
function parse_short_flags() {
    local -n args=$1

    local -a args_parsed=()
    for arg in ${args[@]}; do
        if [[ "$arg" == -* && "$arg" != --* && "${#arg}" > 2 ]]; then
            for c in $(echo "${arg:1}" | sed -e 's/\(.\)/\1\n/g'); do
                if [[ ! $(in_array "-$c" _flags_short) ]]; then
                    args_parsed+=( "-$c" )
                fi
            done
        else
            args_parsed+=( "$arg" )
        fi
    done

    echo ${args_parsed[@]}
}


function validate_common_args() {
    local -n args=$1

    for key in "${!COMMON_FLAGS[@]}"; do
        value="${COMMON_FLAGS[$key]}"
        if [[ "$value" ]]; then
            check_duplicate_flags args "$key" "$value"
        fi
    done

    local -a flags_mutex=( "-q" "--quiet" "-v" "--verbose" )
    check_mutually_exclusive_flags args flags_mutex
}


function validate_command_args() {
    local -n args=$1

    local mutex=true
    case "$OPT_COMMAND" in
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


function validate_output_type() {
    local -a output_types=( "status" "normal" "silent" "all" )

    local valid_type=false
    for output_type in ${output_types[@]}; do
        if [[ "$OPT_OUTPUT" == "$output_type" ]]; then
            valid_type=true
            break
        fi
    done

    if [[ "$valid_type" == false ]]; then
        local valid_choices="valid choices are [$(join_array "," ${output_types[@]})]"
        show_error "invalid output type '$OPT_OUTPUT' -- $valid_choices"
    fi
}


# -------------------------------------------------- COMMANDS
function cmd_run() {
    if [[ "$OPT_QUIET" == true ]]; then
        $1 "${@:2}" &>/dev/null
    else
        $1 "${@:2}"
    fi
}


function cmd_build() {
    source ./utils/build.sh
    source ./utils/device.sh

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
    source ./utils/config.sh

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
    source ./utils/reset.sh

    if [[ "$1" =~ ^(-a|--all)$ ]]; then
        reset_all
        exit 0
    fi

    for arg in $@; do
        case "$arg" in
            -b|--build  ) reset_build ;;
            -c|--config ) reset_config ;;
            -d|--device ) reset_device ;;
        esac
    done
}


function cmd_device() {
    source ./utils/device.sh

    case "$1" in
        -y|--sync-sysroot ) sync_sysroot ;;
        -f|--send-file    ) send_file "$2" "$3" ;;
        -s|--send-script  ) send_script "$2" ;;
        -c|--send-command ) send_command "$2" ;;
        -a|--set-ssh-auth ) set_ssh_auth ;;
    esac
}


# -------------------------------------------------- ENVIRONMENT
function check_variables() {
    var_path="$PWD"/utils/source/variables.sh
    if [[ ! -f "$var_path" ]]; then
        source ./utils/reset.sh
        reset_config
    fi
}


# -------------------------------------------------- MISC
function update_title() {
    set_ofmt --title "qtrpi | $OPT_COMMAND | $1"
}


# -------------------------------------------------- MAIN
function main() {
    cmd_run check_variables

    local -a args_array=( $@ )
    local -a args_parsed=$(parse_short_flags args_array)
    args_array=( ${args_parsed[@]} )
    args_parsed=()

    validate_common_args args_array
    while [[ $i -lt ${#args_array[@]} ]]; do
        local arg="${args_array[$i]}"

        case "$arg" in
            -h|--help    ) show_usage 0 ;;
            -q|--quiet   ) OPT_QUIET=true ;;
            -v|--verbose ) OPT_VERBOSE=true ;;
            --output     ) OPT_OUTPUT="${args_array[((++i))]}" ;;
            *            ) args_parsed+=( "$arg" ) ;;
        esac

        ((i++))
    done

    args_array=( ${args_parsed[@]} )
    args_parsed=()

    OPT_COMMAND="${args_array[0]}"
    validate_command_args args_array
    validate_output_type

    local flags_short="$(join_array "" "${FLAG_MAP[@]}")"
    local flags_long="$(join_array "," "${!FLAG_MAP[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "${args_array[@]}")
    should_error $?

    eval set -- "$flags_getopt"
    should_error $?

    case "$OPT_COMMAND" in
        build )
            cmd_run cmd_build "$1"
        ;;
        config )
            while true; do
                if [[ "$1" == "--" ]]; then break; fi
                cmd_run cmd_config "$1" "$2"
                shift 2
            done
        ;;
        reset )
            local resets=()
            while true; do
                case "$1" in
                    -a|--all    ) resets=( "-a" ); break ;;
                    -b|--build  ) resets+=( "-b" ); shift ;;
                    -c|--config ) resets+=( "-c" ); shift ;;
                    -d|--device ) resets+=( "-d" ); shift ;;
                    -- ) shift ;;
                    *  ) break ;;
                esac
            done

            cmd_run cmd_reset ${resets[@]}
        ;;
        device )
            case "$1" in
                -a|--set-ssh-auth ) cmd_run cmd_device "$1" ;;
                -y|--sync-sysroot ) cmd_run cmd_device "$1" ;;
                -s|--send-script  ) cmd_run cmd_device "$1" "$2" ;;
                -c|--send-command ) cmd_run cmd_device "$1" "$2" ;;
                -f|--send-file    )
                    local arg1=$(index_offset "$1" 1 args_array)
                    local arg2=$(index_offset "$1" 2 args_array)
                    cmd_run cmd_device "$1" "$arg1" "$arg2"
                ;;
            esac
        ;;
        * )
            invalid_command
        ;;
    esac
}


main "$@"
