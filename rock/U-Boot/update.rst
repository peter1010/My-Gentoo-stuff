Das U-Boot tools::

    $emerge --ask sys-apps/dtc
    $emerge --ask dev-embedded/u-boot-tools
    $emerge --ask dev-python/pyelftools

U-Boot and ATF::

    $git clone https://source.denx.de/u-boot/u-boot.git git_repo/GL_u_boot
    $cd git_repo/GL_u_boot
    $git checkout v2024.7
    $cd ../..

    $git clone https://github.com/ARM-software/arm-trusted-firmware.git git_repo/GH_Trusted_FW
    $cd git_repo/GH_Trusted_FW
    $get checkout V2.10.0

Optional if cross-compiling::

    $export CROSS_COMPILE=aarch64-unknown-linux-gnu-

Build Trusted FW::

    $make PLAT=rk3399
    $export BL31=path/to/arm-trusted-firmware/build/rk3399/release/bl31/bl31.elf

    $cd ../GL_u_boot

Config U-boot::

    $make rockpro64-rk3399_defconfig
    $scripts/kconfig/merge_config.sh my_rockpro64-rk3399_defconfig
    $make oldconfig

Adjust if necessary::

    $make menuconfig

    $make

    $make savedefconfig
    $cp defconfig my_rockpro64-rk3399_defconfig

Check sizes of idloader.img and u-boot.itb

Assume (i.e. check with fdisk!) that mmcblk has been partitioned with room to fit the u-boot before first partition
e.g. first partition starts at LBA 32768.

Which allows (16384-64)*512 = 8 355 840 bytes max for idloader.img
And 16384*512 = 8 388 608 bytes max for u-boot.itb.

Copy across u-boot::

    $dd if=idloader.img of=/dev/mmcblk1 seek=64 bs=512
    $dd if=u-boot.itb of=/dev/mmcblk1 seek=16384 bs=512

Create boot scripts...
