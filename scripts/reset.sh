#!/usr/bin/env bash


function reset::build() {
    sudo rm -rf "$LOCAL_PATH" $OPT_VERBOSE
}


function reset::device() {
    device::send_command "sudo rm -rf $TARGET_PATH $OPT_VERBOSE "
}


function reset::config() {
    local reset_only="$1"

    local vars=$(cat <<EOF
#!/usr/bin/env bash
LOCAL_PATH="/opt/qtrpi"
TARGET_PATH="/usr/local/qt5pi"
TARGET_HOST=""
TARGET_DEVICE="linux-rasp-pi3-g++"
QT_BRANCH="5.10"
QT_TAG="v5.10.1"
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
        rm "$temp_file"

        source "$path_vars"
    fi

    if [[ ! "$reset_only" || "$reset_only" == "opts" ]]; then
        echo "$opts" > "$temp_file"
        head -c -1 "$temp_file" > "$path_opts"
        rm "$temp_file"
    fi
}


function reset::all() {
    reset::build
    reset::device
    reset::config
}