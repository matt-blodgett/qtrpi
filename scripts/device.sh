#!/usr/bin/env bash


function device::status() { msgs::status "${MSGS_PREFIX[device]} $1"; }
function device::verbose() { msgs::verbose "${MSGS_PREFIX[device]} $1"; }


function device::set_ssh_auth() {
    device::status "Setting up passwordless ssh with '$VAR_TARGET_HOST'"

    device::verbose "Running ssh-keygen"
    yes "" | ssh-keygen -t rsa
    msgs::check_exit_code "$?"

    device::verbose "Running ssh-copy-id to '$VAR_TARGET_HOST'"
    ssh-copy-id -i "~/.ssh/id_rsa.pub" "$VAR_TARGET_HOST"
    msgs::check_exit_code "$?"

    device::status "Successfully setup passwordless ssh with '$VAR_TARGET_HOST'"
}


function device::sync_sysroot() {
    device::status "Syncing sysroot with '$VAR_TARGET_HOST'"

    device::verbose "Running rsync '$VAR_TARGET_HOST:/lib' '$VAR_LOCAL_PATH/raspi/sysroot'"
    rsync -az $OPT_VERBOSE "$VAR_TARGET_HOST:/lib" "$VAR_LOCAL_PATH/raspi/sysroot"

    device::verbose "Running rsync '$VAR_TARGET_HOST:/usr/include' '$VAR_LOCAL_PATH/raspi/sysroot/usr'"
    rsync -az $OPT_VERBOSE "$VAR_TARGET_HOST:/usr/include" "$VAR_LOCAL_PATH/raspi/sysroot/usr"

    device::verbose "Running rsync '$VAR_TARGET_HOST:/usr/lib' '$VAR_LOCAL_PATH/raspi/sysroot/usr'"
    rsync -az $OPT_VERBOSE "$VAR_TARGET_HOST:/usr/lib" "$VAR_LOCAL_PATH/raspi/sysroot/usr"

    device::verbose "Running rsync '$VAR_TARGET_HOST:/opt/vc' '$VAR_LOCAL_PATH/raspi/sysroot/opt'"
    rsync -az $OPT_VERBOSE "$VAR_TARGET_HOST:/opt/vc" "$VAR_LOCAL_PATH/raspi/sysroot/opt"

    device::verbose "Running rsync '$VAR_LOCAL_PATH/raspi/qt5pi' '$VAR_TARGET_HOST:/usr/local'"
    rsync -az $OPT_VERBOSE "$VAR_LOCAL_PATH/raspi/qt5pi" "$VAR_TARGET_HOST:/usr/local"

    device::verbose "Fixing sysroot relativelinks at '$VAR_LOCAL_PATH/raspi/sysroot'"
    "$PWD"/scripts/sysroot-relativelinks.py "$VAR_LOCAL_PATH/raspi/sysroot" $OPT_VERBOSE

    device::status "Successfully synced sysroot with '$VAR_TARGET_HOST'"
}


function device::send_command() {
    local command="$1"

    device::verbose "Sending command '$command' to '$VAR_TARGET_HOST'"
    ssh "$VAR_TARGET_HOST" "$command"
    msgs::check_exit_code "$?"

    device::verbose "Successfully sent command '$command' to '$VAR_TARGET_HOST'"
}


function device::send_script() {
    local script_path="$1"

    device::verbose "Running script '$script_path' on '$VAR_TARGET_HOST'"
    cat "$script_path" | ssh "$VAR_TARGET_HOST"
    msgs::check_exit_code "$?"

    device::verbose "Successfully ran script '$script_path' on '$VAR_TARGET_HOST'"
}


function device::send_file() {
    device::verbose "Sending file to '$VAR_TARGET_HOST'"

    local source_path="$1"
    local target_path="$2"
    local source_file_name=$(basename "$source_path")

    local pi_command=""
    pi_command+="sudo cp ~/$source_file_name $target_path $OPT_VERBOSE "
    pi_command+="&& rm ~/$source_file_name $OPT_VERBOSE"

    scp "$source_path" "$VAR_TARGET_HOST:~/$source_file_name"
    msgs::check_exit_code "$?"

    ssh "$VAR_TARGET_HOST" "$pi_command"
    msgs::check_exit_code "$?"

    device::verbose "Successfully sent file '$source_path' to '$target_path' on '$VAR_TARGET_HOST'"
}
