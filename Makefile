SHELL=/bin/bash
.SHELLFLAGS=-euo pipefail -c

MIRROR := http://de5.mirror.archlinuxarm.org

arch_image := ArchLinuxARM-aarch64-latest.tar.gz

.cache:
	mkdir -p ".cache"
.cache/tmp:
	mkdir -p ".cache/tmp"

# why is this executing every time?
# TODO fix and add as dependency where needed
arch-image: .cache/$(arch_image)
.cache/$(arch_image): .cache .cache/tmp
	curl -o ".cache/tmp/$(arch_image)" $(MIRROR)/os/ArchLinuxARM-aarch64-latest.tar.gz
	curl -o ".cache/tmp/$(arch_image).sig" $(MIRROR)/os/ArchLinuxARM-aarch64-latest.tar.gz.sig
	# import archlinux arm build pgp key:
	# gpg --keyserver keyserver.ubuntu.com --recv-keys 68B3537F39A313B3E574D06777193F152BDBE6A6
	gpg --verify ".cache/tmp/$(arch_image).sig"
	mv ".cache/tmp/$(arch_image)" ".cache/$(arch_image)"

.cache/root: .cache # .cache/$(arch_image)
	sudo mkdir ".cache/root"
	sudo su -c 'bsdtar -xpf ".cache/$(arch_image)" -C ".cache/root"'

merge:
	sudo rsync -a --no-o --no-g "root/" ".cache/root/"

export LC_ALL := POSIX
setup: # | .cache/root merge
	mountpoint ".cache/root" > /dev/null || sudo mount --bind ".cache/root" ".cache/root"
	# sudo arch-chroot ".cache/root" ls -la /
	sudo arch-chroot ".cache/root" pacman-key --init
	sudo arch-chroot ".cache/root" pacman-key --populate archlinuxarm
	sudo arch-chroot ".cache/root" /bin/bash -c 'pacman -Q linux-aarch64; if [[ $$? == 0 ]]; then pacman -Rs linux-aarch64 --noconfirm; else true; fi'
	sudo arch-chroot ".cache/root" pacman -Syu --noconfirm
	sudo arch-chroot ".cache/root" pacman -S uboot-tools linux-aarch64-rc --noconfirm
	sudo arch-chroot ".cache/root" pacman -S sudo man-db base-devel --noconfirm
	sudo umount -R ".cache/root"

clean:
	sudo umount -R ".cache/root" || true
	[[ ! -e ".cache/root" ]] || sudo rm -rf ".cache/root"
