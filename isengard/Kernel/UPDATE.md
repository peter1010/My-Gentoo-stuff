# Get old config

> eselect kernel list  
> eselect kernel set xx  
> cd /usr/src/linux  

## Either get old config

> modprobe configs  
> zcat /proc/config.gz .config  

## Or

> cp xx_defconfig arch/arm/configs/my_defconfig  
> make my_defconfig

# Refresh the config

> make oldconfig

# Build

> $make

# Install modules

> $make modules_install

check /lib/modules/ contains the modules

# Mount the boot partition and copy across the kernel::

> $cp arch/arm64/boot/Image /boot/kernel8.img  
> $cp arch/arm64/boot/dts/broadcom/*rpi*.dtb /boot/  
> $mkdir /boot/overlays  
> $cp arch/arm/boot/dts/overlays/*.dtbo /boot/overlays/  
> $cp arch/arm/boot/dts/overlays/README /boot/overlays/  

# Save a defconfig

> $make savedefconfig  
> $cp defconfig ..._defconfig  
