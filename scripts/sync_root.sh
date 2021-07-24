#!/bin/bash
set -eo pipefail

if [[ -z "$1" || -z "$2" ]]; then
    echo "usage: $0 <source> <parent-dest>"
    exit 1
fi

set -u
SOURCE="$1"
TARGET="$2"

if [[ ! -d "$SOURCE" ]]; then
    echo "$SOURCE is not a folder"
    exit 2
fi

if [[ ! -d "$TARGET" ]]; then
    echo "$TARGET is not a folder"
    exit 3
fi

set +e
mountpoint "$TARGET/root" > /dev/null
if [[ "$?" != "0" ]]; then
    echo "$TARGET/root is not a mountpoint"
    exit 4
fi
mountpoint "$TARGET/boot" > /dev/null
if [[ "$?" != "0" ]]; then
    echo "$TARGET/boot is not a mountpoint"
    exit 4
fi

set -ex

rsync -a "$SOURCE/" "$TARGET/root/"
rm -rf $TARGET/boot/*
mv $TARGET/root/boot/* "$TARGET/boot/"
sync
