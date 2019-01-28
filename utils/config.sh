#!/usr/bin/env bash


function set_variable_line() {
    sed -i "$1s|.*|$2|" $PWD/utils/source/variables.sh
}


function set_local_path() {
    set_variable_line 3 "LOCAL_PATH=\"$1\""
}


function set_target_path() {
    set_variable_line 4 "TARGET_PATH=\"$1\""
}


function set_target_host() {
    set_variable_line 5 "TARGET_HOST=\"$1\""
}


function set_target_device() {
    set_variable_line 6 "TARGET_DEVICE=\"$1\""
}


function set_qt_branch() {
    set_variable_line 7 "QT_BRANCH=\"$1\""
}


function set_qt_tag() {
    set_variable_line 8 "QT_TAG=\"$1\""
}


function reset_config() {
    cat > $PWD/utils/source/variables.sh <<EOF
#!/usr/bin/env bash

LOCAL_PATH="/opt/qtrpi"
TARGET_PATH="/usr/local/qt5pi"
TARGET_HOST="pi@192.168.0.15"
TARGET_DEVICE="linux-rasp-pi3-g++"
QT_BRANCH="5.10"
QT_TAG="v5.10.1"
EOF
}