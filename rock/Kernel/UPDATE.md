# Get config

> $eselect kernel list  
> $eselect kernel set xx  
> $cd /usr/src/linux  

## Either get old config

> $modprobe configs  
> $zcat /proc/config.gz > .config  

## Or

> Copy my\_rockpro64\_defconfig to /usr/src/linux/arch/arm64/configs/
> make my\_rockpro64\_defconfig

# Refresh the config

> $make oldconfig

# Build

> $make

# Install modules

> $make modules\_install

check /lib/modules/ contains the modules

# Mount the boot partition and copy across the kernel

> $cp arch/arm64/boot/Image.gz /boot/linuz-xxxx-gentoo.gz

# Save config

> $make savedefconfig  
> $cp defconfig to .... my\_rockpro64\_defconfig  

# Create emergency initramfs..

