# auto-scanner

In the persuit of a paperless filing solution I ended up buying a Brother DS-920dw document scanner. Unfortunately this scanner comes with no online storage, so I attached a headless and read-only Raspberry Pi (RPi) in order to detect changes in the scanners document store and upload them to the online file storage solution fileee.

The script has the following features:
* Any documents that are scanned within a short amount of time get merged
* JPG scans get cleaned and converted to PDF before sending them

# Setup
Brother DS-920dw with a SD-Card called "SCANNER" connected via USB to a Raspberry Pi with a USB stick called "STICK". The names of the storage devices are important for the script to find the disks.
* Use etcher or your prefered solution to create a new RPi SD Card
* Make RPi headless
  * Create an empty file called "ssh" boot folder
  * Create a [proper wpa_supplicant.conf file](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md) and place it in the boot folder
* Download the setup_rpi.sh file from this repo and place it in the boot folder
* Login to the RPi and execute the setup_rpi.sh file: sudo /boot/setup_rpi.sh
* Place a .env file on the scanners SD card with the following content:
  * SMTP_SERVER=
  * SMTP_USER=
  * SMTP_PASS=
  * TO_MAIL=
  * FROM_MAIL=
  
  I am using an Ionos SMTP server to send the documents to the fileee private email.
