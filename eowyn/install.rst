====================
On a host PC
====================

For Raspberry PI, we use MBR boot sector (to be backwards compatible)::

    $sudo fdisk /dev/sdc

Delete all paritions with the 'd' command

we use vfat for boot parition and want to end on a 4M boundary so::

    n -> p -> 1 -> <ret> -> +199M

We need a swap parition  2x RAM  so subract 1 or 2G from root partition::

    n -> p -> 2 -> <ret> -> -1G

Take the End sector + 1. Divide by (2 x 1024 x 4), if this is not a whole
integer, note the integer part of the answer and multiply back to the 
sector count, delete partition and recreate with new last sector

Finally::

    n -> p -> 3 -> <ret> -> <ret>

Set parition 1 as boot::

    a -> 1

Set parition types::

    t -> 1 -> c
    t -> 2 -> 83
    t -> 3 -> 82

Example:

/dev/sdc1  *        2048   409599   407552  199M  c W95 FAT32 (LBA
/dev/sdc2         409600 60645375 60235776 28.7G 83 Linux
/dev/sdc3       60645376 62748671  2103296    1G 82 Linux swap / S


Check the boundaries

409600 / (2 * 1024 * 4) = 50
60645376 / (2 * 1024 * 4) = 7403

create filesystems for each::

    $mkfs.vfat -n BOOT /dev/sdc1
    $mkfs.ext4 -L ROOT /dev/sdc2
    $mkswap  -L SWAP /dev/sdc3

create & chroot to gentoo environment on PC (if not already using Gentoo)

Hint for non-gentoo native PC::

    Download stage3-amd64-openrx-xxx.tar.xz from gentoo
    create /mnt/gentoo
    unzip stage3 into /mnt/gentoo

    cp /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

    $mount -types proc /proc /mnt/gentoo/proc
    $mount --rbind /sys /mnt/gentoo/sys
    $mount --make-rslave /mnt/gentoo/sys
    $mount --rbind /dev /mnt/gentoo/dev
    $mount --make-rslave /mnt/gentoo/dev
    $mount --bind /run /mnt/gentoo/run
    $mount --make-slave /mnt/gentoo/run
    $chroot /mnt/gentoo /bin/bash

    $source /etc/profile
    $export PS1="(chroot) ${PS1}"

Mount SD boot parition::

    $mount /dev/sdc1 /boot
    $emerge --ask sys-boot/raspberrypi-firmware

Edit /boot/cmdline.txt (ls -al will find a saved version)::

    Add audit=0 selinux=0
    change root=/dev/mmcblk0p2

Edit /boot/config.txt::

    dtparam=audio=off
    dtoverlay=vc4-kms-v3d
    dtoverlay=i2c-rtc,ds3231
    dtoverlay=disable-bt
    dtoverlay=disable-wifi


    $umount /boot

Get stage3 for the Arm7 "stage3-arm7a_hardfp-xxx.tar.xz

Mount sd card root parition and untar stage3..::

    $mount /dev/sdc2 /mnt/rpi
    $tar -xpf stage3-xxx -C /mnt/rpi

Fixup /mnt/raspberrypi/etc/fstab::

/dev/mmcblk0p1          /boot           auto            noauto,noatime  1 2
/dev/mmcblk0p2          /               ext4            noatime         0 1     
/dev/mmcblk0p3          none            swap            sw              0 0

Adjust  portage/make.conf::

# Raspberry Pi 3 running in 32 bit mode:

COMMON_FLAGS="-O2 -pipe -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"


Get portage-latest.tar.bz2::

    $tar xpf portage-latest.tar.bz2 -C /mnt/rpi/usr

    $mkdir /mnt/rpi/etc/portage/repos.conf
    $cp /mnt/rpi/usr/share/portage/config/repos.conf /mnt/rpi/etc/portage/repos.conf/gentoo.conf

Add following to make.conf::

    LC_MESSAGES=C
    BINPKG_FORMAT="gpkg"
    MAKEOPTS="-j1"
    LINGUAS="en_GB"
    L10N="en-GB"
    EMERGE_DEFAULT_OPTS="--jobs=1 --ask"
    USE="alsa -pulseaudio -dbus -systemd"

If not already done, install cross compiler::

    $emerge --ask sys-devel/crossdev
    $crossdev -S -t armv7a-unknown-linux-gnueabihf

Build the kernel with the cross-compiler::

    $emerge --ask sys-kernel/raspberrypi-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz
so perhaps make a symbolic link to a generic folder linux-rpi::

    $cd /usr/src/linux-rpi
    $make ARCH=arm bcm2709_defconfig
    $make ARCH=arm CROSS_COMPILE=armv7a-unknown-linux-gnueabihf- oldconfig
    $make ARCH=arm CROSS_COMPILE=armv7a-unknown-linux-gnueabihf- -j1
    $make ARCH=arm CROSS_COMPILE=armv7a-unknown-linux-gnueabihf- modules_install INSTALL_MOD_PATH=/mnt/rpi/



check /mnt/rpi/lib/modules/ contains the modules

Mount the boot partition and copy across the kernel::

    $mount /dev/sdc1 /mnt/rpi/boot
    $cp arch/arm/boot/Image /mnt/rpi/boot/kernel.img
    $cp arch/arm/boot/dts/*.dtb /mnt/rpi/boot/
    $mkdir /mnt/rpi/boot/overlays
    $cp arch/arm/boot/dts/overlays/* /mnt/rpi/boot/overlays/ 

Set root ready for startup - temp set up for DNS::

    $cp /etc/resolv.conf /mnt/rpi/etc/resolv.conf



Set up hostname::

    $vi /mnt/rpi/etc/hostname

  and/or

    $vi /mnt/rpi/etc/conf.d/hostname

Set up locale::

    $ln -sf /usr/share/zoneinfo/Europe/London /mnt/rpi/etc/localtime
    $echo "Europe/London" > /mnt/rpi/etc/timezone

set up keymaps::

    $vi /mnt/rpi/etc/conf.d/keymaps

    keymap="uk"

clear root password::

    $sed -i 's/^root:.*/root::::::::/' /mnt/rpi/etc/shadow 


Edit local.gen::

    $vi /mnt/rpi/etc/locale.gen


umount sd card..

------------------ insert sd card into rp and boot ------------------

Fix keymaps, update local::

    $rc-update add keymaps boot
    $rc-service keymaps restart
    $locale-gen

No network of dhcp so use ifconfig and iproute::

    Optional - Add udev rule to make network interface name be eth0?

    $ifconfig eth0 192.168.11.99/24
    $route add default gw 192.168.11.2

Set time::

    $date MMDDhhmmYYYY
    $rc-update add swclock boot
    $rc-update del hwclock boot

Create users::

    $useradd -m -g users -G wheel peter
    $passwd peter

Enable sshd if need to do the rest remotely::

    $rc-update add sshd
    $rc-service sshd start

Sync portage::

    $emerge-webrsync

    $eselect profile list
    $eselect locale list

Get network to automatically come up using dhcp::

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

    $emerge --ask app-misc/screen
    $emerge --ask app-portage/gentoolkit
    $emerge --ask app-editors/vim
        USE=python -crypt, set in package.use subfolder
    $emerge --ask dev-vcs/git
        USE=-perl
    $emerge --ask app-admin/sudo
        USE=-sendmail
    $emerge --ask net-misc/chrony
        USE=-nts -pts -nettle
    $emerge --ask sysklogd
    $emerge --ask dcron

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

DHCP server::

    $emerge net-misc/kea

DNS server::

    $emerge net-dns/unbound
       USE=dnscrypt -http2
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

  on pi add to /boot/cmdline

  
