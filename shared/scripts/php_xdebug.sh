#!/bin/env bash
xdebug_file=$(php --ini | grep -F 'xdebug.ini' | tr -d ',')
if [ -n "${xdebug_file}" ]; then
cat <<EOF
## XDebug stuff ##
function xdebug_enable() {
  su - -c "sed -i 's/^;\(zend_extension\)/\1/' ${xdebug_file}"
}

function xdebug_disable() {
  su - -c "sed -i 's/^\(zend_extension\)/;\1/' ${xdebug_file}"
}

function php_noxdebug() {
  local PHP=\$(type -P php)

  xdebug_disable && \$PHP "\$@"
  local STATUS=\$?

  # re-enable xdebug if wanted by the user
  [ "\${PHP_XDEBUG}" == "1" ] && xdebug_enable

  return \$STATUS

}

function php_xdebug() {
  local PHP=\$(type -P php)

  xdebug_enable && \$PHP "\$@"
  local STATUS=\$?

  # disable xdebug if not wanted by the user
  [ "\${PHP_XDEBUG}" != "1" ] && xdebug_disable

  return \$STATUS
}

EOF
fi
