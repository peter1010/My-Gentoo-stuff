====================
Using a Live CD
====================

Format the HD like so..

Disklabel type: gpt

Device        Start       End   Sectors   Size Type
/dev/sda1      2048    526335    524288   256M EFI System
/dev/sda2    526336  34080767  33554432    16G Linux swap
/dev/sda3  34080768 977105026 943024259 449.7G Linux filesystem

create filesystems for each::

    $mkfs.vfat -n BOOT /dev/sda1
    $mkfs.ext4 -L ROOT /dev/sda2
    $mkswap  -L SWAP /dev/sda3

create & chroot to gentoo environment on PC (if not already using Gentoo)


From https://www.gentoo.org/downloads/

Get stage3 stage3-amd64-openrc-xxx.tar.xz

Mount root parition and untar stage3..::

    $mount /dev/sda3 /mnt/root
    $tar -xpf stage3-xxx -C /mnt/root

Fixup /mnt/root/etc/fstab::

/dev/sda1          /boot           auto            noauto,noatime  1 2
/dev/sda2          none            swap            sw              0 0
/dev/sda3          /               ext4            noatime         0 1

Get portage-latest.tar.bz2::

    $wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2

    $tar xpf portage-latest.tar.bz2 -C /mnt/root/usr

    $mkdir /mnt/root/etc/portage/repos.conf
    $cp /mnt/root/usr/share/portage/config/repos.conf /mnt/rpi/etc/portage/repos.conf/gentoo.conf

Adjust  portage/make.conf::


Add following to make.conf::

    BINPKG_FORMAT="gpkg"
    FEATURES="buildpkg"
    MAKEOPTS="-j1"
    LINGUAS="en_GB"
    L10N="en-GB"

Build the kernel::

    $emerge --ask sys-kernel/gentoo-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz

Make a symbolic link to a generic folder linux::

    $eselect kernel list
    $eselect kernel set ?

Copy across config::

    $modprobe configs
    $zcat /proc/config.gz > /usr/src/linux/.config

    $cd /usr/src/linux
    $make oldconfig
    $make
    $make modules_install

Mount the boot partition and copy across the kernel::

    $mount /dev/sda1 /mnt/boot

Set root ready for startup - temp set up for DNS::

    $cp /etc/resolv.conf /mnt/root/etc/resolv.conf



Set up hostname::

    $vi /mnt/root/etc/hostname

  and/or

    $vi /mnt/root/etc/conf.d/hostname

Set up domainname & network::

    $ln -s net.lo /etc/init.d/net.eth0

    $vi /mnt/root/etc/conf.d/net


    dns_domain_lo="home.arpa"
    config_eth0="dhcp"

    OR

    config_eth0="192.168.11.10/24"
    routes_eth0="default via 192.168.11.2"
    dns_servers_eth0="192.168.11.10"

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

No network of dhcp so use ifconfig and iproute::

    $ifconfig etho 192.168.11.99/24
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

emerge "base" packages I like::

    $emerge --ask net-misc/dhcpcd

Edit /etc/dhcpcd ...
uncomment "hostname", comment out "option hostname" we want to supply hostname to the server

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

DHCP server::

    $emerge net-misc/kea

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

