WIRELESS_MENU:=Wireless Support

define KernelPackage/net-mac80211/Default
  SUBMENU:=$(WIRELESS_MENU)
  URL:=https://wireless.wiki.kernel.org/
endef

define KernelPackage/net-cfg80211
  $(call KernelPackage/net-mac80211/Default)
  TITLE:=cfg80211 - wireless configuration API
  DEPENDS+= +iw
  FILES:= $(LINUX_DIR)/net/wireless/cfg80211.ko
  KCONFIG:=CONFIG_CFG80211 \
	   CONFIG_CFG80211_INTERNAL_REGDB=y \
	   CONFIG_NL80211_TESTMODE=y \
	   CONFIG_CFG80211_DEBUGFS=y \
	   CONFIG_CFG80211_CRDA_SUPPORT=y \
     CONFIG_CFG80211_CERTIFICATION_ONUS=y \
     CONFIG_CFG80211_REQUIRE_SIGNED_REGDB=n
endef

define KernelPackage/net-cfg80211/description
cfg80211 is the Linux wireless LAN (802.11) configuration API.
endef

$(eval $(call KernelPackage,net-cfg80211))

define KernelPackage/net-mac80211
  $(call KernelPackage/net-mac80211/Default)
  TITLE:=Linux 802.11 Wireless Networking Stack
  DEPENDS+= +kmod-net-cfg80211 +hostapd-common +kmod-crypto-aead +kmod-crypto-arc4
  FILES:= $(LINUX_DIR)/net/mac80211/mac80211.ko
  MENU:=1
  KCONFIG:=CONFIG_MAC80211 \
     CONFIG_CRYPTO_ARC4 \
     CONFIG_CRYPTO_LIB_ARC4 \
	   CONFIG_MAC80211_RC_MINSTREL=y \
	   CONFIG_MAC80211_RC_MINSTREL_HT=y \
	   CONFIG_MAC80211_RC_MINSTREL_VHT=y \
	   CONFIG_MAC80211_MESH=y \
	   CONFIG_MAC80211_LEDS=y \
	   CONFIG_MAC80211_DEBUGFS=y
endef

define KernelPackage/net-mac80211/description
Generic IEEE 802.11 Networking Stack (mac80211)
endef

$(eval $(call KernelPackage,net-mac80211))

define KernelPackage/net-ath
  $(call KernelPackage/net-mac80211/Default)
  TITLE:=Atheros common driver part
  DEPENDS+= @PCI_SUPPORT||USB_SUPPORT||TARGET_ipq40xx +kmod-net-mac80211
  FILES:=$(LINUX_DIR)/drivers/net/wireless/ath/ath.ko
  KCONFIG:=CONFIG_ATH_COMMON
  MENU:=1
endef

define KernelPackage/net-ath/description
 This module contains some common parts needed by Atheros Wireless drivers.
endef

$(eval $(call KernelPackage,net-ath))

define KernelPackage/net-ath10k
  $(call KernelPackage/net-mac80211/Default)
  TITLE:=Atheros 802.11ac wireless cards support
  URL:=https://wireless.wiki.kernel.org/en/users/Drivers/ath10k
  KCONFIG:=CONFIG_ATH10K \
	   CONFIG_ATH10K_PCI \
	   CONFIG_ATH10K_AHB=y \
	   CONFIG_ATH10K_DEBUG=y \
	   CONFIG_ATH10K_DEBUGFS=y \
	   CONFIG_ATH10K_TRACING=y
  DEPENDS+= @PCI_SUPPORT +kmod-net-ath +@DRIVER_11N_SUPPORT +@DRIVER_11W_SUPPORT +@KERNEL_RELAY
  FILES:= \
        $(LINUX_DIR)/drivers/net/wireless/ath/ath10k/ath10k_core.ko \
        $(LINUX_DIR)/drivers/net/wireless/ath/ath10k/ath10k_pci.ko
  AUTOLOAD:=$(call AutoLoad,55,ath10k_core ath10k_pci)
endef

define KernelPackage/net-ath10k/description
This module adds support for wireless adapters based on
Atheros IEEE 802.11ac family of chipsets. For now only
PCI is supported.
endef

$(eval $(call KernelPackage,net-ath10k))

define KernelPackage/net-ath9k-common
  $(call KernelPackage/net-mac80211/Default)
  TITLE:=Atheros 802.11n wireless devices (common code for ath9k and ath9k_htc)
  URL:=https://wireless.wiki.kernel.org/en/users/drivers/ath9k
  KCONFIG:=ATH9K \
    ATH_CARDS \
    ATH9K_COMMON \
    ATH_DEBUG \
    ATH9K_STATION_STATISTICS
  DEPENDS+= @PCI_SUPPORT||USB_SUPPORT||TARGET_ath79 +kmod-net-ath +@DRIVER_11N_SUPPORT
  FILES:= \
	$(PKG_BUILD_DIR)/drivers/net/wireless/ath/ath9k/ath9k_common.ko \
	$(PKG_BUILD_DIR)/drivers/net/wireless/ath/ath9k/ath9k_hw.ko
endef

$(eval $(call KernelPackage,net-ath9k-common))

define KernelPackage/net-ath9k
  $(call KernelPackage/net-mac80211/Default)
  TITLE:=Atheros 802.11n PCI wireless cards support
  URL:=https://wireless.wiki.kernel.org/en/users/drivers/ath9k
  DEPENDS+= @PCI_SUPPORT||TARGET_ath79 +kmod-net-ath9k-common
  KCONFIG:=ATH9K
  FILES:= \
	$(PKG_BUILD_DIR)/drivers/net/wireless/ath/ath9k/ath9k.ko
  AUTOLOAD:=$(call AutoProbe,ath9k)
endef

define KernelPackage/net-ath9k/description
This module adds support for wireless adapters based on
Atheros IEEE 802.11n AR5008 and AR9001 family of chipsets.
endef

$(eval $(call KernelPackage,net-ath9k))
