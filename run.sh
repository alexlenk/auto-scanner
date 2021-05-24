#!/bin/bash

sleep 5

/auto-scanner/monitor.sh /media/SCANNER/DCIM/200DOC & > /media/STICK/auto-scanner-pdf.log
/auto-scanner/monitor.sh /media/SCANNER/DCIM/100PHOTO & > /media/STICK/auto-scanner-jpg.log