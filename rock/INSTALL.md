# On a host PC

Get suitable SD-card.. assume it is mounted at /dev/sdc on build machine

For RockPo64, we use GPT and a EFI partition

> sudo fdisk /dev/sdc

Delete all paritions with the 'd' command

Create the GPT partition table 'g'

We need to make room for the u-boot images so start first parition at LBA 32768!

we use vfat for boot parition and want to end so next partition starts on a 4M boundary so::

    n -> p -> 1 -> 32768 -> 409599

Then the root partition..

    n -> p -> 2 -> <ret> -> <ret>

Take the End sector + 1. Divide by (2 x 1024 x 4), if this is not a whole
integer, note the integer part of the answer and multiply back to the 
sector count, delete partition and recreate with new last sector

Set parition types

    t -> 1 -> 1
    t -> 2 -> 20

Example:

| Device    | Start  |    End   | Sectors  | Size  | Type             |
|-----------|--------|----------|----------|-------|------------------|
| /dev/sdc1 |  32768 |   409599 |   407552 |  199M |       EFI System |
| /dev/sdc2 | 409600 | 62332927 | 61923328 | 29.5G | Linux filesystem |


create filesystems for each

> mkfs.vfat -n BOOT /dev/sdc1
> mkfs.ext4 -L ROOT /dev/sdc2

Get stage3 for the Arm64 "stage3-arm64-openrc-xxx.tar.bz2
Mount sd card root parition and untar stage3..

> mount /dev/sdc2 /mnt/root
> tar -xpf stage3-xxx -C /mnt/root

Fixup /mnt/root/etc/fstab

  /dev/mmcblk0p1          /boot           auto            noauto,noatime  1 2  
  /dev/mmcblk0p2          /               ext4            noatime         0 1

Get portage-latest.tar.bz2

> tar xpf portage-latest.tar.bz2 -C /mnt/root/usr

> mkdir /mnt/root/etc/portage/repos.conf
> cp /mnt/root/usr/share/portage/config/repos.conf /mnt/root/etc/portage/repos.conf/gentoo.conf


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

If not already done, install cross compiler::

    $emerge --ask sys-devel/crossdev
    $emerge --ask app-eselect/eselect-repository
    $eselect repository create crossdev
    $crossdev -S -t aarch64-unknown-linux-gnu

Build the kernel with the cross-compiler::

    $emerge --ask sys-kernel/gentoo-sources

Get the config::

    $git clone https://github.com/peter1010/RockPro64.git xxx

Source will end up in /usr/src/linux-xxx-yyy-zzz
so perhaps make a symbolic link to a generic folder linux-rock::

    $cd /usr/src/linux-rock

    $make ARCH=arm64 rockpro64_linux_defconfig
    $scripts/kconfig/merge_config.sh /xxx/my_rockpro64-rk3399_defconfig

    $make ARCH=arm CROSS_COMPILE=aarch64-unknown-linux-gnu- oldconfig
    $make ARCH=arm CROSS_COMPILE=aarch64-unknown-linux-gnu- -j1
    $make ARCH=arm CROSS_COMPILE=aarch64-unknown-linux-gnu- modules_install INSTALL_MOD_PATH=/mnt/root/

check /mnt/root/lib/modules/ contains the modules

Mount the boot partition and copy across the kernel::

    ...

Create u-boot and install

    ...

Set root ready for startup - temp set up for DNS::

    $cp /etc/resolv.conf /mnt/root/etc/resolv.conf


Set up hostname::

    $vi /mnt/root/etc/hostname

  and/or

    $vi /mnt/root/etc/conf.d/hostname


Set up locale::

    $ln -sf /usr/share/zoneinfo/Europe/London /mnt/root/etc/localtime
    $echo "Europe/London" > /mnt/root/etc/timezone

set up keymaps::

    $vi /mnt/root/etc/conf.d/keymaps

    keymap="uk"

clear root password::

    $sed -i 's/^root:.*/root::::::::/' /mnt/root/etc/shadow 


Edit local.gen::

    $vi /mnt/root/etc/locale.gen


umount..

------------------ boot ------------------

Fix keymaps, update local::

    $rc-update add keymaps boot
    $rc-service keymaps restart
    $locale-gen

Set time::

    $date MMDDhhmmYYYY
    $rc-update add swclock boot
    $rc-update del hwclock boot

Create users::

    $useradd -m -g users -G wheel peter
    $passwd peter

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


Set root password::

  $passwd


Other packages::

    $emerge alsa-lib
    $emerge alsa-utils
    $emerge opus
    $emerge app-eselect/eselect-repository

DNS server::

    $emerge net-dns/unbound
       USE=dnscrypt -http2
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

