#!/usr/bin/env python3

import os
import sys


def handle_link(file_path, sub_dir, top_dir):
    link = os.readlink(file_path)

    if link[0] != '/' or link.startswith(top_dir):
        return

    rel_path = os.path.relpath(top_dir + link, sub_dir)
    print(f'Replacing {link} with {rel_path} for {file_path}')

    os.unlink(file_path)
    os.symlink(rel_path, file_path)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f'Usage is {sys.argv[0]} <directory>')
        sys.exit(1)

    top_dir = sys.argv[1]
    top_dir = os.path.abspath(top_dir)
    for sub_dir, dirs, files in os.walk(top_dir):
        for path in dirs + files:
            file_path = os.path.join(sub_dir, path)
            if os.path.islink(file_path):
                handle_link(file_path, sub_dir, top_dir)
