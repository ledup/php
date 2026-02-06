FROM rockylinux/rockylinux:9.7

LABEL org.opencontainers.image.authors="Didier BONNEFOI <dbonnefoi@prestaconcept.net>"

ARG PHP_MAJOR=7.4
ENV ACCEPT_EULA=Y

RUN dnf clean metadata && dnf update -y \
    && dnf install -y yum-utils https://rpms.remirepo.net/enterprise/remi-release-9.rpm \
    && dnf module -y reset php \
    && dnf module -y install php:remi-${PHP_MAJOR} \
    && crb enable \
    && curl https://packages.microsoft.com/config/rhel/9/prod.repo -o /etc/yum.repos.d/mssql-release.repo

RUN dnf install -y \
    php-bcmath \
    php-cli \
    php-curl \
    php-dba \
    php-dbg \
    php-enchant \
    php-fpm \
    php-ffi \
    php-gd \
    php-gettext \
    php-gmp \
    php-imap \
    php-intl \
    php-ldap \
    php-litespeed \
    php-mbstring \
    php-mysqlnd \
    php-odbc \
    php-opcache \
    php-openssl \
    php-process \
    php-pdo \
    php-pdo-dblib \
    php-pdo-firebird \
    php-pgsql \
    php-pspell \
    php-snmp \
    php-soap \
    php-sodium \
    php-tidy \
    php-xml

RUN dnf install -y php-pecl-apcu \
    php-pecl-amqp \
    php-pecl-ast \
    php-pecl-http \
    php-pecl-imagick-im7 \
    php-lz4 \
    php-pecl-mailparse \
    php-pecl-memcached \
    php-pecl-maxminddb \
    php-pecl-mongodb \
    php-pecl-pcov \
    php-pecl-redis \
    php-sqlsrv \
    php-pecl-ssh2 \
    php-pecl-xdebug \
    php-pecl-zip

RUN dnf module install -y composer:2

RUN dnf install -y make git bash-completion openssh-clients patch unzip p7zip p7zip-plugins \
    && dnf config-manager --add-repo https://rpm.prestaconcept.net/externals/presta-rhel-externals.repo \
    && dnf install -y --enablerepo prestaconcept-externals wkhtmltox liberation*fonts \
    && dnf install -y curl libcurl --allowerasing \
    && dnf install -y jpegoptim optipng pngquant gifsicle libwebp-tools libavif-tools \
    && dnf clean all

RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN mkdir /run/php-fpm

ADD shared/conf/php/*.ini /etc/php.d/

ADD shared/scripts/entry.sh /entry.sh
ADD shared/scripts/php_xdebug.sh /

EXPOSE 9000

ENTRYPOINT [ "sh", "/entry.sh" ]

CMD [ "/usr/sbin/php-fpm" ]
