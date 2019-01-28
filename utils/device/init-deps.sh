#!/usr/bin/env bash

sudo sed -i "3s|.*|deb-src http://raspbian.raspberrypi.org/raspbian/ stretch main contrib non-free rpi|" /etc/apt/sources.list

sudo apt-get update
sudo apt-get upgrade

sudo apt-get build-dep qt4-x11
sudo apt-get build-dep libqt5gui5
sudo apt-get autoremove

sudo apt-get install -y libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0
sudo apt-get autoremove

sudo apt-get install -y libx11-dev libfontconfig1-dev
sudo apt-get autoremove

sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove

#sudo apt-get purge wolfram-engine
#sudo apt-get autoremove
