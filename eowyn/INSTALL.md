# On a host PC

Get suitable SD-card.. assume it is mounted at /dev/sdc on build machine.

## Format Boot/Storage Medium

For Raspberry PI, we use MBR boot sector (to be backwards compatible).

> sudo fdisk /dev/sdc

Delete all partitions with the 'd' command.

As we use vfat for boot partition and want to end on a 4M boundary so.

> n -> p -> 1 -> \<ret> -> +199M

We need a swap parition  2x RAM  so subract 1 or 2G from root partition

> n -> p -> 2 -> \<ret> -> -1G

Take the End sector + 1. Divide by (2 x 1024 x 4), if this is not a whole integer, note the integer part of the answer and
multiply back to the sector count, delete partition and recreate with new last sector.

Finally

> n -> p -> 3 -> \<ret> -> \<ret>

Set partition 1 as boot:

> a -> 1

Set partition types like so:

> t -> 1 -> c  
> t -> 2 -> 83  
> t -> 3 -> 82  

Example:

| Device    | Start    | End      | Sectors  | Size  | Type          |
|-----------|----------|----------|----------|-------|---------------|
| /dev/sdc1 |     2048 |   409599 |   407552 |  199M |  c W95 FAT32  |
| /dev/sdc2 |   409600 | 60645375 | 60235776 | 28.7G | 83 Linux      |
| /dev/sdc3 | 60645376 | 62748671 |  2103296 |    1G | 82 Linux swap |


Check the boundaries

409600 / (2 * 1024 * 4) = 50
60645376 / (2 * 1024 * 4) = 7403

Create filesystems for each like so:

> mkfs.vfat -n BOOT /dev/sdc1  
> mkfs.ext4 -L ROOT /dev/sdc2  
> mkswap  -L SWAP /dev/sdc3

## Install Stage 3 root partition

Download stage3 for the Arm7 "stage3-arm7a\_hardfp-xxx.tar.xz

Mount sd card root partition and untar stage3.

> mkdir /mnt/rpi  
> mount /dev/sdc2 /mnt/rpi  
> tar -xpf stage3-xxx -C /mnt/rpi  

Fixup /mnt/rpi/etc/fstab

    /dev/mmcblk0p1          /boot           auto            noauto,noatime  1 2   
    /dev/mmcblk0p2          /               ext4            noatime         0 1  
    /dev/mmcblk0p3          none            swap            sw              0 0

Get portage-latest.tar.bz2

> tar -xpf portage-latest.tar.bz2 -C /mnt/rpi/usr

> mkdir /mnt/rpi/etc/portage/repos.conf  
> cp /mnt/rpi/usr/share/portage/config/repos.conf /mnt/rpi/etc/portage/repos.conf/gentoo.conf

## Put RPI firmware into the boot partition

Mount the boot partition in the hosts /boot mount point...

> mount /dev/sdc1 /boot

Triple check you have mounted the right /boot as you don't want to distroy the host's boot! 

> emerge --ask sys-boot/raspberrypi-firmware
> unmout /boot

## Build the kernel

Create & chroot to gentoo environment on PC (if not already using Gentoo)

See NON\_GENTOO\_PC.md for setting up Gentoo build env

If not already done, install cross compiler;

> emerge sys-devel/crossdev  
> emerge app-eselect/eselect-repository  
> eselect repository create crossdev  
> crossdev -S -t armv7a-unknown-linux-gnueabihf

Get the linux source files:

> emerge sys-kernel/raspberrypi-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz so perhaps make a symbolic link to a generic folder linux-rpi

> cd /usr/src/linux-rpi

Get the config from https://github.com/peter1010/My-Gentoo-Stuff/eowyn/Kernel/build

> make ARCH=arm bcm2709\_defconfig  
> scripts/kconfig/merge\_config.sh /xxx/my\_rpi3\_defconfig

Build the kernel with the cross-compiler:

> make ARCH=arm CROSS\_COMPILE=armv7a-unknown-linux-gnueabihf- oldconfig  
> make ARCH=arm CROSS\_COMPILE=armv7a-unknown-linux-gnueabihf- -j1  
> make ARCH=arm CROSS\_COMPILE=armv7a-unknown-linux-gnueabihf- modules\_install INSTALL\_MOD\_PATH=/mnt/rpi/  

Check /mnt/rpi/lib/modules/ contains the modules.

Mount the boot partition, again, but this time somewhere safer that before.

> mount /dev/sdc1 /mnt/rpi/boot  
> cp arch/arm/boot/Image /mnt/rpi/boot/kernel.img  
> cp arch/arm/boot/dts/\*.dtb /mnt/rpi/boot/  
> mkdir /mnt/rpi/boot/overlays  
> cp arch/arm/boot/dts/overlays/\* /mnt/rpi/boot/overlays/


Edit /mnt/rpi/boot/cmdline.txt (ls -al will find a saved version)

    Add audit=0 selinux=0
    change root=/dev/mmcblk0p2

Edit /mnt/rpi/boot/config.txt

    dtparam=audio=off
    dtoverlay=vc4-kms-v3d
    dtoverlay=i2c-rtc,ds3231
    dtoverlay=disable-bt
    dtoverlay=disable-wifi

## Tweaks ready to boot nicely

At this point one could umount the sd-card and boot the Raspberry pi. Or for convenience continue with the mounted SD-CARD. Assumming the latter.


Adjust /mnt/rpi/etc/portage/make.conf



    COMMON_FLAGS="-O2 -pipe -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard"  
    CFLAGS="${COMMON_FLAGS}"  
    CXXFLAGS="${COMMON_FLAGS}"  
    FCFLAGS="${COMMON_FLAGS}"  
    FFLAGS="${COMMON_FLAGS}"  

    BINPKG_FORMAT="gpkg"
    MAKEOPTS="-j1"  
    LINGUAS="en_GB"  
    L10N="en-GB"  
    EMERGE_DEFAULT_OPTS="--jobs=1 --ask"  
    USE="alsa -pulseaudio -dbus -systemd"  


> cp /etc/resolv.conf /mnt/rpi/etc/resolv.conf

Set up hostname

> vi /mnt/rpi/etc/hostname

and/or

> vi /mnt/rpi/etc/conf.d/hostname

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

    en\_US ISO-8859-1
    en\_US.UTF-8 UTF-8
    en\_GB ISO-8859-1
    en\_GB.UTF-8 UTF-8

umount sd card..

------------------ insert sd card into rp and boot ------------------

# Raspberry Pi 3 running:

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

Fix the network interface names by creating a /etc/udev/rules.d/99\_my.rules

    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="xx:xx:xx:xx:xx:xx", NAME="eth0"

Reboot and check network interface is now eth0

Initinally no dhcp so use ifconfig and iproute..

> ifconfig eth0 192.168.11.99/24
> route add default gw 192.168.11.2

Enable sshd if need to do the rest remotely

> rc-update add sshd  
> rc-service sshd start

# SSH running so remote login is possible:

Sync portage

> emerge-webrsync

> eselect profile list  
> eselect locale list

Setup portage use flags

    copy from my github the general uses file

Setup console fonts.


Get network to automatically come up using dhcp

> emerge net-misc/dhcpcd

Edit /etc/dhcpcd ...

    uncomment "hostname"  
    comment out "option hostname" we want to supply hostname to the server  
    uncomment "option ntp\_servers"  

    slaac token ::16  
    \# if dhcp fails, assigne IP address so we are reachable  
    fallback static_xxx  

    profile static_xxx
    static ip_address=192.168.11.16/24


Start the dhcpcd service::

> rc-update add dhcpcd  
> rc-service dhcpcd


emerge "base" packages I like::

> emerge app-misc/screen
> emerge app-portage/gentoolkit
> emerge app-editors/vim
> emerge dev-vcs/git
> emerge app-admin/sudo
> emerge net-misc/chrony
> emerge sysklogd
> emerge dcron

    $usermod -a -G cron peter
    $rc-update add dcron default
    $rc-service dcron restart

Set root password::

  $passwd

Other packages::

    $emerge alsa-lib
    $emerge alsa-utils
    $emerge opus
    $emerge app-eselect/eselect-repository




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

  on pi add to /boot/cmdline

  
