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
    fi
fi
