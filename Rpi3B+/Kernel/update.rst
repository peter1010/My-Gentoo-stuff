Get old config::

    $cd /usr/src/linux
    $modprobe configs
    $zcat /proc/config.gz .config

Refresh the config::

    $make oldconfig

Build::

    $make

Installl modules::

    $make modules_install

check /lib/modules/ contains the modules

Mount the boot partition and copy across the kernel::

    $cp /usr/src/linux/arch/arm/boot/Image /boot/kernel.img
    $cp /usr/src/linux/arch/arm/boot/dts/*rpi*.dtb /boot/
    $mkdir /boot/overlays
    $cp /usr/src/linux/arch/arm/boot/dts/overlays/*.dtbo /boot/overlays/
    $cp /usr/src/linux/arch/arm/boot/dts/overlays/README.txt /boot/overlays/

