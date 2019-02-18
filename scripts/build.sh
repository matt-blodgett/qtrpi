#!/usr/bin/env bash


function build::init_local() {
    sudo mkdir "$LOCAL_PATH" $OPT_VERBOSE
    sudo chown "$(whoami)":"$(whoami)" "$LOCAL_PATH" --recursive $OPT_VERBOSE

    local local_dirs=()
    local_dirs+=( "$LOCAL_PATH/logs" )
    local_dirs+=( "$LOCAL_PATH/modules" )
    local_dirs+=( "$LOCAL_PATH/raspi" )
    local_dirs+=( "$LOCAL_PATH/raspi/sysroot" )
    local_dirs+=( "$LOCAL_PATH/raspi/sysroot/usr" )
    local_dirs+=( "$LOCAL_PATH/raspi/sysroot/opt" )

    mkdir "${local_dirs[@]}" $OPT_VERBOSE

    git clone "https://github.com/raspberrypi/tools.git" "$LOCAL_PATH/raspi/tools" $OPT_VERBOSE
}


function build::init_device() {
    local pi_script="$PWD/scripts/deploy/init-deps.sh"
    local pi_usr=$(cut -d"@" -f1 <<<"$TARGET_HOST")

    local pi_command=""
    pi_command+="sudo mkdir $TARGET_PATH $OPT_VERBOSE "
    pi_command+="&& sudo chown $pi_usr:$pi_usr $TARGET_PATH $OPT_VERBOSE"

    device::send_script "$pi_script"
    device::send_command "$pi_command"
}


function build::install_device() {
    local pi_script="$PWD/scripts/deploy/fix-mesa-libs.sh"
    local conf_path="/etc/ld.so.conf.d/00-qt5pi.conf"

    local pi_command=""
    pi_command+="echo $TARGET_PATH/lib | sudo tee $conf_path "
    pi_command+="&& sudo ldconfig $OPT_VERBOSE"

    device::send_script "$pi_script"
    device::send_command "$pi_command"
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
    git clean -dfx $OPT_VERBOSE

    cd "$cwd"
}


function build::build_qtbase() {
    local cwd="$PWD"
    local qt_module="qtbase"
    local qt_module_path="$LOCAL_PATH/modules/$qt_module"

    local extprefix="$LOCAL_PATH/raspi/qt5pi"
    local hostprefix="$LOCAL_PATH/raspi/qt5"
    local sysroot="$LOCAL_PATH/raspi/sysroot"

    local cross_compile="$LOCAL_PATH"
    cross_compile+="/raspi/tools/arm-bcm2708"
    cross_compile+="/gcc-arm-linux-gnueabihf-raspbian-x64"
    cross_compile+="/bin/arm-linux-gnueabihf-"

    git clone "git://code.qt.io/qt/$qt_module.git" "$qt_module_path" -b "$QT_BRANCH" $OPT_VERBOSE
    cd "$qt_module_path"
    git checkout "tags/$QT_TAG"

    # Add missing INCLUDEPATH in qmake conf
    local qmake_file="mkspecs/devices/$TARGET_DEVICE/qmake.conf"
    grep -q "INCLUDEPATH" "$qmake_file" || cat>>"$qmake_file" << EOL
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vcos
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vcos/pthreads
    INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vmcs_host/linux
EOL

    sed -i "s/\$\$QMAKE_CFLAGS -std=c++1z/\$\$QMAKE_CFLAGS -std=c++11/g" "$qmake_file"

    local opts_array=()
    local opts_path="$cwd/scripts/common/options.txt"
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
    local cwd="$PWD"
    local qt_module="$1"
    local qt_module_path="$LOCAL_PATH/modules/$qt_module"

    git clone "git://code.qt.io/qt/$qt_module.git" "$qt_module_path" -b "$QT_BRANCH" $OPT_VERBOSE
    cd "$qt_module_path"
    git checkout "tags/$QT_TAG"

    build::qmake "$qt_module"
    build::make "$qt_module"

    cd "$cwd"
}