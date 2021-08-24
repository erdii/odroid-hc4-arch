#!/bin/bash
set -eo pipefail

if [[ -z "$1" ]]; then
    echo "usage: $0 <device>"
    exit 1
fi

set -u
DEVICE="$1"

if [[ ! -b "$DEVICE" ]]; then
    echo "$DEVICE is not a block device"
    exit 2
fi

set -x

parted --script "$DEVICE" \
    mklabel gpt \
    mkpart fat32 1MiB 500MiB \
    mkpart ext4 500MiB 100% \

partprobe "$DEVICE"

mkfs.vfat -n HC4BOOT "${DEVICE}1"
mkfs.ext4 -L HC4ROOT "${DEVICE}2"
