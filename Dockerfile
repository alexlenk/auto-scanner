FROM ubuntu

RUN apt-get update && apt-get install -y inotify-tools s-nail psmisc poppler-utils

ENTRYPOINT ["/volumes/SCANNER/run_monitor.sh"]