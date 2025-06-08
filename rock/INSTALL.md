# On a host PC

Get suitable SD-card.. assume it is mounted at /dev/sdc on build machine.

## Format Boot/Storage Medium

For RockPo64, we use GPT and a EFI partition, run fdisk...

> sudo fdisk /dev/sdc

Delete all partitions with the 'd' command.

Create the GPT partition table 'g'.

We need to make room for the u-boot images so start first parition at LBA 32768!

We use vfat for boot parition and want to end so next partition starts on a 4M boundary so:

> n -> p -> 1 -> 32768 -> 409599

Then the root partition.

> n -> p -> 2 -> \<ret> -> \<ret>

Take the End sector + 1. Divide by (2 x 1024 x 4), if this is not a whole integer, note the integer part of the answer and
multiply back to the sector count, delete partition and recreate with new last sector.

Set partition 1 as boot:

> a -> 1

Set partition types like so:

> t -> 1 -> 1  
> t -> 2 -> 20

Example:

| Device    | Start  | End      | Sectors  | Size  | Type             |
|-----------|--------|----------|----------|-------|------------------|
| /dev/sdc1 |  32768 |   409599 |   407552 |  199M |       EFI System |
| /dev/sdc2 | 409600 | 62332927 | 61923328 | 29.5G | Linux filesystem |


Create filesystems for each like so:

> mkfs.vfat -n BOOT /dev/sdc1  
> mkfs.ext4 -L ROOT /dev/sdc2

## Install Stage 3 root partition

Download stage3 for the Arm64 "stage3-arm64-openrc-xxx.tar.bz2 from gentoo website.

Mount sd card root partition and untar stage3.

> mkdir /mnt/rock  
> mount /dev/sdc2 /mnt/rock  
> tar -xpf stage3-xxx -C /mnt/rock  

Fixup /mnt/rock/etc/fstab

    /dev/mmcblk0p1          /boot           auto            noauto,noatime  1 2  
    /dev/mmcblk0p2          /               ext4            noatime         0 1

Get portage-latest.tar.bz2

> tar -xpf portage-latest.tar.bz2 -C /mnt/rock/usr

> mkdir /mnt/rock/etc/portage/repos.conf
> cp /mnt/rock/usr/share/portage/config/repos.conf /mnt/rock/etc/portage/repos.conf/gentoo.conf

## Build the kernel


Create & chroot to gentoo environment on PC (if not already using Gentoo)

See NON\_GENTOO\_PC.md for setting up Gentoo build env

If not already done, install cross compiler;

> emerge sys-devel/crossdev  
> emerge app-eselect/eselect-repository  
> eselect repository create crossdev  
> crossdev -S -t aarch64-unknown-linux-gnu  

Get the linux source files:

> emerge --ask sys-kernel/gentoo-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz so perhaps make a symbolic link to a generic folder linux-rock

> cd /usr/src/linux-rock

Get the config from https://github.com/peter1010/My-Gentoo-Stuff/rock/Kernel/build

> make ARCH=arm64 rockpro64\_linux\_defconfig  
> scripts/kconfig/merge_config.sh /xxx/my_rockpro64-rk3399_defconfig

Build the kernel with the cross-compiler:

> make ARCH=arm CROSS\_COMPILE=aarch64-unknown-linux-gnu- oldconfig  
> make ARCH=arm CROSS\_COMPILE=aarch64-unknown-linux-gnu- -j1  
> make ARCH=arm CROSS\_COMPILE=aarch64-unknown-linux-gnu- modules\_install INSTALL\_MOD\_PATH=/mnt/rock/

Check /mnt/rock/lib/modules/ contains the modules.

Mount the boot partition and copy across the kernel.

> mount /dev/sdc1 /mnt/rock/boot  
> cp arch/arm64/boot/Image /mnt/rock/boot/xxx

    ...

Create u-boot and install

    ...

## Tweaks ready to boot nicely

At this point one could umount the sd-card and boot the Rock SBC. Of for convenience continue 


Adjust /mnt/rock/etc/portage/make.conf


    COMMON_FLAGS="-O2 -pipe -march=armv8-a+crc+crypto -mtune=cortex-a72.cortex-a53 -mfix-cortex-a53-835769 -mfix-cortex-a53-843419"  
    CFLAGS="${COMMON_FLAGS}"  
    CXXFLAGS="${COMMON_FLAGS}"  
    FCFLAGS="${COMMON_FLAGS}"  
    FFLAGS="${COMMON_FLAGS}"  

    LC_MESSAGES=C  
    MAKEOPTS="-j1"  
    LINGUAS="en_GB"  
    L10N="en-GB"  
    EMERGE_DEFAULT_OPTS="--jobs=1 --ask"
    LLVM_TARGETS="arm aarch64"  
    VIDEO_CARDS="panfrost"
# BINPKG_FORMAT="gpkg"
# FEATURES="buildpkg"
    USE="-pulseaudio alsa wayland elogind -systemd cups -kde -dbus"  

> cp /etc/resolv.conf /mnt/root/etc/resolv.conf

Set up hostname

> vi /mnt/rock/etc/hostname

and/or

> vi /mnt/rock/etc/conf.d/hostname


Set up locale

> ln -sf /usr/share/zoneinfo/Europe/London /mnt/rock/etc/localtime
> echo "Europe/London" > /mnt/rock/etc/timezone

set up keymaps

> vi /mnt/rock/etc/conf.d/keymaps

    keymap="uk"

clear root password

> sed -i 's/^root:.*/root::::::::/' /mnt/rock/etc/shadow 

Edit local.gen

> vi /mnt/rock/etc/locale.gen

    en\_US ISO-8859-1
    en\_US.UTF-8 UTF-8
    en\_GB ISO-8859-1
    en\_GB.UTF-8 UTF-8

umount sd card..

------------------ insert sd card into rp and boot ------------------

# Rock Pro running

Fix keymaps, update local

> rc-update add keymaps boot  
> rc-service keymaps restart  
> locale-gen  

Set time

> date MMDDhhmmYYYY  
> rc-update add swclock boot  
> rc-update del hwclock boot  

Create users

> useradd -m -g users -G wheel peter  
> passwd peter

No dhcp so use ifconfig and iproute::

    $ifconfig **** 192.168.11.99/24
    $route add default gw 192.168.11.2

replace **** with ethernet network dev


Enable sshd if need to do the rest remotely::

    $rc-update add sshd
    $rc-service sshd start


Sync portage::

    $emerge-webrsync

    $eselect profile list
    $eselect locale list

emerge "base" packages I like::

    $emerge --ask net-misc/dhcpcd

Edit /etc/dhcpcd ...

uncomment "hostname",
comment out "option hostname" we want to supply hostname to the server
uncomment "option ntp_servers"

Add fallback section with static address

Start the dhcpcd service::

    $rc-update add dhcpcd
    $rc-service dhcpcd


emerge "base" packages I like::

> emerge app-misc/screen
> emerge app-portage/gentoolkit
> emerge app-editors/vim
> emerge dev-vcs/git
> emerge app-admin/sudo
> emerge net-misc/chrony
> emerge sysklogd


Set root password::

  $passwd


Other packages::

    $emerge alsa-lib
    $emerge alsa-utils
    $emerge opus
    $emerge app-eselect/eselect-repository

DNS server::

    $emerge ldns-utils 
        // for drill
    $emerge bind-tools
        // for dig


Create a local (personal) repositry::

    $eselect repository create local

Add all audio users to the audio group.
 

Other things are

  * Update the /etc/portage/make with FEATURES="buildpkg" for the build machine

  * Update USE flags

  * move portage build folders onto faster more robost storage media

  * check for microcode fixes and apply

  * If RAM is low make tmpfiles be on disk see tmpfiles.rst

  * Disable audit by setting audit=0 on kernel cmd line

