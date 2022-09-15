#!/bin/bash

##### User management #####

# Remove root password
usermod -p "" root

# Add local user
# Either use the _UID if passed in at runtime or fallback
USER_ID=${_UID:-9001}
USER="dev"
useradd --shell /bin/bash -u "${USER_ID}" -o -c "" -m ${USER}
# put user 'dev' into apache group, for php sessions
gpasswd -a ${USER} apache >/dev/null

if [ -f "/mnt/host/.gitconfig" ];then
    su - ${USER} -c "cp -a /mnt/host/.gitconfig ~/.gitconfig"
fi

if [ -d "/mnt/host/.ssh" ];then
    su - ${USER} -c "cp -a /mnt/host/.ssh ~/.ssh"
    # if not using existing ssh agent socket, fallback with a local agent
    if [ ! -S "${SSH_AUTH_SOCK}" ]; then
      # avoid multiple ssh-agent launch
      su - ${USER} -c "echo '[ ! -f /tmp/ssh.agent ] && ssh-agent -s > /tmp/ssh.agent ; . /tmp/ssh.agent > /dev/null' >> ~/.bashrc"
    fi
fi

##### PHP configuration #####

# commented in php-fpm pool, will be grabbed from this global configuration

PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-8096M}
sed -i "s#\(memory_limit = \).*#\1${PHP_MEMORY_LIMIT}#g" /etc/php.d/php-default.ini

## XDebug enable/disable ##

# detect xdebug configuration file
xdebug_file=$(php --ini | grep -F 'xdebug.ini' | tr -d ',')
if [ -f "${xdebug_file}" ]; then
  # enable if wanted
  if [ "${PHP_XDEBUG}" == "1" ]; then
    sed -i 's/^;\(zend_extension\)/\1/' "${xdebug_file}"
  else
    # or disable
    sed -i 's/^\(zend_extension\)/;\1/' "${xdebug_file}"
  fi
fi

su - ${USER} -c "source /php_xdebug.sh  >> ~/.bashrc"

##### PHP-FPM configuration #####

# sed operations by order:
# - print daemon output to stderr to be readable from container's log
# - disable daemonize to keep php-fpm in foreground
sed -e 's#^error_log = .*#error_log = /proc/self/fd/2#' \
    -e 's#daemonize = yes#daemonize = no#' \
    -i /etc/php-fpm.conf

# sed operations by order about pool www:
# - set listen to TCP socket
# - remove access restriction by IP
# - enable error output
# - remove error log, will print output to php-fpm's daemon error_log
# - enable access log, redirect to stderr to be readable from container's log
# - change user/group
sed -e 's#^listen = .*#listen = 0.0.0.0:9000#' \
    -e '/allowed_clients/d' \
    -e '/catch_workers_output/s/^;//' \
    -e '/error_log/d' \
    -e 's#^;access.log = .*#access.log = /proc/self/fd/2#' \
    -e "s#^user = .*#user = ${USER}#" \
    -e "s#^group = .*#group = ${USER}#" \
    -i /etc/php-fpm.d/www.conf

# add Composer completion if provided
if ! composer completion bash > /etc/bash_completion.d/composer 2>/dev/null; then
  rm /etc/bash_completion.d/composer
fi
# use exec to avoid subshell
exec "$@"
