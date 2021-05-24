FROM ubuntu:latest

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/Berlin"

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y inotify-tools s-nail psmisc poppler-utils git ghostscript imagemagick
RUN git clone https://github.com/alexlenk/auto-scanner.git
RUN sed -i "s/<policy domain=\"coder\" rights=\"none\" pattern=\"PDF\" \/>/<!--<policy domain=\"coder\" rights=\"none\" pattern=\"PDF\" \/>-->/g" /etc/ImageMagick-6/policy.xml

CMD ["/auto-scanner/run.sh"]