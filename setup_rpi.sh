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
        apt-get update && apt-get upgrade -y && apt-get install -y inotify-tools s-nail psmisc poppler-utils git ghostscript imagemagick
        git clone https://github.com/alexlenk/auto-scanner.git
    fi
fi

if [ -d /home/pi/auto-scanner ]; then
    cd /home/pi/auto-scanner
    git pull
    chown -R pi:pi ../auto-scanner/
fi

#cp /home/pi/auto-scanner/11-media-by-label-auto-mount.rules /etc/udev/rules.d/
#udevadm control --reload-rules

apt-get remove -y --purge triggerhappy logrotate dphys-swapfile
apt-get autoremove -y --purge
apt-get install -y busybox-syslogd
apt-get remove -y --purge rsyslog

mkdir /media/STICK
echo "/dev/sda1        /media/STICK        ext4   defaults         0       0" >> /etc/fstab

if [ "$1" = "ro" ]; then
    sed -i "s/\/boot           vfat    defaults/\/boot           vfat    defaults,ro/g" /etc/fstab
    sed -i "s/\/               ext4    defaults,noatime/\/               ext4    defaults,noatime,ro/g" /etc/fstab
    echo "tmpfs        /tmp            tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/log        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/tmp        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/lib/dhcp        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/lib/dhcpcd5        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo "tmpfs        /var/spool        tmpfs   nosuid,nodev         0       0" >> /etc/fstab
    echo `cat /boot/cmdline.txt` fastboot noswap ro > /boot/cmdline.txt
    
    rm -rf /var/lib/dhcp /var/lib/dhcpcd5 /var/spool /etc/resolv.conf
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

    cat >/lib/systemd/system/auto-scanner.service <<EOL
[Unit]
Description=Alex Auto Scanner for PDF
After=multi-user.target

[Service]
Type=idle
ExecStart=/home/pi/auto-scanner/monitor.sh /volumes/SCANNER/DCIM/200DOC
Restart=always
StandardOutput=file:/tmp/auto-scanner-pdf.log
StandardError=file:/tmp/auto-scanner-pdf.log

[Install]
WantedBy=multi-user.target
EOL

cat >/lib/systemd/system/auto-scanner-img.service <<EOL
[Unit]
Description=Alex Auto Scanner for Images
After=multi-user.target

[Service]
Type=idle
ExecStart=/home/pi/auto-scanner/monitor.sh /volumes/SCANNER/DCIM/100PHOTO
Restart=always
StandardOutput=file:/tmp/auto-scanner-jpg.log
StandardError=file:/tmp/auto-scanner-jpg.log

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    systemctl enable auto-scanner.service
    systemctl enable auto-scanner-img.service

