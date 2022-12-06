DTS_DIR := $(DTS_DIR)/mediatek

ifdef CONFIG_LINUX_5_4
  KERNEL_LOADADDR := 0x44080000
else
  KERNEL_LOADADDR := 0x44000000
endif

define Image/Prepare
	# For UBI we want only one extra block
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/buffalo-kernel-trx
	$(eval magic=$(word 1,$(1)))
	$(eval dummy=$(word 2,$(1)))
	$(eval kern_size=$(if $(KERNEL_SIZE),$(KERNEL_SIZE),0x400000))

	$(if $(dummy),touch $(dummy))
	$(STAGING_DIR_HOST)/bin/otrx create $@.new \
		$(if $(magic),-M $(magic),) \
		-f $@ \
		$(if $(dummy),\
			-a 0x20000 \
			-b $$(( $(subst k, * 1024,$(kern_size)) )) \
			-f $(dummy),)
	mv $@.new $@
endef

define Build/bl2
	cat $(STAGING_DIR_IMAGE)/mt7622-$1-bl2.img >> $@
endef

define Build/bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7622_$1-u-boot.fip >> $@
endef

define Build/mt7622-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		$(if $(findstring sdmmc,$1), \
			-H \
			-t 0x83	-N bl2		-r	-p 512k@512k \
		) \
			-t 0xef	-N fip		-r	-p 2M@2M \
			-t 0x83	-N ubootenv	-r	-p 1M@4M \
				-N recovery	-r	-p 32M@6M \
		$(if $(findstring sdmmc,$1), \
				-N install	-r	-p 7M@38M \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@45M \
		) \
		$(if $(findstring emmc,$1), \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@40M \
		)
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Build/trx-nand
	# kernel: always use 4 MiB (-28 B or TRX header) to allow upgrades even
	#	  if it grows up between releases
	# root: UBI with one extra block containing UBI mark to trigger erasing
	#	rest of partition
	$(STAGING_DIR_HOST)/bin/otrx create $@.new \
		-M 0x32504844 \
		-f $(IMAGE_KERNEL) -a 0x20000 -b 0x400000 \
		-f $@ \
		-A $(KDIR)/ubi_mark -a 0x20000
	mv $@.new $@
endef

define Device/bananapi_bpi-r64
  DEVICE_VENDOR := Bananapi
  DEVICE_MODEL := BPi-R64
  DEVICE_DTS := mt7622-bananapi-bpi-r64
  DEVICE_PACKAGES := kmod-ata-ahci-mtk kmod-btmtkuart kmod-usb3 e2fsprogs mkf2fs f2fsck
  ARTIFACTS := emmc-preloader.bin emmc-bl31-uboot.fip sdcard.img.gz snand-preloader.bin snand-bl31-uboot.fip
  IMAGES := sysupgrade.itb
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  ARTIFACT/emmc-preloader.bin	:= bl2 emmc-2ddr
  ARTIFACT/emmc-bl31-uboot.fip	:= bl31-uboot bananapi_bpi-r64-emmc
  ARTIFACT/snand-preloader.bin	:= bl2 snand-2ddr
  ARTIFACT/snand-bl31-uboot.fip	:= bl31-uboot bananapi_bpi-r64-snand
  ARTIFACT/sdcard.img.gz	:= mt7622-gpt sdmmc |\
				   pad-to 512k | bl2 sdmmc-2ddr |\
				   pad-to 2048k | bl31-uboot bananapi_bpi-r64-sdmmc |\
				$(if $(CONFIG_TARGET_ROOTFS_INITRAMFS),\
				   pad-to 6144k | append-image-stage initramfs-recovery.itb | check-size 38912k |\
				) \
				   pad-to 38912k | mt7622-gpt emmc |\
				   pad-to 39424k | bl2 emmc-2ddr |\
				   pad-to 40960k | bl31-uboot bananapi_bpi-r64-emmc |\
				   pad-to 43008k | bl2 snand-2ddr |\
				   pad-to 43520k | bl31-uboot bananapi_bpi-r64-snand |\
				$(if $(CONFIG_TARGET_ROOTFS_SQUASHFS),\
				   pad-to 46080k | append-image squashfs-sysupgrade.itb | check-size | gzip \
				)
  IMAGE_SIZE := $$(shell expr 45 + $$(CONFIG_TARGET_ROOTFS_PARTSIZE))m
  KERNEL			:= kernel-bin | gzip
  KERNEL_INITRAMFS		:= kernel-bin | lzma | fit lzma $$(DTS_DIR)/$$(DEVICE_DTS).dtb with-initrd | pad-to 128k
  IMAGE/sysupgrade.itb		:= append-kernel | fit gzip $$(DTS_DIR)/$$(DEVICE_DTS).dtb external-static-with-rootfs | append-metadata
endef
TARGET_DEVICES += bananapi_bpi-r64
