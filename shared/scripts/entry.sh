#!/bin/bash

##### User management #####

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${_UID:-9001}

# Remove root password
usermod -p "" root

useradd --shell /bin/bash -u $USER_ID -o -c "" -m dev

# put user 'dev' into apache group, for php sessions
gpasswd -a dev apache >/dev/null

export HOME=/home/dev

if [ -f /mnt/host/.gitconfig ];then
    cp -a /mnt/host/.gitconfig /home/dev/.gitconfig
    chown dev:dev /home/dev/.gitconfig
fi

if [ -d /mnt/host/.ssh ];then
    cp -a /mnt/host/.ssh /home/dev/.ssh

    chown -R dev:dev /home/dev/.ssh
    chmod 600 /home/dev/.ssh/*

    echo "ssh-agent -s > /tmp/ssh.agent ; . /tmp/ssh.agent > /dev/null" >> /home/dev/.bashrc
fi

##### PHP configuration #####
# commented in php-fpm pool, will be grabbed from this global configuration

PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-8096M}
sed -i "s#\(memory_limit = \).*#\1${PHP_MEMORY_LIMIT}#g" /etc/php.d/php-default.ini

## XDebug enable/disable ##

# detect xdebug configuration file
xdebug_file=$(php --ini | grep -F 'xdebug.ini' | tr -d ',')

# enable if wanted
if [ "${PHP_XDEBUG}" == "1" ]; then
  sed -i 's/^;\(zend_extension\)/\1/' "${xdebug_file}"
else
  # or disable
  sed -i 's/^\(zend_extension\)/;\1/' "${xdebug_file}"
fi

bash /php_xdebug_composer.sh >> "${HOME}/.bashrc"

##### PHP-FPM configuration #####
# change php-fpm pool UID/GID
PHPFPM_USER=dev
sed -i "s#^user = .*#user = ${PHPFPM_USER}#" /etc/php-fpm.d/www.conf
sed -i "s#^group = .*#group = ${PHPFPM_USER}#" /etc/php-fpm.d/www.conf

# use exec to avoid subshell
exec "$@"
