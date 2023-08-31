
SHELL=/bin/bash

/boot/initramfs.cpio.gz : initramfs.cpio
	@echo "Compressing to boot partition"
	gzip --best -c $< > $@

initramfs.cpio : initramfs_list init.sh
	@echo "Creating the cpio"
	cd ../linux && ./usr/gen_init_cpio ../initramfs/$< > ../initramfs/$@


.PHONY: BootMount
BootMount:
	@echo "Mounting the boot partition"
	mount /boot


%:: BootMount
	:


.PHONY: all
all: /boot/initramfs.cpio.gz

