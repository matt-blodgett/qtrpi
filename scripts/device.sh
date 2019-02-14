#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/common/variables.sh


function set_ssh_auth() {
    yes "" | ssh-keygen -t rsa
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$TARGET_HOST"
}


function sync_sysroot() {
    rsync -avz "$TARGET_HOST:/lib" "$LOCAL_PATH/raspi/sysroot"
    rsync -avz "$TARGET_HOST:/usr/include" "$LOCAL_PATH/raspi/sysroot/usr"
    rsync -avz "$TARGET_HOST:/usr/lib" "$LOCAL_PATH/raspi/sysroot/usr"
    rsync -avz "$TARGET_HOST:/opt/vc" "$LOCAL_PATH/raspi/sysroot/opt"
    rsync -avz "$LOCAL_PATH/raspi/qt5pi" "$TARGET_HOST:/usr/local"

    "$SCRIPT_DIR"/sysroot-relativelinks.py "$LOCAL_PATH/raspi/sysroot"
}


function send_command() {
    local command="$1"
    ssh "$TARGET_HOST" "$command"
}


function send_script() {
    local script_path="$1"
    cat "$script_path" | ssh "$TARGET_HOST"
}


function send_file() {
    local source_path="$1"
    local target_path="$2"
    local source_file_name=$(basename "$source_path")
    scp "$source_path" "$TARGET_HOST:~/$source_file_name"
    send_command "sudo cp ~/$source_file_name $target_path && rm ~/$source_file_name"
}