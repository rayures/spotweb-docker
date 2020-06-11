FROM ubuntu:latest

ENV DEBIAN_FRONTEND="noninteractive" \
    TERM="xterm" \
    APTLIST="\
    apache2 \
    php \
    php-curl\
    php-gd \
    php-mysql \
    php-pgsql \
    php-sqlite3 \
    php-xml \
    php-xmlrpc \
    php-mbstring \
    php-zip \
    git-core \
    cron \
    wget \
    jq"

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup &&\
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -q update && \
    apt-get -qy dist-upgrade && \
    apt-get install -qy $APTLIST && \
    \
    # Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -r /var/www/html && \
    rm -rf /tmp/*

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh

COPY ./000-default.conf /etc/apache2/sites-enabled/000-default.conf

# Add caching and compression config to .htaccess, move later in via entrypoint
COPY ./001-htaccess.conf /001-htaccess.conf

VOLUME [ "/config" ]

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
