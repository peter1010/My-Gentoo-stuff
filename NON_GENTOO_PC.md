
Create & chroot to gentoo environment on PC (if not already using Gentoo)

Hint for non-gentoo native PC:

* Download stage3-amd64-openrx-xxx.tar.xz from gentoo
* Create /mnt/gentoo
* unzip stage3 into /mnt/gentoo

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
> export PS1="(chroot) ${PS1}"
