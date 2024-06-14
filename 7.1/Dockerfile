FROM centos:7

MAINTAINER Didier BONNEFOI <dbonnefoi@prestaconcept.net>

ARG PHP_VER=7.1.33

RUN yum clean metadata && yum -y update \
    && yum install -y yum-utils \
    && yum install -y http://rpm.prestaconcept.net/prestaconcept/RHEL7/presta-release-latest-7.rpm \
    && yum-config-manager --enable prestaconcept \
    && yum-config-manager --enable prestaconcept-php71 \
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
    php-pecl-pcov \
    php-pecl-ssh2 \
    php-pecl-xdebug

# requires EPEL
RUN yum -y install php-pecl-maxminddb \
                   php-pecl-redis

ARG COMPOSER2_VER=2.2.24

RUN yum install -y make git bash-completion openssh-clients \
    && yum-config-manager --enable prestaconcept-externals \
    && yum install -y wkhtmltox-0.12.6 wkhtmltox-bundle \
    && yum install -y composer22-${COMPOSER2_VER} \
    && yum clean all

RUN ln -sf /usr/share/zoneinfo/Europe/Paris  /etc/localtime
ADD shared/conf/php/*.ini /etc/php.d/

ADD shared/scripts/entry.sh /entry.sh
ADD shared/scripts/php_xdebug.sh /

EXPOSE 9000

ENTRYPOINT [ "sh", "/entry.sh" ]

CMD [ "/usr/sbin/php-fpm" ]
