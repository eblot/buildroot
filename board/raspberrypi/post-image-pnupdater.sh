#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-pnupdater.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

echo "Creating PN updater overlay to config.txt."

cat << __EOF__ > "${BINARIES_DIR}/rpi-firmware/config.txt"
kernel=zImage

gpu_mem=32
framebuffer_width=960
framebuffer_height=600
disable_overscan=1

#arm_freq=1000
#gpu_freq=300
#core_freq=500
#sdram_freq=500
#sdram_schmoo=0x02000020
#over_voltage=6
#sdram_over_voltage=2

enable_uart=1

dtoverlay=dwc2
dtparam=spi=on
dtdebug=1
__EOF__

rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?

# Use pv -trbe output/images/sdcard.img | sudo dd of=/dev/sdd bs=64k oflag=sync
# to flash (replace /dev/sdd with the actual MicroSD device)