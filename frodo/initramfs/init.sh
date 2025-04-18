#!/bin/busybox sh

echo "Rescue shell"

/bin/busybox mkdir -p /usr/bin /usr/sbin /sbin
/bin/busybox --install -s

/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys

exec /bin/sh
