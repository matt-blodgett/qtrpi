# qtrpi
##### Scripts for building and deploying Qt5 to RaspberryPi devices

## Setup:
##### Clone the repository:

```bash
git clone https://github.com/matt-blodgett/qtrpi.git
cd ./qtrpi
```

<br>

---

##### Configure shared script variables and change applicable defaults:
Of particular importance is setting the `--target-host` variable as it is empty by default.

```bash
./qtrpi.sh config --local-path "/opt/qtrpi"
./qtrpi.sh config --target-host "pi@192.168.0.15"
```

<br>

---

##### Setup passwordless `ssh` with the target device:
This will prevent numerous repeated password prompts when running the build process.
<br>The setup is made simple with the `--set-ssh-auth` option:
<br>Simply follow the prompts and you should be able to `ssh` to the device unprompted.

```bash
./qtrpi.sh device --set-ssh-auth
```

<br>

---

##### Run the build script:

```bash
./qtrpi.sh build --install
```

<br>

---

##### Troubleshooting:

The build process has a few distinct steps:
1. Creates a local repository where the RaspberryPi build toolchain and built Qt modules will be located
2. Installs dependencies on the target device.
3. Creates a sysroot and uses `rsync` to keep it up to date with new modules and dependencies.
4. Builds QtBase using the cross compiling toolchain from https://github.com/raspberrypi/tools.git
5. Updates and configures the device with the new libs and fixes known issues with the process.

---

If building QtBase fails try the following steps:
1. Install any missing dependencies on the device
2. Make sure `rpi-update` has been run on the device
3. Tweak the `./configure` variables used
4. Retry the build with `./qtrpi.sh build --rebuild`

## Configuring QtCreator:
##### Source Reference: [wiki.qt.io/RasperryPi2EGLFS](https://wiki.qt.io/RaspberryPi2EGLFS)

Once qtbase is successfully built, use the following steps to configure QtCreator to build and deploy automatically to the device.
<br>

1. Go to `Options -> Devices` and add:
    ```
    Generic Linux Device:
    Enter IP address, user & password for the device
    ```
2. Go to `Options -> Compilers` and add:
    ```
    'GCC', compiler path: 
    ../raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-g++
    ```
3. Go to `Options -> Debuggers` and add:
    ```
    ../raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gdb
    ```
4. Go to `Options -> Qt Versions` and add:
    ```
    ~/raspi/qt5/bin/qmake`
    ```
5. Go to `Options -> Build & Run -> Kits` and add:
    ```
    Generic Linux Device
    Device: the one just created
    Sysroot: ../raspi/sysroot
    Compiler: the one just created
    Debugger: the one just created
    Qt version: the one seen under Qt Versions
    Qt mkspec: leave empty
    ```
