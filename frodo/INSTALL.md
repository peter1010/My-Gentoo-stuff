# Using a Live CD

Format the HD like so..

### Disklabel type: gpt

| Device    | Start    | End       |   Sectors |   Size | Type             |
| --------- | -------- | --------- | --------- | ------ | ---------------- |
| /dev/sda1 |     2048 |    526335 |    524288 |   256M | EFI System       |
| /dev/sda2 |   526336 |  34080767 |  33554432 |    16G | Linux swap       |
| /dev/sda3 | 34080768 | 977105026 | 943024259 | 449.7G | Linux filesystem |

### create filesystems for each

> $mkfs.vfat -n BOOT /dev/sda1<br>
> $mkfs.ext4 -L ROOT /dev/sda2<br>
> $mkswap -L SWAP /dev/sda3<br>

create & chroot to gentoo environment on PC (if not already using Gentoo)

From https://www.gentoo.org/downloads/

Get stage3 stage3-amd64-openrc-xxx.tar.xz

### Mount root parition and untar stage3..

> $mount /dev/sda3 /mnt/root<br>
> $tar -xpf stage3-xxx -C /mnt/root<br>

Fixup /mnt/root/etc/fstab

    /dev/sda1          /boot           auto            noauto,noatime  1 2
    /dev/sda2          none            swap            sw              0 0
    /dev/sda3          /               ext4            noatime         0 1

### Get portage-latest.tar.bz2

> $wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2<br>
> $tar xpf portage-latest.tar.bz2 -C /mnt/root/usr<br>
>
> $mkdir /mnt/root/etc/portage/repos.conf<br>
> $cp /mnt/root/usr/share/portage/config/repos.conf /mnt/rpi/etc/portage/repos.conf/gentoo.conf<br>

### Adjust portage/make.conf

Add following to make.conf

    BINPKG_FORMAT="gpkg"
    FEATURES="buildpkg"
    MAKEOPTS="-j1"
    LINGUAS="en_GB"
    L10N="en-GB"

## Build the kernel

> $emerge --ask sys-kernel/gentoo-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz

Make a symbolic link to a generic folder linux

> $eselect kernel list<br>
> $eselect kernel set ?

Copy across config

> $modprobe configs<br>
> $zcat /proc/config.gz > /usr/src/linux/.config

> $cd /usr/src/linux<br>
> $make oldconfig<br>
> $make<br>
> $make modules_install<br>

Mount the boot partition and copy across the kernel

> $mount /dev/sda1 /mnt/boot

Set root ready for startup - temp set up for DNS

> $cp /etc/resolv.conf /mnt/root/etc/resolv.conf

Set up hostname

> $vi /mnt/root/etc/hostname

and/or

> $vi /mnt/root/etc/conf.d/hostname

Set up locale

> $ln -sf /usr/share/zoneinfo/Europe/London /mnt/root/etc/localtime<br>
> $echo "Europe/London" > /mnt/root/etc/timezone

set up keymaps

> $vi /mnt/root/etc/conf.d/keymaps

    keymap="uk"

clear root password

> $sed -i 's/^root:.*/root::::::::/' /mnt/root/etc/shadow 

Edit local.gen

> $vi /mnt/root/etc/locale.gen

umount..

------------------ boot ------------------

Fix keymaps, update local

> $rc-update add keymaps boot<br>
> $rc-service keymaps restart<br>
> $locale-gen

Set time

> $date MMDDhhmmYYYY<br>
> $rc-update add swclock boot<br>
> $rc-update del hwclock boot

Create users

> $useradd -m -g users -G wheel peter<br>
> $passwd peter

Temporary set up wpa_supplicant

> $vi /etc/wpa_supplicant/wpa_supplicant.conf

Add Network

    ctrl_interface=/var/run/wpa_supplicant
    update_config=1

    network={
        scan_ssid=1
        key_mgmt=WPA-PSK
        psk="******"
       ssid="*****"
    }

replace "*****" with appropriate values

Run wpa_supplicant service::

> $rc-service wpa_supplicant start

No dhcp so use ifconfig and iproute

> $ifconfig **** 192.168.11.99/24<br>
> $route add default gw 192.168.11.2

replace **** with wifi network dev

Enable sshd if need to do the rest remotely

> $rc-update add sshd<br>
> $rc-service sshd start

Sync portage

> $emerge-webrsync

> $eselect profile list<br>
> $eselect locale list

emerge "base" packages I like

> $emerge --ask net-misc/dhcpcd<br>
> $emerge --ask net-misc/iwd

Kill wpa_supplicant, start the iwd service::

> $rc-update add iwd<br>
> $rc-service iwd start

Configure iwd

> $iwctl

    station list
    station *** scan
    station *** connect ****

Edit /etc/dhcpcd ...

uncomment "hostname",
comment out "option hostname" we want to supply hostname to the server
uncomment "option ntp_servers"

Add fallback section with static address

Start the dhcpcd service

> $rc-update add dhcpcd<br>
> $rc-service dhcpcd


emerge "base" packages I like

> $emerge --ask app-misc/screen<br>
> $emerge --ask app-portage/gentoolkit

> $emerge --ask app-editors/vim<br>
> USE=python -crypt, set in package.use subfolder

> $emerge --ask dev-vcs/git<br>
> USE=-perl<br>

> $emerge --ask app-admin/sudo<br>
> USE=-sendmail

> $emerge --ask net-misc/chrony<br>
>  USE=-nts -pts -nettle

> $emerge --ask sysklogd

Set root password

> $passwd

Other packages

> $emerge alsa-lib<br>
> $emerge alsa-utils<br>
> $emerge opus<br>
> $emerge app-eselect/eselect-repository

DHCP server

> $emerge net-misc/kea

DNS server

> $emerge net-dns/unbound<br>
> USE=dnscrypt -http2

> $emerge ldns-utils<br> 
        // for drill
> $emerge bind-tools<br>
        // for dig

Create a local (personal) repositry

> $eselect repository create local

Add all audio users to the audio group.

Change the action of pressing the power button when powered::

edit /etc/elogind/logind.conf

Change HandlePowerKey to 'ignore'
Change HandlePowerKeyLongPress to 'poweroff'

> $rc-service elogind restart

Other things are

- Update the /etc/portage/make with FEATURES="buildpkg" for the build machine
- Update USE flags
- move portage build folders onto faster more robost storage media
- check for microcode fixes and apply
- If RAM is low make tmpfiles be on disk see tmpfiles.rst
- Disable audit by setting audit=0 on kernel cmd line

