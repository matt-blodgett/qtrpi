#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/common/variables.sh


function device::set_ssh_auth() {
    echo "set_ssh_auth"
    sleep 2
    return 0

    yes "" | ssh-keygen -t rsa
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$TARGET_HOST"
}


function device::sync_sysroot() {
    echo "sync_sysroot"
    sleep 5
    return 0

    rsync -avz "$TARGET_HOST:/lib" "$LOCAL_PATH/raspi/sysroot"
    rsync -avz "$TARGET_HOST:/usr/include" "$LOCAL_PATH/raspi/sysroot/usr"
    rsync -avz "$TARGET_HOST:/usr/lib" "$LOCAL_PATH/raspi/sysroot/usr"
    rsync -avz "$TARGET_HOST:/opt/vc" "$LOCAL_PATH/raspi/sysroot/opt"
    rsync -avz "$LOCAL_PATH/raspi/qt5pi" "$TARGET_HOST:/usr/local"

    "$SCRIPT_DIR"/sysroot-relativelinks.py "$LOCAL_PATH/raspi/sysroot"
}


function device::send_command() {
    echo "send_command $1"
    sleep 1
    return 0

    local command="$1"
    ssh "$TARGET_HOST" "$command"
}


function device::send_script() {
    echo "send_script $1"
    sleep 1
    return 0

    local script_path="$1"
    cat "$script_path" | ssh "$TARGET_HOST"
}


function device::send_file() {
    echo "send_file $1 $2"
    sleep 1
    return 0

    local source_path="$1"
    local target_path="$2"
    local source_file_name=$(basename "$source_path")
    scp "$source_path" "$TARGET_HOST:~/$source_file_name"
    device::send_command "sudo cp ~/$source_file_name $target_path && rm ~/$source_file_name"
}