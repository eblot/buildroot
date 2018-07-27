#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Set GPU memory (can go lower without losing other features...)
gpu_mem=32
sed -e "/^${gpu_mem%=*}=/s,=.*,=${gpu_mem##*=}," -i "${BINARIES_DIR}/rpi-firmware/config.txt"

echo "Adding PN updater overlay to config.txt."
cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

framebuffer_width=960
framebuffer_height=600
arm_freq=1000
gpu_freq=300
core_freq=500
sdram_freq=500
sdram_schmoo=0x02000020
over_voltage=6
sdram_over_voltage=2

# add support for PN updater peripherals
# dtoverlay=
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
