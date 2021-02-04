FROM centos:7

MAINTAINER Didier BONNEFOI <dbonnefoi@prestaconcept.net>

ARG PHP_VER=7.0.33

RUN yum clean metadata \
    && yum install -y yum-utils \
    && yum install -y http://rpm.prestaconcept.net/prestaconcept/RHEL7/presta-release-latest-7.rpm \
    && yum-config-manager --enable prestaconcept \
    && yum-config-manager --enable prestaconcept-php70 \
    && yum -y install \
    php-${PHP_VER} \
    php-bcmath \
    php-cli \
    php-curl \
    php-dba \
    php-dbg \
    php-enchant \
    php-fpm \
    php-gd \
    php-gettext \
    php-gmp \
    php-imap \
    php-intl \
    php-ldap \
    php-litespeed \
    php-mbstring \
    php-mcrypt \
    php-mysql \
    php-mssql \
    php-odbc \
    php-opcache \
    php-openssl \
    php-process \
    php-pdo \
    php-pdo_sqlite \
    php-pdo_dblib \
    php-pgsql \
    php-pspell \
    php-recode \
    php-snmp \
    php-soap \
    php-tidy \
    php-xml \
    php-xmlrpc \
    php-zip

# for now install fail with epel repo enabled
RUN yum -y install --disablerepo=epel \
    php-pecl-amqp \
    php-pecl-ast \
    php-pecl-apcu \
    php-pecl-http \
    php-pecl-imagick \
    php-pecl-lz4 \
    php-pecl-mailparse \
    php-pecl-memcached \
    php-pecl-mongodb \
    php-pecl-ssh2 \
    php-pecl-xdebug

# requires EPEL
RUN yum -y install php-pecl-maxminddb \
                   php-pecl-redis

ARG COMPOSER_VER=1.10.20
ARG COMPOSER2_VER=2.0.9

RUN yum install -y make git bash-completion openssh-clients \
    && yum install -y wkhtmltox-bundle \
    && yum install -y composer-${COMPOSER_VER} composer2-${COMPOSER2_VER} \
    && yum clean all

RUN ln -sf /usr/share/zoneinfo/Europe/Paris  /etc/localtime
ADD shared/conf/php/*.ini /etc/php.d/

# sed operations by order :
# - print daemon output to stderr to be readable from container's log
# - disable daemonize to keep php-fpm in foreground
RUN sed -e 's#^error_log = .*#error_log = /proc/self/fd/2#' \
        -e 's#daemonize = yes#daemonize = no#' \
        -i /etc/php-fpm.conf

# sed operations by order about pool www :
# - set listen to TCP socket
# - remove access restriction by IP
# - enable error output
# - remove error log, will print output to php-fpm's daemon error_log
# - enable access log, redirect to stderr to be readable from container's log
RUN sed -e 's#^listen = .*#listen = 0.0.0.0:9000#' \
        -e '/allowed_clients/d' \
        -e '/catch_workers_output/s/^;//' \
        -e '/error_log/d' \
        -e 's#^;access.log = .*#access.log = /proc/self/fd/2#' \
        -i /etc/php-fpm.d/www.conf

ADD shared/scripts/entry.sh /entry.sh
ADD shared/scripts/php_xdebug_composer.sh /php_xdebug_composer.sh

EXPOSE 9000

ENTRYPOINT [ "sh", "/entry.sh" ]

CMD [ "/usr/sbin/php-fpm" ]
