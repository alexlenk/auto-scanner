#!/bin/bash

if [ ! -d /home/pi/auto-scanner ]; then
    echo "First run ..."
    first=true
    ln -s /media /volumes
    mkfifo /tmp/scannerpipe
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
fi

cp /home/pi/auto-scanner/11-media-by-label-auto-mount.rules /etc/udev/rules.d/
udevadm control --reload-rules

if [ "$1" = "ro" ]; then
    apt-get remove --purge triggerhappy logrotate dphys-swapfile
    apt-get autoremove --purge
    echo `cat /boot/cmdline.txt` fastboot noswap ro > /boot/cmdline.txt
    apt-get install busybox-syslogd
    apt-get remove --purge rsyslog

    sed -i "s/\/boot           vfat    defaults/\/boot           vfat    defaults,ro/g" /etc/fstab
    sed -i "s/\/               ext4    defaults,noatime/\//               ext4    defaults,noatime,ro  0       1/g" /etc/fstab
    echo "tmpfs        /tmp            tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/log        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/tmp        tmpfs   nosuid,nodev         0       0" >> /etc/fstab

    rm -rf /var/lib/dhcp /var/lib/dhcpcd5 /var/spool /etc/resolv.conf
    ln -s /tmp /var/lib/dhcp
    ln -s /tmp /var/lib/dhcpcd5
    ln -s /tmp /var/spool
    touch /tmp/dhcpcd.resolv.conf
    ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

    rm /var/lib/systemd/random-seed
    ln -s /tmp/random-seed /var/lib/systemd/random-seed
    sed -i "s/\[Service\]/\[Service\]\nExecStartPre=\/bin\/echo \"\" >\/tmp\/random-seed/g" /lib/systemd/system/systemd-random-seed.service

    cat >/etc/bash.bashrc <<EOL
    set_bash_prompt() {
    fs_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p")
    PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    }
    alias ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot'
    alias rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot'
    PROMPT_COMMAND=set_bash_prompt 
EOL

    echo "mount -o remount,ro /" >> /etc/bash.bash_logout
    echo "mount -o remount,ro /boot" >> /etc/bash.bash_logout
fi
