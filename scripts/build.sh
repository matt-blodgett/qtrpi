#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_DIR"/common/variables.sh
source "$SCRIPT_DIR"/device.sh


function build::init_local() {
    sudo mkdir -v "$LOCAL_PATH"
    sudo chown -v "$(whoami)":"$(whoami)" "$LOCAL_PATH" --recursive

    mkdir -v "$LOCAL_PATH/logs"
    mkdir -v "$LOCAL_PATH/modules"

    mkdir -v "$LOCAL_PATH/raspi"
    mkdir -v "$LOCAL_PATH/raspi/sysroot"
    mkdir -v "$LOCAL_PATH/raspi/sysroot/usr"
    mkdir -v "$LOCAL_PATH/raspi/sysroot/opt"

    git clone -v "https://github.com/raspberrypi/tools.git" "$LOCAL_PATH/raspi/tools"
}


function build::init_device() {
    device::send_script "$SCRIPT_DIR/deploy/init-deps.sh"
    local pi_usr=$(cut -d"@" -f1 <<<"$TARGET_HOST")
    device::send_command "sudo mkdir -v $TARGET_PATH && sudo chown -v $pi_usr:$pi_usr $TARGET_PATH --recursive"
}


function build::install_device() {
    device::send_script "$SCRIPT_DIR/deploy/fix-mesa-libs.sh"
    local conf_path="/etc/ld.so.conf.d/00-qt5pi.conf"
    device::send_command "echo $TARGET_PATH/lib | sudo tee $conf_path && sudo ldconfig -v"
}


function build::qmake() {
    local log_file="${1:-default}"
    "$LOCAL_PATH"/raspi/qt5/bin/qmake -r |& tee "$LOCAL_PATH/logs/$log_file.log"
}


function build::make() {
    local log_file="${1:-default}"
    make -j 10 |& tee --append "$LOCAL_PATH/logs/$log_file.log"
    make install
}


function build::clean_module() {
    local qt_module="$1"
    local cwd="$PWD"

    cd "$LOCAL_PATH/modules/$qt_module"
    git clean -dfx

    cd "$cwd"
}


function build::build_qtbase() {
    local cwd="$PWD"
    local qt_module="qtbase"

    local extprefix="$LOCAL_PATH/raspi/qt5pi"
    local hostprefix="$LOCAL_PATH/raspi/qt5"
    local sysroot="$LOCAL_PATH/raspi/sysroot"
    local cross_compile="$LOCAL_PATH/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-"

    git clone -v "git://code.qt.io/qt/$qt_module.git" "$LOCAL_PATH/modules/$qt_module" -b "$QT_BRANCH"
    cd "$LOCAL_PATH/modules/$qt_module"
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

    local opts_array=()
    local opts_path="$SCRIPT_DIR/common/opts_qtbase.txt"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        opts_array+=( "$line" )
    done < "$opts_path"

    opts_array+=( "-sysroot $sysroot" )
    opts_array+=( "-extprefix $extprefix" )
    opts_array+=( "-hostprefix $hostprefix" )
    opts_array+=( "-prefix $TARGET_PATH" )
    opts_array+=( "-device $TARGET_DEVICE" )
    opts_array+=( "-device-option CROSS_COMPILE=$cross_compile" )

    IFS=' ' read -a opts <<<"${opts_array[@]}"
    opts_array=( "${opts[@]}" )

     ./configure "${opts_array[@]}" |& tee "$LOCAL_PATH/logs/$qt_module.log"

    build::make "$qt_module"
    cd "$cwd"
}


function build::build_qtmodule() {
    local qt_module="$1"
    local cwd="$PWD"

    git clone -v "git://code.qt.io/qt/$qt_module.git" "$LOCAL_PATH/modules/$qt_module" -b "$QT_BRANCH"
    cd "$LOCAL_PATH/modules/$qt_module"
    git checkout "tags/$QT_TAG"

    build::qmake "$qt_module"
    build::make "$qt_module"

    cd "$cwd"
}