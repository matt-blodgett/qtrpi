#!/usr/bin/env bash


function config::set_variable_line() {
    sed -i "$1s|.*|$2|" "$PWD/scripts/common/variables.sh"
}


function config::set_local_path() { config::set_variable_line 2 "LOCAL_PATH=\"$1\""; }
function config::set_target_path() { config::set_variable_line 3 "TARGET_PATH=\"$1\""; }
function config::set_target_host() { config::set_variable_line 4 "TARGET_HOST=\"$1\""; }
function config::set_target_device() { config::set_variable_line 5 "TARGET_DEVICE=\"$1\""; }
function config::set_qt_branch() { config::set_variable_line 6 "QT_BRANCH=\"$1\""; }
function config::set_qt_tag() { config::set_variable_line 7 "QT_TAG=\"$1\""; }