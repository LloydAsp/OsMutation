#!/bin/sh
set -e

TO=/x
OLD_INIT=$(readlink /proc/1/exe)
cd "$TO"

if [ ! -e fakeinit ]; then
    ./busybox echo "Please compile fakeinit.c first"
    exit 1
fi


./busybox echo "Setting up target filesystem..."
./busybox rm -f etc/mtab
./busybox ln -s /proc/mounts etc/mtab
./busybox mkdir -p oldroot

./busybox echo "Mounting pseudo-filesystems..."
./busybox mount -t tmpfs tmp tmp
./busybox mount -t proc proc proc
./busybox mount -t sysfs sys sys
if ! ./busybox mount -t devtmpfs dev dev; then
    ./busybox mount -t tmpfs dev dev
    ./busybox cp -a /dev/* dev/
    ./busybox rm -rf dev/pts
    ./busybox mkdir dev/pts
fi
./busybox mount --bind /dev/pts dev/pts

TTY="$(./busybox tty)"

./busybox echo "Checking and switching TTY..."

exec <"$TO/$TTY" >"$TO/$TTY" 2>"$TO/$TTY"

./busybox echo "Preparing init..."
./busybox cat >tmp/${OLD_INIT##*/} <<EOF
#!${TO}/busybox sh

exec <"${TO}/${TTY}" >"${TO}/${TTY}" 2>"${TO}/${TTY}"
cd "${TO}"

./busybox echo "Init takeover successful"
./busybox echo "Pivoting root..."
./busybox mount --make-rprivate /
./busybox pivot_root . oldroot
./busybox echo "Chrooting and running init..."
exec ./busybox chroot . /fakeinit
EOF
./busybox chmod +x tmp/${OLD_INIT##*/}


./busybox echo "About to take over init. This script will now pause for a few seconds."
./busybox echo "If the takeover was successful, you will see output from the new init."
./busybox echo "You may then kill the remnants of this session and any remaining"

./busybox mount --bind tmp/${OLD_INIT##*/} ${OLD_INIT}

telinit u

./busybox sleep 5