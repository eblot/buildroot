#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Set GPU memory
gpu_mem=32
sed -e "/^${gpu_mem%=*}=/s,=.*,=${gpu_mem##*=}," -i "${BINARIES_DIR}/rpi-firmware/config.txt"

echo "Adding InkRadio overlay to config.txt."
cat << __EOF__ >> "${BINARIES_DIR}/rpi-firmware/config.txt"

# add support for InkRadio peripherals
dtoverlay=hifiberry-digi-overlay
dtparam=i2c=on
dtparam=i2s=on
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
