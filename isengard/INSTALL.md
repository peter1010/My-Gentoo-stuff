# On a host PC

For Raspberry PI, we use MBR boot sector (to be backwards compatible).

> sudo fdisk /dev/sdc

Delete all paritions with the 'd' command.

As we use vfat for boot parition and want to end on a 4M boundary so.

    n -> p -> 1 -> <ret> -> +199M
    n -> p -> 2 -> <ret> -> <ret>

Take the End sector + 1. Divide by (2 x 1024 x 4), if this is not a whole
integer, note the integer part of the answer and multiply back to the 
sector count, delete partition and recreate with new last sector.

Set parition 1 as boot

    a -> 1

Set parition types

    t -> 1 -> c
    t -> 2 -> 83

Example:

| Device    | Start    | End      | Sectors  | Size  | Type          |
| --------- |--------- | -------- | -------- | ----- | ------------- |
| /dev/sdc1 |     2048 |   409599 |   407552 |  199M |  c W95 FAT32  |
| /dev/sdc2 |   409600 | 60645375 | 61924352 | 29.5G | 83 Linux      |

Check the boundaries

409600 / (2 * 1024 * 4) = 50

Create filesystems for each.

> mkfs.vfat -n BOOT /dev/sdc1  
> mkfs.ext4 -L ROOT /dev/sdc2  

Create & chroot to gentoo environment on PC (if not already using Gentoo)

Hint for non-gentoo native PC

    Download stage3-amd64-openrx-xxx.tar.xz from gentoo
    create /mnt/gentoo
    unzip stage3 into /mnt/gentoo

> cp /etc/resolv.conf /mnt/gentoo/etc/resolv.conf 

> mount -types proc /proc /mnt/gentoo/proc  
> mount --rbind /sys /mnt/gentoo/sys  
> mount --make-rslave /mnt/gentoo/sys  
> mount --rbind /dev /mnt/gentoo/dev  
> mount --make-rslave /mnt/gentoo/dev  
> mount --bind /run /mnt/gentoo/run  
> mount --make-slave /mnt/gentoo/run  
> chroot /mnt/gentoo /bin/bash  

> source /etc/profile  
> export PS1="\(chroot\) \$\{PS1\}"

Mount SD boot parition.

> mount /dev/sdc1 /boot

Triple check you have mounted the right /boot as you don't want to distroy the host 

> emerge --ask sys-boot/raspberrypi-firmware

Edit /boot/cmdline.txt (ls -al will find a saved version)

    Add audit=0 selinux=0
    change root=/dev/mmcblk0p2

Edit /boot/config.txt

    dtparam=audio=off
    dtoverlay=vc4-fkms-v3d
    max_framebuffers=2
    dtoverlay=i2c-rtc,ds3231
    dtoverlay=disable-bt
    dtoverlay=disable-wifi


> umount /boot

Get stage3 for the Arm64 "stage3-arm64-openrc-xxx.tar.zx" from https://distfiles.gentoo.org/releases/

Mount sd card root parition and untar stage3..

> mount /dev/sdc2 /mnt/rpi  
> tar -xpf stage3-xxx -C /mnt/rpi 

Fixup /mnt/rpi/etc/fstab

    /dev/mmcblk0p1          /boot           auto            noauto,noatime  1 2
    /dev/mmcblk0p2          /               ext4            noatime         0 1     

Adjust portage/make.conf

# Raspberry Pi 4 running:

    COMMON_FLAGS="-O2 -mcpu=cortex-a72 -ftree-vectorize -fomit-frame-pointer"
    CFLAGS="${COMMON_FLAGS}"
    CXXFLAGS="${COMMON_FLAGS}"
    FCFLAGS="${COMMON_FLAGS}"
    FFLAGS="${COMMON_FLAGS}"

Get portage-latest.tar.bz2

> tar -xpf portage-latest.tar.bz2 -C /mnt/rpi/usr

> mkdir /mnt/rpi/etc/portage/repos.conf  
> cp /mnt/rpi/usr/share/portage/config/repos.conf /mnt/rpi/etc/portage/repos.conf/gentoo.conf

Add following to make.conf

    BINPKG_FORMAT="gpkg"
    FEATURES="buildpkg"
    MAKEOPTS="-j1"
    LINGUAS="en_GB en fr"
    L10N="en-GB en fr"
    EMERGE_DEFAULT_OPTS="--jobs=1 --ask"

If not already done, install cross compiler

> emerge --ask sys-devel/crossdev
> crossdev -S -t aarch64-unknown-linux-gnu

Build the kernel with the cross-compiler

> emerge --ask sys-kernel/raspberrypi-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz
so perhaps make a symbolic link to a generic folder linux-rpi

> cd /usr/src/linux-rpi
> make ARCH=arm64 bcm2711_defconfig  
> make ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- oldconfig  
> make ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- -j1  
> make ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- modules_install INSTALL_MOD_PATH=/mnt/rpi/'  
    
Check /mnt/rpi/lib/modules/ contains the modules

Mount the boot partition and copy across the kernel::

> mount /dev/sdc1 /mnt/rpi/boot  
> cp arch/arm64/boot/Image /mnt/rpi/boot/kernel8.img  
> cp arch/arm64/boot/broadcom/dts/\*.dtb /mnt/rpi/boot/  
> mkdir /mnt/rpi/boot/overlays  
> cp arch/arm64/boot/dts/overlays/\* /mnt/rpi/boot/overlays/  

Set root ready for startup - temp set up for DNS

> cp /etc/resolv.conf /mnt/rpi/etc/resolv.conf

Set up hostname

> vi /mnt/rpi/etc/conf.d/hostname

Set up domainname & network

> cd /mnt/rpi/etc/init.d  
> ln -s net.lo net.eth0

> vi /mnt/rpi/etc/conf.d/net

    config_eth0="192.168.11.11/24"

    routes_eth0="default via 192.168.11.5
    217.169.20.20/31 via 192.168.11.5
    185.214.220.7/32 via 192.168.11.3
    185.130.156.7/32 via 192.168.11.3"

    dns_servers_eth0="192.168.11.11"
    dns_search_eth0="home.arpa"

    \# set IPv6 interface token
    preup() {
        ip token set ::11 dev eth0
        return 0
    }

    \# optional: assign the token ::11 address to fe80:
    postup() {
        ip addr flush scope link dev eth0
        ip addr add fe80::11/64 dev eth0
        return 0
    }

Set up locale

> ln -sf /usr/share/zoneinfo/Europe/London /mnt/rpi/etc/localtime  
> echo "Europe/London" > /mnt/rpi/etc/timezone

set up keymaps

> vi /mnt/rpi/etc/conf.d/keymaps

    keymap="uk"

clear root password

> sed -i 's/^root:.*/root::::::::/' /mnt/rpi/etc/shadow 

Edit local.gen

> vi /mnt/rpi/etc/locale.gen

    en_US ISO-8859-1
    en_US.UTF-8 UTF-8
    en_GB ISO-8859-1
    en_GB.UTF-8 UTF-8

umount sd card..

------------------ insert sd card into rp and boot ------------------

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

Fix the network interface names by creating a /etc/udev/rules.d/99_my.rules

    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="xx:xx:xx:xx:xx:xx", NAME="eth0"

Add the startup for the network

> rc-update add net.eth0 boot

Enable sshd if need to do the rest remotely

> rc-update add sshd  
> rc-service sshd start  

Sync portage

> emerge-webrsync  

> eselect profile list  
> eselect locale list  

Setup portage use flags

    copy from my github the general uses file

Setup console fonts.

> emerge media-fonts/terminus-font

Edit /etc/conf.d/consolefonts and add

    consolefont="ter-v32n"

> rc-update add consolefont boot


emerge "base" packages I like::

    $emerge --ask app-misc/screen
    $emerge --ask app-portage/gentoolkit
    $emerge --ask app-editors/vim
    $emerge --ask dev-vcs/git
    $emerge --ask app-admin/sudo
    $emerge --ask net-misc/chrony
    $emerge --ask rsyslog
    $emerge --ask dcron
    $emerge --ask logrotate

    $rc-update add chronyd
    $rc-service chronyd start

Adjust /etc/chrony to point to time services::

    $rc-update add dcron
    $rc-service dcron start

    $rc-update add rsyslog
    $rc-service rsyslog start

Set root password::

  $passwd


Other packages::

    $emerge alsa-lib
    $emerge alsa-utils
    $emerge opus
    $emerge app-eselect/eselect-repository

DHCP server::

    $emerge net-misc/kea

DNS server::

    $emerge net-dns/bind


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

  * haveged and rng-tools no longer need to un-install

  on pi add to /boot/cmdline

  
