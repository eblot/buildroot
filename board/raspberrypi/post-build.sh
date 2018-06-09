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
