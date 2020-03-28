#!/bin/bash

if [ ! -d /home/pi/auto-scanner ]; then
    echo "First run ..."
    first=true
    ln -s /media /volumes
fi

if [ "$first" = "true" ]; then
    if [ "$1" = "docker" ]; then
        apt-get update && apt-get upgrade -y && apt-get install -y docker-compose
    else
        apt-get update && apt-get upgrade -y && apt-get install -y inotify-tools s-nail psmisc poppler-utils git
        git clone https://github.com/alexlenk/auto-scanner.git
    fi
fi

if [ -d /home/pi/auto-scanner ]; then
    cd /home/pi/auto-scanner
    git pull
    chown -R pi:pi ../auto-scanner/
    #chmod +x *.sh
fi

cp /home/pi/auto-scanner/11-media-by-label-auto-mount.rules /etc/udev/rules.d/
udevadm control --reload-rules

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

    sed -i "s/PIDFile=\/run\/dhcpcd.pid/PIDFile=\/var\/run\/dhcpcd.pid\n/g" /etc/systemd/system/dhcpcd5.service

    rm /var/lib/systemd/random-seed
    ln -s /tmp/random-seed /var/lib/systemd/random-seed

    sed -i "s/\[Service\]/\[Service\]\nExecStartPre=\/bin\/echo \"\" >\/tmp\/random-seed/g" /etc/systemd/system/dhcpcd5.service

    systemctl daemon-reload

    sed -i "s/\/boot           vfat    defaults/\/boot           vfat    defaults,ro/g" /etc/fstab
    sed -i "s/\/               ext4    defaults,noatime/\//               ext4    defaults,noatime,ro  0       1/g" /etc/fstab
    echo "tmpfs           /tmp            tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs           /var/log        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
fi
