# Get config

> $eselect kernel list  
> $eselect kernel set xx  
> $cd /usr/src/linux  

## Either get old config

> $modprobe configs  
> $zcat /proc/config.gz > .config  

## Or

> $cp xxx/MacBookPro_linux_defconfig to /usr/src/linux/arch/x86_6/configs/
> $make MacbooPro_defconfig

# Refresh the config

> $make oldconfig

# Build

> $make

# Install modules

> $make modules_install

check /lib/modules/ contains the modules

# Mount the boot partition and copy across the kernel

> $cp arch/x86_64/boot/bzImage /boot/vmlinuz_xxxx.bz

# Save config

> $make savedefconfig  
> $cp defconfig to .... xx_defconfig  

# Create emergency initramfs..

