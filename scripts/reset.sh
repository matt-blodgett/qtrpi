#!/usr/bin/env bash


function reset::build() {
    sudo rm -rfv "$LOCAL_PATH"
}


function reset::device() {
    device::send_command "sudo rm -rfv $TARGET_PATH"
}


function reset::config() {
    cat > "$PWD"/scripts/common/variables.sh <<EOF
#!/usr/bin/env bash
LOCAL_PATH="/opt/qtrpi"
TARGET_PATH="/usr/local/qt5pi"
TARGET_HOST=""
TARGET_DEVICE="linux-rasp-pi3-g++"
QT_BRANCH="5.10"
QT_TAG="v5.10.1"
EOF

    source "$PWD"/scripts/common/variables.sh
}


function reset::all() {
    reset::build
    reset::device
    reset::config
}