#!/usr/bin/env bash


function config::set_variable_line() {
    sed -i "$1s|.*|$2|" "$PWD/scripts/common/variables.sh"
}


function config::set_local_path() { config::set_variable_line 2 "VAR_LOCAL_PATH=\"$1\""; }
function config::set_target_path() { config::set_variable_line 3 "VAR_TARGET_PATH=\"$1\""; }
function config::set_target_host() { config::set_variable_line 4 "VAR_TARGET_HOST=\"$1\""; }
function config::set_target_device() { config::set_variable_line 5 "VAR_TARGET_DEVICE=\"$1\""; }
function config::set_qt_branch() { config::set_variable_line 6 "VAR_QT_BRANCH=\"$1\""; }
function config::set_qt_tag() { config::set_variable_line 7 "VAR_QT_TAG=\"$1\""; }