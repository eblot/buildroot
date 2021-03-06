################################################################################
#
# reaver
#
################################################################################

# Older repos for this project will not cross-compile easily
# while this one works right away
REAVER_VERSION = 9bae55bd30b6d46b42da3a09dc23c8b0f9341996
REAVER_SITE = $(call github,t6x,reaver-wps-fork-t6x,$(REAVER_VERSION))
REAVER_LICENSE = GPL-2.0+
REAVER_LICENSE_FILES = docs/LICENSE

REAVER_SUBDIR = src
REAVER_DEPENDENCIES = libpcap

$(eval $(autotools-package))
