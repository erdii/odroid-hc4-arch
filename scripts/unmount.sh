#!/bin/bash
set -x

PARENT="${1:-$PWD/.cache/mnt}"

mountpoint "$PARENT/root" > /dev/null && umount "$PARENT/root"
mountpoint "$PARENT/boot" > /dev/null && umount "$PARENT/boot"
