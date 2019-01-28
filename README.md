# qtrpi
Scripts for building and deploying Qt5 to RaspberryPi3

## Qt Setup:
First, it's a good idea to setup passwordless `ssh` with the device.
<br>This will prevent numerous repeated password prompts when running the build process.
<br>
<br>Use `ssh-keygen -t rsa` to generate the key, pressing enter when prompted for a passphrase.
<br>Use `ssh-copy-id -i ~/.ssh/id_rsa.pub host@address` to copy the id to the device.

```bash
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub pi@192.168.0.15
```
<br>

Now clone the repository:

```bash
git clone https://github.com/matt-blodgett/qtrpi.git
cd ./qtrpi
```
<br>

Configure shared script variables and change applicable defaults:

```bash
./qtrpi.py config --local-path "/opt/qtrpi"
./qtrpi.py config --target-host "pi@192.168.0.15"
```
<br>

Now you can simply run the build script:

```bash
./qtrpi.py build --install
```
<br>

If building QtBase fails try the following steps:
1. Use `git clean -dfx` in the qtbase module folder
2. Install any missing dependencies on the device
3. Tweak the `./configure` variables used
4. Retry the build

## Configuring QTCreator:
Source Reference: [wiki.qt.io/RasperryPi2EGLFS](https://wiki.qt.io/RaspberryPi2EGLFS)

Once qtbase is successfully built, use the following steps to configure QtCreator to build and deploy automatically to the device.
<br>

1. Go to `Options -> Devices`
2. Add `'Generic Linux Device'`
3. Enter IP address, user & password for the device
4. Go to `Options -> Compilers`
5. Add:
<br>'GCC', compiler path: 
<br>`../raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-g++`
6. Go to `Options -> Debuggers`
7. Add
<br>`../raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gdb`
8. Go to `Options -> Qt Versions`
9. Add the entry `~/raspi/qt5/bin/qmake`
10. Go to `Options -> Build & Run -> Kits`
11. Add:
<br>`Generic Linux Device`
<br>Device: the one we just created
<br>Sysroot: `../raspi/sysroot`
<br>Compiler: the one we just created
<br>Debugger: the one we just created
<br>Qt version: the one we saw under Qt Versions
<br>Qt mkspec: leave empty
