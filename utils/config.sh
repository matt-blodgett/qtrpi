#!/usr/bin/env bash


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


function set_variable_line() {
    sed -i "$1s|.*|$2|" "$SCRIPT_DIR"/source/variables.sh
}


function set_local_path() { set_variable_line 3 "LOCAL_PATH=\"$1\""; }
function set_target_path() { set_variable_line 4 "TARGET_PATH=\"$1\""; }
function set_target_host() { set_variable_line 5 "TARGET_HOST=\"$1\""; }
function set_target_device() { set_variable_line 6 "TARGET_DEVICE=\"$1\""; }
function set_qt_branch() { set_variable_line 7 "QT_BRANCH=\"$1\""; }
function set_qt_tag() { set_variable_line 8 "QT_TAG=\"$1\""; }