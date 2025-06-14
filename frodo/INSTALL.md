# Using a Live CD

Format the HD like so..

## Format Boot/Storage Medium

For MacBook we use  gpt

> sudo fdisk /dev/sda

Delete all partitions with the 'd' command.



We use vfat for boot partition



Set partition types like so:

> t -> 1 -> 1  
> t -> 2 -> 20

Example:

| Device    | Start    | End       | Sectors   |   Size | Type             |
|-----------|----------|-----------|-----------|--------| ---------------- |
| /dev/sda1 |     2048 |    526335 |    524288 |   256M | EFI System       |
| /dev/sda2 |   526336 |  34080767 |  33554432 |    16G | Linux swap       |
| /dev/sda3 | 34080768 | 977105026 | 943024259 | 449.7G | Linux filesystem |


Create filesystems for each like so:

> mkfs.vfat -n BOOT /dev/sda1  
> mkfs.ext4 -L ROOT /dev/sda2  
> mkswap -L SWAP /dev/sda3  

## Install Stage 3 root partition

Download stage3 stage3-amd64-openrc-xxx.tar.xz from Gentoo.

Mount root partition and untar stage3..

> mkdir /mnt/root  
> mount /dev/sda3 /mnt/root  
> tar -xpf stage3-xxx -C /mnt/root  

Fixup /mnt/root/etc/fstab

    /dev/sda1          /boot           auto            noauto,noatime  1 2
    /dev/sda2          none            swap            sw              0 0
    /dev/sda3          /               ext4            noatime         0 1

Get portage-latest.tar.bz2

> wget http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2  
> tar -xpf portage-latest.tar.bz2 -C /mnt/root/usr  

> mkdir /mnt/root/etc/portage/repos.conf  
> cp /mnt/root/usr/share/portage/config/repos.conf /mnt/root/etc/portage/repos.conf/gentoo.conf<br>

## Build the kernel


Create & chroot to gentoo environment on PC (if not already using Gentoo)

See NON\_GENTOO\_PC.md for setting up Gentoo build env



Get the linux source files:

> emerge --ask sys-kernel/gentoo-sources

Source will end up in /usr/src/linux-xxx-yyy-zzz so perhaps make a symbolic link to a generic folder linux

> cd /usr/src/linux-rock

Get the configfrom https://github.com/peter1010/My-Gentoo-Stuff/frodo/Kernel/build



> make oldconfig  
> make  
> make modules\_install INSTALL\_MOD\_PATH=/mnt/root

Mount the boot partition and copy across the kernel

> mount /dev/sda1 /mnt/boot


Create grub and install


## Tweaks ready to boot nicely

At this point one could umount the CD rom and boot the laptop. Of for convenience continue 


Adjust portage/make.conf


    BINPKG_FORMAT="gpkg"
    FEATURES="buildpkg"
    MAKEOPTS="-j1"
    LINGUAS="en_GB"
    L10N="en-GB"



> cp /etc/resolv.conf /mnt/root/etc/resolv.conf

Set up hostname

> vi /mnt/root/etc/hostname

and/or

> vi /mnt/root/etc/conf.d/hostname

Set up locale

> ln -sf /usr/share/zoneinfo/Europe/London /mnt/root/etc/localtime  
> echo "Europe/London" > /mnt/root/etc/timezone

set up keymaps

> vi /mnt/root/etc/conf.d/keymaps

    keymap="uk"

clear root password

> $sed -i 's/^root:.*/root::::::::/' /mnt/root/etc/shadow 

Edit local.gen

> $vi /mnt/root/etc/locale.gen

    en\_US ISO-8859-1
    en\_US.UTF-8 UTF-8
    en\_GB ISO-8859-1
    en\_GB.UTF-8 UTF-8

umount..

------------------ boot ------------------

# Frodo is running

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

Temporary set up wpa\_supplicant

> vi /etc/wpa\_supplicant/wpa\_supplicant.conf

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

> rc-service wpa\_supplicant start  

No dhcp so use ifconfig and iproute

> ifconfig **** 192.168.11.99/24  
> route add default gw 192.168.11.2  

replace **** with wifi network dev

Enable sshd if need to do the rest remotely

> rc-update add sshd  
> rc-service sshd start


Sync portage

> emerge-webrsync

> eselect profile list  
> eselect locale list

emerge "base" packages I like

> emerge net-misc/dhcpcd  
> emerge net-misc/iwd

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
uncomment "option ntp\_servers"

Add fallback section with static address

Start the dhcpcd service

> rc-update add dhcpcd  
> rc-service dhcpcd


emerge "base" packages I like

> $emerge app-misc/screen<br>
> $emerge app-portage/gentoolkit

> $emerge app-editors/vim<br>
> USE=python -crypt, set in package.use subfolder

> emerge dev-vcs/git<br>
> emerge app-admin/sudo<br>
> emerge net-misc/chrony<br>

> emerge sysklogd

Set root password

> $passwd

Other packages

> $emerge alsa-lib<br>
> $emerge alsa-utils<br>
> $emerge opus<br>
> $emerge app-eselect/eselect-repository

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

## Screen resolution

Xwayland can't handle scaling so...

In Sway set output scale to 1 

    output $primary {  
        bg #002200 solid_color scale 1  
    }  

For GTK applications, set font in .config/gtk-3.0/settings.ini

  [Settings]  
    gtk-font-name=DejaVu Sans 20  


Other things are

- Update the /etc/portage/make with FEATURES="buildpkg" for the build machine
- Update USE flags
- move portage build folders onto faster more robost storage media
- check for microcode fixes and apply
- If RAM is low make tmpfiles be on disk see tmpfiles.rst
- Disable audit by setting audit=0 on kernel cmd line

