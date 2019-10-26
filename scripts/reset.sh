#!/usr/bin/env bash


function reset::status() { msgs::status "${MSGS_PREFIX[reset]} $1"; }
function reset::verbose() { msgs::verbose "${MSGS_PREFIX[reset]} $1"; }


function reset::build() {
    reset::status "Removing local build files from '$VAR_LOCAL_PATH'"
    sudo rm -rf "$VAR_LOCAL_PATH" $OPT_VERBOSE
    msgs::check_exit_code "$?"
    reset::status "Successfully removed local build files from '$VAR_LOCAL_PATH'"
}


function reset::device() {
    reset::status "Removing remote build files from '$VAR_TARGET_PATH' on '$VAR_TARGET_HOST'"
    device::send_command "sudo rm -rf $VAR_TARGET_PATH $OPT_VERBOSE"
    reset::status "Successfully removed remote build files from '$VAR_TARGET_PATH' on '$VAR_TARGET_HOST'"
}


function reset::config() {
    reset::status "Resetting program variables to defaults"

    local reset_only="$1"

    local vars=$(cat <<EOF
#!/usr/bin/env bash
VAR_LOCAL_PATH="/opt/qtrpi"
VAR_TARGET_PATH="/usr/local/qt5pi"
VAR_TARGET_HOST=""
VAR_TARGET_DEVICE="linux-rasp-pi3-g++"
VAR_QT_BRANCH="5.10"
VAR_QT_TAG="v5.10.1"
EOF
)

    local opts=$(cat <<EOF
-verbose
-release
-opengl es2
-make libs
-opensource
-confirm-license
-no-use-gold-linker
-fontconfig
EOF
)

    local temp_file="$PWD/scripts/common/tmp.sh"
    local path_vars="$PWD/scripts/common/variables.sh"
    local path_opts="$PWD/scripts/common/options.txt"

    if [[ ! "$reset_only" || "$reset_only" == "vars" ]]; then
        echo "$vars" > "$temp_file"
        head -c -1 "$temp_file" > "$path_vars"
        source "$path_vars"
        rm "$temp_file"
    fi

    if [[ ! "$reset_only" || "$reset_only" == "opts" ]]; then
        echo "$opts" > "$temp_file"
        head -c -1 "$temp_file" > "$path_opts"
        rm "$temp_file"
    fi

    reset::status "Successfully reset program variables to defaults"
}


function reset::all() {
    reset::build
    reset::device
    reset::config
}
