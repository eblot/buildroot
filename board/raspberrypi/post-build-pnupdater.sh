#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
    sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
    grep -qE '^ttyGS0::' ${TARGET_DIR}/etc/inittab || \
    sed -i '/GENERIC_SERIAL/a\
ttyGS0::respawn:/sbin/getty -L  ttyGS0 0 vt100 # USB gadget console' ${TARGET_DIR}/etc/inittab
    # sed -i 's/^console::/#console::/' ${TARGET_DIR}/etc/inittab
fi

if [ -e ${TARGET_DIR}/etc/init.d/S50sshd ]; then
    grep -qE 'remount' ${TARGET_DIR}/etc/init.d/S50sshd || \
    sed -e '/\/usr\/bin\/ssh-keygen \-A/i\\tif [ ! -e "/etc/ssh/ssh_host_rsa_key" ]; then\n \tmount \-o remount,rw \/' \
        -e '/\/usr\/bin\/ssh-keygen \-A/a\\tmount \-o remount,ro \/\n\tfi' \
        -i ${TARGET_DIR}/etc/init.d/S50sshd
fi

if [ -e ${TARGET_DIR}/etc/fstab ]; then
    # USB mass storage as VFAT
    grep -qE '/usbms' ${TARGET_DIR}/etc/fstab || \
    echo "/dev/mmcblk0p2	/usbms	vfat	rw,nouto,sync	1	1" >> ${TARGET_DIR}/etc/fstab
    # Application partition as EXT4, should be mount as RO for production
    grep -qE '/local' ${TARGET_DIR}/etc/fstab || \
    echo "/dev/mmcblk0p4	/local	ext4	rw	1	1" >> ${TARGET_DIR}/etc/fstab
fi

# Dangerous option
sed -e "s/^#PermitRootLogin .*/PermitRootLogin yes/" -i "${TARGET_DIR}/etc/ssh/sshd_config"
# Very unsafe option (dev. only, never use this in production)
sed -e "s/^#PermitEmptyPasswords .*/PermitEmptyPasswords yes/" -i "${TARGET_DIR}/etc/ssh/sshd_config"

# 256M EXT4 partition to store application (to be decrease for prod)
mkdir -p ${TARGET_DIR}/local
rm -f ${BINARIES_DIR}/local.ext4
${HOST_DIR}/sbin/mkfs.ext4 -r 1 -N 0 -m 5 -L "local" -O ^64bit \
    ${BINARIES_DIR}/local.ext4 "256M"

# 64M VFAT partition to store USB mass storage file (such as PN firmwares)
mkdir -p ${TARGET_DIR}/usbms
rm -f ${BINARIES_DIR}/usbms.vfat
dd if=/dev/zero of=${BINARIES_DIR}/usbms.vfat bs=1024 count=65536
${HOST_DIR}/sbin/mkfs.vfat -n "PnUpdater" ${BINARIES_DIR}/usbms.vfat
