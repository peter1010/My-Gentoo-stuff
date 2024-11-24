Get old config::

    $cd /usr/src/linux
    $modprobe configs
    $zcat /proc/config.gz .config

Refresh the config::

    $make oldconfig

Build::

    $make

Install modules::

    $make modules_install

check /lib/modules/ contains the modules

Mount the boot partition and copy across the kernel::

    $cp arch/arm/boot/Image /boot/kernel.img
    $cp arch/arm/boot/dts/broadcom/*rpi*.dtb /boot/
    $mkdir /boot/overlays
    $cp arch/arm/boot/dts/overlays/*.dtbo /boot/overlays/
    $cp arch/arm/boot/dts/overlays/README.txt /boot/overlays/

Save config::

    $make savedefconfig
    $cp defconfig to .... xx_defconfig

Use previously saved defconfig::

    $cp xx_defconfig arch/<arch>/configs/my_defconfig
    $make my_defconfig
