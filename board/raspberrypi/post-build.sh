#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
    sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
    grep -qE '^console::' ${TARGET_DIR}/etc/inittab || \
    sed -i 's/^console:/#console:/' ${TARGET_DIR}/etc/inittab
fi

if [ -e ${TARGET_DIR}/etc/init.d/S50sshd ]; then
    grep -qE 'remount' ${TARGET_DIR}/etc/init.d/S50sshd || \
    sed -e '/\/usr\/bin\/ssh-keygen \-A/i\\tif [ ! -e "/etc/ssh/ssh_host_rsa_key" ]; then\n \tmount \-o remount,rw \/' \
        -e '/\/usr\/bin\/ssh-keygen \-A/a\\tmount \-o remount,ro \/\n\tfi' \
        -i ${TARGET_DIR}/etc/init.d/S50sshd
fi

if [ -e ${TARGET_DIR}/etc/fstab ]; then
    grep -qE '/config' ${TARGET_DIR}/etc/fstab || \
    echo "/dev/mmcblk0p1   /config       ext4    rw,noauto   1   1" >> ${TARGET_DIR}/etc/fstab
fi

if [ -e ${TARGET_DIR}/etc/network/interfaces ]; then
    grep -qE '^auto wlan0' ${TARGET_DIR}/etc/init.d/S50sshd || \
    cat >>${TARGET_DIR}/etc/network/interfaces <<EOT

auto wlan0
iface wlan0 inet dhcp
        pre-up wpa_supplicant -iwlan0 -c/etc/wpa_supplicant.conf -B
        up iw wlan0 set power_save off
        down killall wpa_supplicant
EOT
fi

cat >>${TARGET_DIR}/etc/ssh/sshd_config  <<EOT
# Very dangerous options to be removed as soon as dev. is completed
PermitRootLogin yes
PermitEmptyPasswords yes
EOT

cat >${TARGET_DIR}/etc/init.d/S91mpd  <<EOT
#!/bin/sh

# Sanity checks
test -f /etc/mpd.conf || exit 0

start() {
    mkdir -p /run/mpd/music /run/mpd/playlists
    mkdir -p /tmp/mpd
    printf "Starting mpd: "
    start-stop-daemon --start --quiet --background --exec /usr/bin/mpd \
        && echo "OK" || echo "FAIL"
}

stop() {
    printf "Stopping mpd: "
    start-stop-daemon --stop --quiet --pidfile /var/run/mpd.pid \
        && echo "OK" || echo "FAIL"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart|reload)
        stop
        sleep 1
        start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
EOT
chmod +x ${TARGET_DIR}/etc/init.d/S91mpd

cat >${TARGET_DIR}/etc/mpd.conf  <<EOT
# Directory where the music is stored
music_directory      "/run/mpd/music"

# Directory where user-made playlists are stored (RW)
playlist_directory   "/run/mpd/playlists"

# Database file (RW)
db_file              "/run/mpd/database"

# Log file (RW)
log_file             "/tmp/mpd.log"

# Process ID file (RW)
pid_file             "/run/mpd.pid"

# State file (RW)
state_file           "/run/mpd/state"

# User id to run the daemon as
#user                "nobody"

# TCP socket binding
bind_to_address      "localhost"

# Unix socket to listen on
bind_to_address      "/run/mpd/socket"
EOT

cat >${TARGET_DIR}/etc/init.d/S92inkradio  <<EOT
#!/bin/sh

start() {
    printf "Starting inkradio: "
    start-stop-daemon --start --background --verbose \
            --pidfile /var/run/inkradio.pid \
            --make-pidfile \
            --exec /usr/bin/python3 /usr/local/bin/inkradio.py \
        && echo "OK" || echo "FAIL"
}

stop() {
    printf "Stopping inkradio: "
    start-stop-daemon --stop \
        --pidfile /var/run/inkradio.pid \
        --remove-pidfile \
        && echo "OK" || echo "FAIL"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart|reload)
        stop
        sleep 1
        start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
EOT
chmod +x ${TARGET_DIR}/etc/init.d/S92inkradio

mkdir -p ${TARGET_DIR}/config
rm -f ${BINARIES_DIR}/config.ext4
${HOST_DIR}/sbin/mkfs.ext4 -r 1 -N 0 -m 5 -L "config" -O ^64bit \
    ${BINARIES_DIR}/config.ext4 "2M"
