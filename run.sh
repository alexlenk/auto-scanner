#!/bin/bash

/auto-scanner/monitor.sh /media/SCANNER/DCIM/200DOC > /volumes/STICK/auto-scanner-pdf.log &
/auto-scanner/monitor.sh /media/SCANNER/DCIM/100PHOTO > /volumes/STICK/auto-scanner-jpg.log &


while true; do 
	sleep 60
done