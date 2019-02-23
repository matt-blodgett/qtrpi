#!/usr/bin/env bash


function build::status() { msgs::status "${MSGS_PREFIX[build]} $1"; }
function build::verbose() { msgs::verbose "${MSGS_PREFIX[build]} $1"; }


function build::init_local() {
    build::status "Setting up local files"

    build::verbose "Creating local build directory"
    sudo mkdir "$VAR_LOCAL_PATH" $OPT_VERBOSE
    sudo chown "$(whoami)":"$(whoami)" "$VAR_LOCAL_PATH" --recursive $OPT_VERBOSE

    local local_dirs=()
    local_dirs+=( "$VAR_LOCAL_PATH/logs" )
    local_dirs+=( "$VAR_LOCAL_PATH/modules" )
    local_dirs+=( "$VAR_LOCAL_PATH/raspi" )
    local_dirs+=( "$VAR_LOCAL_PATH/raspi/sysroot" )
    local_dirs+=( "$VAR_LOCAL_PATH/raspi/sysroot/usr" )
    local_dirs+=( "$VAR_LOCAL_PATH/raspi/sysroot/opt" )

    mkdir "${local_dirs[@]}" $OPT_VERBOSE

    local git_url="https://github.com/raspberrypi/tools.git"
    local git_path="$VAR_LOCAL_PATH/raspi/tools"

    build::verbose "Cloning raspberrypi build toolchain from '$git_url' into '$git_path'"
    git clone "$git_url" "$git_path" $OPT_VERBOSE

    build::status "Successfully set up local files"
}


function build::init_device() {
    build::status "Setting up remote files"

    build::verbose "Installing device dependencies"
    local pi_script="$PWD/scripts/deploy/init-deps.sh"
    device::send_script "$pi_script"

    build::verbose "Creating remote target path '$VAR_TARGET_PATH'"
    local pi_usr=$(cut -d"@" -f1 <<<"$VAR_TARGET_HOST")
    local pi_command=""
    pi_command+="sudo mkdir -p $VAR_TARGET_PATH $OPT_VERBOSE "
    pi_command+="&& sudo chown $pi_usr:$pi_usr $VAR_TARGET_PATH $OPT_VERBOSE"
    device::send_command "$pi_command"

    build::status "Successfully set up remote files"
}


function build::install_device() {
    build::status "Registering Qt libs"

    build::verbose "Fixing mesa lib links"
    local pi_script="$PWD/scripts/deploy/fix-mesa-libs.sh"
    device::send_script "$pi_script"

    build::verbose "Adding ld conf and running ldconfig"
    local conf_path="/etc/ld.so.conf.d/00-qt5pi.conf"
    local pi_command=""
    pi_command+="echo $VAR_TARGET_PATH/lib | sudo tee $conf_path "
    pi_command+="&& sudo ldconfig $OPT_VERBOSE"
    device::send_command "$pi_command"

    build::status "Successfully set up remote libs"
}


function build::qmake() {
    local log_file="$VAR_LOCAL_PATH/logs/${1:-default}.log"

    build::verbose "Running qmake > logfile='$log_file'"
    "$VAR_LOCAL_PATH"/raspi/qt5/bin/qmake -r |& tee "$VAR_LOCAL_PATH/logs/$log_file.log"
    msgs::check_exit_code "$?"
    build::verbose "Successfully ran qmake > logfile='$log_file'"
}


function build::make() {
    local log_file="$VAR_LOCAL_PATH/logs/${1:-default}.log"

    build::verbose "Running make > logfile='$log_file'"
    make -j 10 |& tee --append "$VAR_LOCAL_PATH/logs/$log_file.log"
    make install
    msgs::check_exit_code "$?"
    build::verbose "Successfully ran make > logfile='$log_file'"
}


function build::clean_module() {
    local cwd="$PWD"
    local qt_module="$1"
    local qt_module_path="$VAR_LOCAL_PATH/modules/$qt_module"

    build::status "Cleaning module '$qt_module'"

    build::verbose "Entering '$qt_module_path'"
    cd "$VAR_LOCAL_PATH/modules/$qt_module"

    build::verbose "Resetting module '$qt_module'"
    git clean -dfx
    msgs::check_exit_code "$?"

    build::verbose "Leaving '$qt_module_path'"
    cd "$cwd"

    build::status "Successfully cleaned '$qt_module'"
}


function build::build_qtbase() {
    build::status "Building 'qtbase'"

    local cwd="$PWD"
    local qt_module="qtbase"
    local qt_module_path="$VAR_LOCAL_PATH/modules/$qt_module"
    local git_url="git://code.qt.io/qt/$qt_module.git"

    local extprefix="$VAR_LOCAL_PATH/raspi/qt5pi"
    local hostprefix="$VAR_LOCAL_PATH/raspi/qt5"
    local sysroot="$VAR_LOCAL_PATH/raspi/sysroot"

    local cross_compile="$VAR_LOCAL_PATH"
    cross_compile+="/raspi/tools/arm-bcm2708"
    cross_compile+="/gcc-linaro-arm-linux-gnueabihf-raspbian-x64"
    cross_compile+="/bin/arm-linux-gnueabihf-"

    build::verbose "Cloning $qt_module from '$git_url' into '$qt_module_path'"
    git clone "$git_url" "$qt_module_path" -b "$VAR_QT_BRANCH" $OPT_VERBOSE

    build::verbose "Entering '$qt_module_path'"
    cd "$qt_module_path"

    build::verbose "Checking out 'tags/$VAR_QT_TAG'"
    git checkout "tags/$VAR_QT_TAG"
    msgs::check_exit_code "$?"

    build::verbose "Adding missing INCLUDEPATH in qmake conf"
    local qmake_file="mkspecs/devices/$VAR_TARGET_DEVICE/qmake.conf"
    grep -q "INCLUDEPATH" "$qmake_file" || cat>>"$qmake_file" << EOL
INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include
INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vcos
INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vcos/pthreads
INCLUDEPATH += \$\$[QT_SYSROOT]/opt/vc/include/interface/vmcs_host/linux
EOL

    build::verbose "Adding QMAKE_CFLAGS to qmake conf"
    sed -i "s/\$\$QMAKE_CFLAGS -std=c++1z/\$\$QMAKE_CFLAGS -std=c++11/g" "$qmake_file"

    local opts_array=()
    local opts_path="$cwd/scripts/common/options.txt"
    while IFS='' read -r line || [[ -n "$line" ]]; do
        opts_array+=( "$line" )
    done < "$opts_path"

    opts_array+=( "-sysroot $sysroot" )
    opts_array+=( "-extprefix $extprefix" )
    opts_array+=( "-hostprefix $hostprefix" )
    opts_array+=( "-prefix $VAR_TARGET_PATH" )
    opts_array+=( "-device $VAR_TARGET_DEVICE" )
    opts_array+=( "-device-option CROSS_COMPILE=$cross_compile" )

    IFS=' ' read -a opts <<<"${opts_array[@]}"
    opts_array=( "${opts[@]}" )

    build::verbose "Running configure script for '$qt_module'"
     ./configure "${opts_array[@]}" |& tee "$VAR_LOCAL_PATH/logs/$qt_module.log"
    msgs::check_exit_code "$?"

    build::make "$qt_module"

    build::verbose "Leaving '$qt_module_path'"
    cd "$cwd"

    build::status "Successfully built 'qtbase'"
}


function build::build_qtmodule() {
    local cwd="$PWD"
    local qt_module="$1"
    local qt_module_path="$VAR_LOCAL_PATH/modules/$qt_module"
    local git_url="git://code.qt.io/qt/$qt_module.git"

    build::status "Building Qt module '$qt_module'"

    build::verbose "Cloning $qt_module from '$git_url' into '$qt_module_path'"
    git clone "$git_url" "$qt_module_path" -b "$VAR_QT_BRANCH" $OPT_VERBOSE
    msgs::check_exit_code "$?"

    build::verbose "Entering '$qt_module_path'"
    cd "$qt_module_path"

    build::verbose "Checking out 'tags/$VAR_QT_TAG'"
    git checkout "tags/$VAR_QT_TAG"
    msgs::check_exit_code "$?"

    build::qmake "$qt_module"
    build::make "$qt_module"

    build::verbose "Leaving '$qt_module_path'"
    cd "$cwd"

    build::status "Successfully built Qt module '$qt_module'"
}
