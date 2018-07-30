#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
    sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
    # sed -i 's/^console::/#console::/' ${TARGET_DIR}/etc/inittab
fi

if [ -e ${TARGET_DIR}/etc/init.d/S50sshd ]; then
    grep -qE 'remount' ${TARGET_DIR}/etc/init.d/S50sshd || \
    sed -e '/\/usr\/bin\/ssh-keygen \-A/i\\tif [ ! -e "/etc/ssh/ssh_host_rsa_key" ]; then\n \tmount \-o remount,rw \/' \
        -e '/\/usr\/bin\/ssh-keygen \-A/a\\tmount \-o remount,ro \/\n\tfi' \
        -i ${TARGET_DIR}/etc/init.d/S50sshd
fi

if [ -e ${TARGET_DIR}/etc/fstab ]; then
    grep -qE '/local' ${TARGET_DIR}/etc/fstab || \
    echo "/dev/mmcblk0p2   /local       ext4    rw,noauto   1   1" >> ${TARGET_DIR}/etc/fstab
fi

# Dangerous option
sed -e "s/^#PermitRootLogin .*/PermitRootLogin yes/" -i "${TARGET_DIR}/etc/ssh/sshd_config"
# Very unsafe option (dev. only, never use this in production)
sed -e "s/^#PermitEmptyPasswords .*/PermitEmptyPasswords yes/" -i "${TARGET_DIR}/etc/ssh/sshd_config"

cat >${TARGET_DIR}/etc/init.d/S95pnupd  <<EOT
#!/bin/sh

# # Sanity checks
# 
# start() {
#     printf "Starting mpd: "
#     mkdir -p /run/mpd/music /run/mpd/playlists /tmp/mpd
#     start-stop-daemon --start --quiet --background --exec /usr/bin/mpd \\
#         && echo "OK" || echo "FAIL"
# }
# 
# stop() {
#     printf "Stopping mpd: "
#     start-stop-daemon --stop --quiet --pidfile /var/run/mpd.pid \\
#         && echo "OK" || echo "FAIL"
# }
# 
# case "\$1" in
#     start)
#         start
#         ;;
#     stop)
#         stop
#         ;;
#     restart|reload)
#         stop
#         sleep 1
#         start
#         ;;
#     *)
#         echo "Usage: \$0 {start|stop|restart}"
#         exit 1
# esac
EOT
chmod +x ${TARGET_DIR}/etc/init.d/S95pnupd

mkdir -p ${TARGET_DIR}/local
rm -f ${BINARIES_DIR}/local.ext4
${HOST_DIR}/sbin/mkfs.ext4 -r 1 -N 0 -m 5 -L "local" -O ^64bit \
    ${BINARIES_DIR}/local.ext4 "512M"
