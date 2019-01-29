#!/usr/bin/env bash


source $PWD/utils/source/variables.sh


function init_local() {
    sudo mkdir "$LOCAL_PATH"
    sudo chown "$(whoami)":"$(whoami)" "$LOCAL_PATH" --recursive

    mkdir "$LOCAL_PATH/logs"
    mkdir "$LOCAL_PATH/modules"

    mkdir "$LOCAL_PATH/raspi"
    mkdir "$LOCAL_PATH/raspi/sysroot"
    mkdir "$LOCAL_PATH/raspi/sysroot/usr"
    mkdir "$LOCAL_PATH/raspi/sysroot/opt"

    git clone "https://github.com/raspberrypi/tools.git" "$LOCAL_PATH/raspi/tools"
}


function init_device() {
    source $PWD/utils/device.sh
    send_command "$PWD/utils/device/init-deps.sh"

    local pi_usr=$(cut -d"@" -f1 <<<"$TARGET_HOST")
    ssh "$TARGET_HOST" "sudo mkdir $TARGET_PATH && sudo chown $pi_usr:$pi_usr $TARGET_PATH --recursive"
}


function install_device() {
    source $PWD/utils/device.sh
    send_command "$PWD/utils/device/fix-mesa-libs.sh"

    local conf_path="/etc/ld.so.conf.d/00-qt5pi.conf"
    ssh "$TARGET_HOST" "echo $TARGET_PATH/lib | sudo tee $conf_path && sudo ldconfig"
}


function cmd_qmake() {
    local log_file="${1:-default}"
    "$LOCAL_PATH"/raspi/qt5/bin/qmake -r |& tee "$LOCAL_PATH/logs/$log_file.log"
}


function cmd_make() {
    local log_file="${1:-default}"
    make -j 10 |& tee --append "$LOCAL_PATH/logs/$log_file.log"
    make install
}


function clean_module() {
    cd "$LOCAL_PATH/modules/$1"
    git clean -dfx
}


function build_qtbase() {
    export CROSS_COMPILE="$LOCAL_PATH/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-"
    export SYSROOT="$LOCAL_PATH/raspi/sysroot"

    local qt_module="qtbase"
    local output_dir="$LOCAL_PATH/raspi/qt5pi"
    local output_host_dir="$LOCAL_PATH/raspi/qt5"

    git clone "git://code.qt.io/qt/$qt_module.git" "$LOCAL_PATH/modules/$qt_module" -b "$QT_BRANCH"
    cd  "$LOCAL_PATH/modules/$qt_module"
    git checkout "tags/$QT_TAG"
    local qmake_file="mkspecs/devices/$TARGET_DEVICE/qmake.conf"

    # Add missing INCLUDEPATH in qmake conf
    grep -q "INCLUDEPATH" "$qmake_file" || cat>>"$qmake_file" << EOL
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vcos
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vcos/pthreads
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vmcs_host/linux
EOL

    sed -i "s/\$\$QMAKE_CFLAGS -std=c++1z/\$\$QMAKE_CFLAGS -std=c++11/g" "$qmake_file"

    ./configure \
        -release \
        -opengl es2 \
        -device "$TARGET_DEVICE" \
        -device-option CROSS_COMPILE="$CROSS_COMPILE" \
        -sysroot "$SYSROOT" \
        -opensource \
        -confirm-license \
        -make libs \
        -prefix "$TARGET_PATH" \
        -extprefix "$output_dir" \
        -hostprefix "$output_host_dir" \
        -no-use-gold-linker \
        -fontconfig \
        |& tee "$LOCAL_PATH/logs/$qt_module.log"

    cmd_make "$qt_module"
}


function build_qtmodule() {
    local qt_module="$1"

    git clone "git://code.qt.io/qt/$qt_module.git" "$LOCAL_PATH/modules/$qt_module" -b "$QT_BRANCH"
    cd  "$LOCAL_PATH/modules/$qt_module"
    git checkout "tags/$QT_TAG"

    cmd_qmake "$qt_module"
    cmd_make "$qt_module"
}


function reset_build() {
    echo "resetting build"
}