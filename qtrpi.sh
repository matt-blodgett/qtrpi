#!/usr/bin/env bash


function qtrpi::source() {
    source scripts/common/variables.sh
    source scripts/utils/args.sh
    source scripts/utils/array.sh
    source scripts/utils/ofmt.sh
    source scripts/utils/msgs.sh

    source scripts/build.sh
    source scripts/config.sh
    source scripts/reset.sh
    source scripts/device.sh
}


OPT_COMMAND=
OPT_VERBOSE=
OPT_LOGFILE=
OPT_OUTPUT=all
OPT_NOCONFIRM=false


declare -n FLAG_MAP

declare -A COMMON_FLAGS=(
    ["help"]="h"
    ["verbose"]="v"
    ["output:"]=""
    ["logfile:"]=""
    ["noconfirm"]=""
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


function qtrpi::usage() {
    cat <<EOF
Usage: qtrpi.py [-h|-q|-v] [--output level] COMMAND [<options>]
Scripts for building and deploying Qt to RaspberryPi devices

Optional Flags:
 -h| --help              display this help text
 -v| --verbose           output verbose messages
   | --output            set the output level [all,quiet,silent]
   | --logfile           a file to record suppressed output [quiet]
   | --noconfirm         suppress and confirm any confirmation messages

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

    if [[ ! "$1" ]]; then exit 1; else exit $1; fi
}


function qtrpi::validate_common_args() {
    local -n args=$1

    for key in "${!COMMON_FLAGS[@]}"; do
        value="${COMMON_FLAGS[$key]}"
        if [[ "$value" ]]; then
            args::check_duplicate_flags args "$key" "$value"
        fi
    done

    local -a flags_mutex=( "-v" "--verbose" )
    args::check_mutually_exclusive_flags args flags_mutex
}


function qtrpi::validate_command_args() {
    local -n args=$1

    local mutex=true
    case "$OPT_COMMAND" in
        build  ) FLAG_MAP=COMMAND_BUILD_FLAGS ;;
        config ) FLAG_MAP=COMMAND_CONFIG_FLAGS; mutex=false ;;
        reset  ) FLAG_MAP=COMMAND_RESET_FLAGS; mutex=false ;;
        device ) FLAG_MAP=COMMAND_DEVICE_FLAGS ;;
    esac

    local -a flags=()
    for key in "${!FLAG_MAP[@]}"; do
        flags+=( "--$(cut -f1 -d: <<<"$key")" )
        value="${FLAG_MAP[$key]}"
        if [[ "$value" ]]; then
            flags+=( "-$(cut -f1 -d: <<<"$value")" )
            args::check_duplicate_flags args "$key" "$value"
        fi
    done

    args::check_unrecognized_flags args flags
    args::check_required_flags args flags

    if [[ "$mutex" == true ]]; then
        args::check_mutually_exclusive_flags args flags
    fi
}


function qtrpi::build() {
    case "$1" in
        --install )
            local title_prefix="qtrpi: install step"
            local step_number=1
            local step_total=6
            local title=""

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            build::init_local

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            build::init_device

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            device::sync_sysroot

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            build::build_qtbase

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            build::install_device

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            device::sync_sysroot

            ofmt::set_format --title "" >&3
        ;;
        --rebuild )
            local title_prefix="qtrpi: rebuild step"
            local step_number=1
            local step_total=4
            local title=""

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            device::sync_sysroot

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            build::clean_module "qtbase"

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            build::build_qtbase

            title="$title_prefix $((step_number++)) of $step_total"
            ofmt::set_format --title "$title" >&3
            device::sync_sysroot

            ofmt::set_format --title "" >&3
        ;;
    esac
}


function qtrpi::config() {
    case "$1" in
        --local-path    ) config::set_local_path "$2" ;;
        --target-path   ) config::set_target_path "$2" ;;
        --target-host   ) config::set_target_host "$2" ;;
        --target-device ) config::set_target_device "$2" ;;
        --qt-branch     ) config::set_qt_branch "$2" ;;
        --qt-tag        ) config::set_qt_tag "$2" ;;
    esac
}


function qtrpi::reset() {
    local confirm_msg=""

    if [[ "$1" =~ ^(-a|--all)$ ]]; then
        confirm_msg="Are you sure you want to reset all qtrpi files "
        confirm_msg+="including configuration files and all related "
        confirm_msg+="local and remote build files? "

        if [[ $(msgs::confirm "$confirm_msg") ]]; then reset::all; fi
        exit 0
    fi

    local reset_build=false
    local reset_config=false
    local reset_device=false

    for arg in $@; do
        case "$arg" in
            -b|--build  ) reset_build=true ;;
            -c|--config ) reset_config=true ;;
            -d|--device ) reset_device=true ;;
        esac
    done

    confirm_msg="Are you sure you want to reset?"
    if [[ $(msgs::confirm "$confirm_msg") ]]; then
        if [[ "$reset_build" == true ]]; then reset::build; fi
        if [[ "$reset_device" == true ]]; then reset::device; fi
        if [[ "$reset_config" == true ]]; then reset::config; fi
    fi
}


function qtrpi::device() {
    case "$1" in
        -y|--sync-sysroot ) device::sync_sysroot ;;
        -f|--send-file    ) device::send_file "$2" "$3" ;;
        -s|--send-script  ) device::send_script "$2" ;;
        -c|--send-command ) device::send_command "$2" ;;
        -a|--set-ssh-auth ) device::set_ssh_auth ;;
    esac
}


function qtrpi::check_config() {
    local path_vars="$PWD/scripts/common/variables.sh"
    local default_vars=false

    local path_opts="$PWD/scripts/common/options.txt"
    local default_opts=false

    if [[ ! -d "$PWD/scripts/common" ]]; then
        mkdir "$PWD/scripts/common"
    fi

    if [[ ! -f "$path_vars" ]]; then
        default_vars=true
        touch "$path_vars"
    fi

    if [[ ! -f "$path_opts" ]]; then
        default_opts=true
        touch "$path_opts"
    fi

    if [[ "$default_vars" == true || "$default_opts" == true ]]; then
        OPT_OUTPUT=all
        qtrpi::source
        msgs::initialize
    fi

    if [[ "$default_vars" == true ]]; then
        reset::config "vars"
    fi

    if [[ "$default_opts" == true ]]; then
        reset::config "opts"
    fi
}


function main() {
    qtrpi::check_config
    qtrpi::source

    local -a args_array=( $@ )
    local -a args_parsed=$(args::parse_short_flags args_array)
    args_array=( ${args_parsed[@]} )
    args_parsed=()

    qtrpi::validate_common_args args_array
    while [[ $i -lt ${#args_array[@]} ]]; do
        local arg="${args_array[((i++))]}"

        case "$arg" in
            -h|--help    ) qtrpi::usage 0 ;;
            -v|--verbose ) OPT_VERBOSE="-v" ;;
            --output     ) OPT_OUTPUT="${args_array[((i++))]}" ;;
            --logfile    ) OPT_LOGFILE="${args_array[((i++))]}" ;;
            --noconfirm  ) OPT_NOCONFIRM=true ;;
            *            ) args_parsed+=( "$arg" ) ;;
        esac
    done

    args_array=( ${args_parsed[@]} )
    OPT_COMMAND="${args_array[0]}"

    local -a output_types=( "all" "quiet" "silent" )
    args::check_valid_choice "$OPT_OUTPUT" output_types "output"
    msgs::initialize

    local -a command_types=( "build" "config" "reset" "device" )
    args::check_valid_choice "$OPT_COMMAND" command_types "command"
    qtrpi::validate_command_args args_array

    local flags_short="$(array::join "" "${FLAG_MAP[@]}")"
    local flags_long="$(array::join "," "${!FLAG_MAP[@]}")"
    local flags_getopt=$(getopt -o "$flags_short" --longoptions "$flags_long" -- "${args_array[@]}")
    args::check_exit_code $?

    eval set -- "$flags_getopt"
    args::check_exit_code $?

    case "$OPT_COMMAND" in
        build )
            qtrpi::build "$1"
        ;;
        config )
            while true; do
                if [[ "$1" == "--" ]]; then break; fi
                qtrpi::config "$1" "$2"
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

            qtrpi::reset ${resets[@]}
        ;;
        device )
            case "$1" in
                -a|--set-ssh-auth ) qtrpi::device "$1" ;;
                -y|--sync-sysroot ) qtrpi::device "$1" ;;
                -s|--send-script  ) qtrpi::device "$1" "$2" ;;
                -c|--send-command ) qtrpi::device "$1" "$2" ;;
                -f|--send-file    )
                    local arg1=$(array::value_offset "$1" 1 args_array)
                    local arg2=$(array::value_offset "$1" 2 args_array)
                    qtrpi::device "$1" "$arg1" "$arg2"
                ;;
            esac
        ;;
    esac
}


main "$@"
