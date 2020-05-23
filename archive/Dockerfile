FROM ubuntu

RUN apt-get update && apt-get install -y inotify-tools s-nail psmisc poppler-utils

ADD monitor.sh /tmp/monitor.sh
ADD upload.sh /tmp/upload.sh

ENTRYPOINT ["/tmp/monitor.sh"]