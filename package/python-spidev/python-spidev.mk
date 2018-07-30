################################################################################
#
# python-spidev
#
################################################################################

PYTHON_SPIDEV_VERSION = 3.3
# PYTHON_SPIDEV_SOURCE = py-spidev-$(PYTHON_SPIDEV_VERSION).tar.gz
PYTHON_SPIDEV_SITE = $(call github,doceme,py-spidev,v$(PYTHON_SPIDEV_VERSION))
PYTHON_SPIDEV_SETUP_TYPE = distutils
PYTHON_SPIDEV_LICENSE = GPL-2.0
PYTHON_SPIDEV_LICENSE_FILES = LICENSE.md

$(eval $(python-package))
