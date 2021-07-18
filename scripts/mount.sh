#!/bin/bash
set -eo pipefail

if [[ -z "$1" ]]; then
    echo "usage: $0 <device> [parent=.cache/mnt]"
    exit 1
fi

PARENT="${2:-$PWD/.cache/mnt}"

set -u
DEVICE="$1"

if [[ ! -b "$DEVICE" ]]; then
    echo "$DEVICE is not a block device"
    exit 2
fi

if [[ ! -b "${DEVICE}1" ]]; then
    echo "${DEVICE}1 is not a block device"
    exit 2
fi

if [[ ! -b "${DEVICE}2" ]]; then
    echo "${DEVICE}2 is not a block device"
    exit 2
fi

mkdir -p "$PARENT/"{boot,root}

set -x

mount "${DEVICE}1" "$PARENT/boot"
mount "${DEVICE}2" "$PARENT/root"
