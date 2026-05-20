# On a host PC

Get suitable SD-card.. assume it is mounted at /dev/sdc on build machine.

## Format Boot/Storage Medium

Partition (see partition.rst)

## Install Stage 3 root partition

See install\_stage3.rst

## Put RPI firmware into the boot partition

Mount the boot partition in the hosts /boot mount point...

> mount /dev/sdc1 /boot

Triple check you have mounted the right /boot as you don't want to distroy the host's boot! 

> emerge --ask sys-boot/raspberrypi-firmware
> umount /boot

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

Get the config from https://github.com/peter1010/My-Gentoo-Stuff/gandalf/Kernel/build

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
    Add net.ifnames=0

Note: net.ifnames=0 means the first network interface found will be called eth0, and so on

Edit /mnt/rpi/boot/config.txt

    dtparam=audio=off
    dtoverlay=vc4-kms-v3d
    dtoverlay=disable-bt
    dtoverlay=disable-wifi

## Tweaks ready to boot nicely

At this point one could umount the sd-card and boot the Raspberry pi. Or for convenience continue with the mounted SD-CARD.
Assumming the latter.

Adjust /mnt/rpi/etc/portage/make.conf

    COMMON_FLAGS="-O2 -pipe -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard"  
    CFLAGS="${COMMON_FLAGS}"  
    CXXFLAGS="${COMMON_FLAGS}"  
    FCFLAGS="${COMMON_FLAGS}"  
    FFLAGS="${COMMON_FLAGS}"  

    BINPKG_FORMAT="gpkg"  
    FEATURES="buildpkg"  
    MAKEOPTS="-j1"  
    LINGUAS="en_GB"  
    L10N="en-GB"  
    EMERGE_DEFAULT_OPTS="--jobs=1 --ask"  

> cp /etc/resolv.conf /mnt/rpi/etc/resolv.conf

Set up hostname

> vi /mnt/rpi/etc/hostname

and/or

> vi /mnt/rpi/etc/conf.d/hostname

Set up domainname & network

> cd /mnt/rpi/etc/init.d  
> ln -s net.lo net.eth0

> vi /mnt/rpi/etc/conf.d/net

See static_ip.rst

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

See adjtimex for setting up RTC

Create users

> useradd -m -g users -G wheel peter  
> passwd peter

Add the startup for the network

> rc-update add net.eth0 boot

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


    $usermod -a -G cron peter


emerge "base" packages I like::

> emerge app-misc/screen
> emerge app-portage/gentoolkit
> emerge app-editors/vim
> emerge dev-vcs/git
> emerge app-admin/sudo

See adjtimex & NTP for time

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

DHCP server::

    $emerge net-misc/kea

Note: the default install is not quite and needs some tweaking in particular the following needs adjusting
1/ kea needs to run as dhcp (not root) so add -u dhcp to start-stop-daemon in /etc/init.d/kea
2/ kea creates a pidfile so remove -m option from start-stop-daemon
3/ kea creates the pidfile in /run/kea/ folder so again /etc/init.d/kea definitions need adjusting for this
4/ logging to "syslog" doesn't work, this could be because kea is running as 'dhcp' user
5/ logging to file needs correct permissions on /var/log/kea/ folder to allow kea to generate the log files


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

  
