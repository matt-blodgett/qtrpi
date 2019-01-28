#!/usr/bin/env bash


readonly USR_LIB_ARM="/usr/lib/arm-linux-gnueabihf"
readonly OPT_VC_LIB="/opt/vc/lib"


sudo mv "$USR_LIB_ARM/libEGL.so.1.0.0" "$USR_LIB_ARM/libEGL.so.1.0.0_backup"
sudo mv "$USR_LIB_ARM/libGLESv2.so.2.0.0" "$USR_LIB_ARM/libGLESv2.so.2.0.0_backup"

sudo ln -sf "$OPT_VC_LIB/libbrcmEGL.so" "$OPT_VC_LIB/libEGL.so"
sudo ls -sf "$OPT_VC_LIB/libbrcmGLESv2.so" "$OPT_VC_LIB/libGLESv2.so"

sudo ln -sf "$OPT_VC_LIB/libGLESv2.so" "$USR_LIB_ARM/libGLESv2.so"
sudo ln -sf "$OPT_VC_LIB/libGLESv2.so" "$USR_LIB_ARM/libGLESv2.so.2"
sudo ln -sf "$OPT_VC_LIB/libGLESv2.so" "$USR_LIB_ARM/libGLESv2.so.2.0"
sudo ln -sf "$OPT_VC_LIB/libGLESv2.so" "$USR_LIB_ARM/libGLESv2.so.2.0.0"

sudo ln -sf "$OPT_VC_LIB/libEGL.so" "$USR_LIB_ARM/libEGL.so"
sudo ln -sf "$OPT_VC_LIB/libEGL.so" "$USR_LIB_ARM/libEGL.so.1"
sudo ln -sf "$OPT_VC_LIB/libEGL.so" "$USR_LIB_ARM/libEGL.so.1.0"
sudo ln -sf "$OPT_VC_LIB/libEGL.so" "$USR_LIB_ARM/libEGL.so.1.0.0"
