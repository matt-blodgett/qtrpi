#!/usr/bin/env bash

sudo sed -i "3s|.*|deb-src http://raspbian.raspberrypi.org/raspbian/ stretch main contrib non-free rpi|" "/etc/apt/sources.list"
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoremove -y
sudo apt-get build-dep -y qt4-x11 && sudo apt-get build-dep -y libqt5gui5
sudo apt-get install -y libgles2-mesa-dev libx11-dev libfontconfig1-dev
sudo apt-get install -y libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0
