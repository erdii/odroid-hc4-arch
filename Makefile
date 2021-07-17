SHELL=/bin/bash
.SHELLFLAGS=-euo pipefail -c

CACHE := .cache
MIRROR := http://de5.mirror.archlinuxarm.org

arch_image := ArchLinuxARM-aarch64-latest.tar.gz

$(CACHE):
	mkdir -p "$(CACHE)"
$(CACHE)/tmp:
	mkdir -p "$(CACHE)/tmp"

# why is this executing every time?
# TODO fix and add as dependency where needed
arch-image: $(CACHE)/$(arch_image)
$(CACHE)/$(arch_image): $(CACHE) $(CACHE)/tmp
	curl -o "$(CACHE)/tmp/$(arch_image)" $(MIRROR)/os/ArchLinuxARM-aarch64-latest.tar.gz
	curl -o "$(CACHE)/tmp/$(arch_image).sig" $(MIRROR)/os/ArchLinuxARM-aarch64-latest.tar.gz.sig
	# import archlinux arm build pgp key:
	# gpg --keyserver keyserver.ubuntu.com --recv-keys 68B3537F39A313B3E574D06777193F152BDBE6A6
	gpg --verify "$(CACHE)/tmp/$(arch_image).sig"
	mv "$(CACHE)/tmp/$(arch_image)" "$(CACHE)/$(arch_image)"

$(CACHE)/root: $(CACHE) # $(CACHE)/$(arch_image)
	sudo mkdir "$(CACHE)/root"
	# su -c 'bsdtar -xpf "$(CACHE)/$(arch_image)" -C "$(CACHE)/root"'

merge:
	sudo rsync -a --no-o --no-g "root/" "$(CACHE)/root/"

setup: # | $(CACHE)/root merge
	mountpoint "$(CACHE)/root" > /dev/null || sudo mount --bind "$(CACHE)/root" "$(CACHE)/root"
	sudo arch-chroot "$(CACHE)/root" pacman-key --init
	sudo arch-chroot "$(CACHE)/root" pacman-key --populate archlinuxarm
	sudo arch-chroot "$(CACHE)/root" pacman -Syu --noconfirm
	sudo arch-chroot "$(CACHE)/root" pacman -S uboot-tools --noconfirm
	sudo arch-chroot "$(CACHE)/root" /bin/bash -c 'pacman -Q linux-aarch64; if [[ $? == 0 ]]; then pacman -Rs linux-aarch64 --noconfirm; else true; fi'
	sudo arch-chroot "$(CACHE)/root" pacman -S linux-aarch64-rc --noconfirm
	sudo umount -R "$(CACHE)/root"

clean:
	sudo umount "$(CACHE)/root" || true
	[[ ! -e "$(CACHE)/root" ]] || sudo rm -rf "$(CACHE)/root"

# root/boot/dtbs/amlogic/meson-sm1-odroid-hc4.dtb: $(CACHE)/linux
# 	dtc \
# 		-O dtb \
# 		"$(CACHE)/linux/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts" \
# 		-o "root/boot/dtbs/amlogic/meson-sm1-odroid-hc4.dtb"

# $(CACHE)/linux: $(CACHE)
# 	git clone \
# 		--depth=1 \
# 		--branch v5.12 \
# 		https://github.com/torvalds/linux \
# 		"$(CACHE)/linux"
