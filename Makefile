SHELL=/bin/bash
.SHELLFLAGS=-euo pipefail -c

MIRROR := http://de5.mirror.archlinuxarm.org

.cache/ArchLinuxARM-aarch64-latest.tar.gz:
	mkdir -p ".cache/tmp"
	curl -o ".cache/tmp/ArchLinuxARM-aarch64-latest.tar.gz" $(MIRROR)/os/ArchLinuxARM-aarch64-latest.tar.gz
	curl -o ".cache/tmp/ArchLinuxARM-aarch64-latest.tar.gz.sig" $(MIRROR)/os/ArchLinuxARM-aarch64-latest.tar.gz.sig
	# import archlinux arm build pgp key:
	# gpg --keyserver keyserver.ubuntu.com --recv-keys 68B3537F39A313B3E574D06777193F152BDBE6A6
	gpg --verify ".cache/tmp/ArchLinuxARM-aarch64-latest.tar.gz.sig"
	# how to specifically check if `68B3537F39A313B3E574D06777193F152BDBE6A6` signed?
	mv ".cache/tmp/ArchLinuxARM-aarch64-latest.tar.gz" ".cache/ArchLinuxARM-aarch64-latest.tar.gz"

# this target re-executes every time... why?
.cache/root: .cache/ArchLinuxARM-aarch64-latest.tar.gz
	sudo mkdir -p ".cache/root"
	sudo su -c 'bsdtar -xpf ".cache/ArchLinuxARM-aarch64-latest.tar.gz" -C ".cache/root"'
	sudo rsync -a --no-o --no-g "root/" ".cache/root/"

export LC_ALL := POSIX
setup: .cache/root
	mountpoint ".cache/root" > /dev/null || sudo mount --bind ".cache/root" ".cache/root"
	sudo arch-chroot ".cache/root" pacman-key --init
	sudo arch-chroot ".cache/root" pacman-key --populate archlinuxarm
	sudo arch-chroot ".cache/root" /bin/bash -c 'pacman -Q linux-aarch64; if [[ $$? == 0 ]]; then pacman -Rs linux-aarch64 --noconfirm; else true; fi'
	sudo arch-chroot ".cache/root" pacman -Syu --noconfirm
	sudo arch-chroot ".cache/root" pacman -S uboot-tools linux-aarch64-rc --noconfirm
	sudo arch-chroot ".cache/root" pacman -S sudo man-db base-devel git --noconfirm
	sudo umount -R ".cache/root"

clean:
	sudo umount -R ".cache/root" || true
	[[ ! -e ".cache/root" ]] || sudo rm -rf ".cache/root"
