#!/usr/bin/env bash


function device::set_ssh_auth() {
    yes "" | ssh-keygen -t rsa
    ssh-copy-id -i "~/.ssh/id_rsa.pub" "$TARGET_HOST"
}


function device::sync_sysroot() {
    rsync -az $OPT_VERBOSE "$TARGET_HOST:/lib" "$LOCAL_PATH/raspi/sysroot"
    rsync -az $OPT_VERBOSE "$TARGET_HOST:/usr/include" "$LOCAL_PATH/raspi/sysroot/usr"
    rsync -az $OPT_VERBOSE "$TARGET_HOST:/usr/lib" "$LOCAL_PATH/raspi/sysroot/usr"
    rsync -az $OPT_VERBOSE "$TARGET_HOST:/opt/vc" "$LOCAL_PATH/raspi/sysroot/opt"
    rsync -az $OPT_VERBOSE "$LOCAL_PATH/raspi/qt5pi" "$TARGET_HOST:/usr/local"

    "$PWD"/scripts/sysroot-relativelinks.py "$LOCAL_PATH/raspi/sysroot" $OPT_VERBOSE
}


function device::send_command() {
    local command="$1"
    ssh "$TARGET_HOST" "$command"
}


function device::send_script() {
    local script_path="$1"
    cat "$script_path" | ssh "$TARGET_HOST"
}


function device::send_file() {
    local source_path="$1"
    local target_path="$2"
    local source_file_name=$(basename "$source_path")

    local pi_command=""
    pi_command+="sudo cp ~/$source_file_name $target_path $OPT_VERBOSE "
    pi_command+="&& rm ~/$source_file_name $OPT_VERBOSE"

    scp "$source_path" "$TARGET_HOST:~/$source_file_name"
    device::send_command "$pi_command"
}