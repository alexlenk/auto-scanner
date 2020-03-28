#!/bin/bash

if [ ! -d /home/pi/scanner ]; then
    mkdir /home/pi/scanner
    first=true
fi
cp /media/SCANNER/* /home/pi/scanner
cp /media/SCANNER/.env /home/pi/scanner
chown -R pi:pi /home/pi/scanner

cp /home/pi/scanner/11-media-by-label-auto-mount.rules /etc/udev/rules.d/
udevadm control --reload-rules

if [ "first" = "true" ]; then
    if [ "$1" = "docker" ]; then
        apt-get update && apt-get upgrade -y && apt-get install -y docker-compose
    else
        apt-get update && apt-get upgrade -y && apt-get install -y inotify-tools s-nail psmisc poppler-utils

        if [ "$1" = "ro" ]; then
            apt-get remove --purge wolfram-engine triggerhappy anacron logrotate dphys-swapfile xserver-common lightdm
            apt-get autoremove --purge
            apt-get install busybox-syslogd
            dpkg --purge rsyslog
            echo `cat /boot/cmdline.txt` fastboot noswap ro > /boot/cmdline.txt
            rm -rf /var/lib/dhcp /var/lib/dhcpcd5 /var/run /var/spool /var/lock /etc/resolv.conf
            ln -s /tmp /var/lib/dhcp
            ln -s /tmp /var/lib/dhcpcd5
            ln -s /tmp /var/run
            ln -s /tmp /var/spool
            ln -s /tmp /var/lock
            touch /tmp/dhcpcd.resolv.conf
            ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

            # Edit /etc/systemd/system/dhcpcd5

            rm /var/lib/systemd/random-seed
            ln -s /tmp/random-seed /var/lib/systemd/random-seed

            # edit /lib/systemd/system/systemd-random-seed.service
    fi
fi
