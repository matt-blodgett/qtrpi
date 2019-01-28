#!/usr/bin/env python3


import os
import sys
import argparse
import subprocess


USAGE = """usage: qtrpi.py [options]

qtrpi: scripts for building and deploying Qt to Raspberry Pi devices

optional flags:
  -h| --help              display help text
  -v| --verbose           display process output

command flags:

build                     build scripts
    | --install           install qtbase, build tools and create sysroot
    | --rebuild           rebuild qtbase and sync sysroot
    
config                    set configuration variables
    | --local-path        local build path for modules and sysroot
    | --target-path       target install path for built Qt libs
    | --target-host       device address <"host@address">
    | --target-device     target device flag for cross compiling
    | --qt-branch         Qt version branch
    | --qt-tag            Qt version tag

reset                     reset and clean
  -a| --all               reset both build and config
  -b| --build             reset qtrpi build process and clean
  -c| --config            reset all config variables to default

device                    device utils
 -sy| --sync-sysroot      sync sysroot directory
 -sf| --send-file         send file to device
 -sc| --send-command      send shell script to run on device
 -sa| --set-ssh-auth      set ssh key and add to known hosts

git: <https://github.com/matt-blodgett/qtrpi.git>"""


def run_shell(args, bash=True):
    process = subprocess.Popen(
        args if not bash else ['bash', '-c', args],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    while True:
        line = process.stdout.readline().decode('UTF-8')
        if line == '' and process.poll() is not None:
            break

        sys.stdout.write(line)
        sys.stdout.flush()

    process.wait()
    return process.returncode


def main():
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument('-h', '--help', dest='show_help', action='store_true')
    common.add_argument('-v', '--verbose', dest='show_verbose', action='store_true')

    parser = argparse.ArgumentParser(add_help=False, parents=[common])
    subparsers = parser.add_subparsers(dest='command')

    sub_parser = subparsers.add_parser('build', add_help=False, parents=[common])
    group = sub_parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--install', dest='install', action='store_true')
    group.add_argument('--rebuild', dest='rebuild', action='store_true')
    group.add_argument('--module', dest='module', action='store_true')

    sub_parser = subparsers.add_parser('config', add_help=False, parents=[common])
    sub_parser.add_argument('--local-path', dest='local_path', type=str)
    sub_parser.add_argument('--target-path', dest='target_path', type=str)
    sub_parser.add_argument('--target-host', dest='target_host', type=str)
    sub_parser.add_argument('--target-device', dest='target_device', type=str)
    sub_parser.add_argument('--qt-branch', dest='qt_branch', type=str)
    sub_parser.add_argument('--qt-tag', dest='qt_tag', type=str)

    sub_parser = subparsers.add_parser('reset', add_help=False, parents=[common])
    sub_parser.add_argument('-a', '--all', dest='reset_all', action='store_true')
    sub_parser.add_argument('-b', '--build', dest='reset_build', action='store_true')
    sub_parser.add_argument('-c', '--config', dest='reset_config', action='store_true')

    sub_parser = subparsers.add_parser('device', add_help=False, parents=[common])
    group = sub_parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-sy', '--sync-sysroot', dest='sync_sysroot', action='store_true')
    group.add_argument('-sf', '--send-file', dest='send_file', type=str, nargs=2)
    group.add_argument('-sc', '--send-command', dest='send_command', type=str)
    group.add_argument('-sa', '--set-ssh-auth', dest='set_ssh_auth', action='store_true')

    args = parser.parse_args()
    # print(vars(args))

    if args.show_help:
        print(USAGE)

    elif args.command == 'build':
        cwd = os.path.abspath(os.getcwd())
        sh_functions = '. ./utils/build.sh; '
        sh_functions += ' . ./utils/device.sh; '

        if args.rebuild:
            sh_functions += '; '.join([
                'sync_sysroot',
                'clean_module "qtbase"',
                'build_qtbase',
                f'cd {cwd}',
                'sync_sysroot'
            ])

        else:
            sh_functions += '; '.join([
                'init_local',
                'init_device',
                'sync_sysroot',
                'build_qtbase',
                f'cd {cwd}',
                'install_device',
                'sync_sysroot'
            ])

        run_shell(sh_functions)

    elif args.command == 'config':
        sh_functions = '. ./utils/config.sh; '

        attribs = [
            'local_path',
            'target_path',
            'target_host',
            'target_device',
            'qt_branch',
            'qt_tag'
        ]

        for key in attribs:
            value = getattr(args, key)

            if value:
                sh_functions += f'set_{key} "{value}"; '

        run_shell(sh_functions)

    elif args.command == 'reset':
        sh_functions = ''

        if args.reset_config or args.reset_all:
            sh_functions += '. ./utils/config.sh; reset_config; '

        if args.reset_build or args.reset_all:
            sh_functions += '. ./utils/build.sh; reset_build; '

        run_shell(sh_functions)

    elif args.command == 'device':
        sh_functions = '. ./utils/device.sh; '

        if args.sync_sysroot:
            sh_functions += 'sync_sysroot; '

        elif args.send_file:
            fr_file, to_file = args.send_file
            sh_functions += f'send_file "{fr_file}" "{to_file}"; '

        elif args.send_command:
            sh_functions += f'send_command "{args.send_command}"; '

        elif args.set_ssh_auth:
            sh_functions += 'set_ssh_auth; '

        run_shell(sh_functions)


if __name__ == '__main__':
    main()
