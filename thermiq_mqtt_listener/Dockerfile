ARG BUILD_FROM=ghcr.io/hassio-addons/base:17.2.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

RUN apk --no-cache add php84 php84-dev php84-fpm php84-mysqli php84-opcache php84-gd zlib php84-curl php84-phar php84-mbstring php84-zip php84-pdo php84-pdo_mysql php84-iconv php84-dom php84-session php84-intl php84-soap php84-fileinfo php84-xml php84-ctype php84-pecl-xdebug php84-pdo_sqlite php84-tokenizer php84-exif php84-xmlwriter php84-cgi php84-simplexml
RUN apk --no-cache add \
    php84-simplexml \
    php84-gd \
    php84-json \
    php84-imap \
    php84-apcu
RUN apk --no-cache add mosquitto mosquitto-dev
RUN apk --no-cache add mariadb-client
RUN apk --no-cache add ffmpeg

#musl-locales/php-locales
RUN apk add --no-cache cmake make musl-dev gcc gettext-dev libintl
RUN wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
    && cd musl-locales-master \
    && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
    && cd .. && rm -r musl-locales-master



# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh


# Directory structure for ThermIQ

RUN mkdir -p /share/thermiq/etc
RUN mkdir -p /tmp/thermiq_install
RUN mkdir -p /opt/bin

# Configure php path for scripts
RUN cd /opt/bin && ln -sf /usr/bin/php84 php
ENV PATH="$PATH:/share/thermiq:/opt/bin"

RUN cd /opt/ && ln -sf /share/thermiq/etc

CMD [ "/run.sh" ]
