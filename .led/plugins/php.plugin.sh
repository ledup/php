#!/bin/bash
_php_plugin_desc()
{
    echo "Manage PHP (memory, switch xdebug status)"
}

# get env key from a service starting with "php" or "apache"
# _php_get_service_env_key "ENV_VARIABLE"
_php_get_service_env_key()
{
  local env_var=$1

  local service_keys service_key
  local dc_key

  service_keys=$(yq -Y ".services | keys" "${dc_file}" | cut -c3-)
  for service_key in ${service_keys}
  do
    # if a service start with "php" or "apache", stop and get his env key
    if [[ "${service_key}" == php* ]] || [[ "${service_key}" == apache* ]]; then
      dc_key=".services.${service_key}.environment.${env_var}"
      break
    fi
  done

  if [ -z "${dc_key}" ]; then
    echo >&2 "Can't detect a service starting with 'apache' or 'php'"
    return 1
  fi

  echo "${dc_key}"
}

# plugin

# Plugin usage:
#   led php [options] [COMMAND]
#   led php -h|--help
#
# Commands:
#   xdebug          Manage XDebug status
#   memory          Set php memory_limit value
#
# @autocomplete php: xdebug memory
php_plugin()
{
  local command options

  command=$1
  if [[ $command == -* ]]; then
    command=""
  else
    set -- "${@:2}"
  fi

  options=( "${@}" )

  case $command in
      xdebug) php_xdebug "${options[*]}";;
      memory) php_memory "${options[*]}";;
      "") help php;;
      *) echo -e "Unknown plugin command: $command\n"; help plugin php;;
  esac
}

# xdebug
# Usage: led php xdebug [OPTIONS]
#
# Manage Xdebug status in a docker-compose file
#
# Options:
#  -e, --enable   Enable XDebug
#  -d, --disable  Disable XDebug
#
# Without option, switch XDebug status
# Each operation refresh the container
#
# @autocomplete php xdebug: --enable --disable
php_xdebug()
{
    local xdebug_operation="switch"
    local ret=
    local message=

    if ! func_exists _dockercompose_file_check 2>/dev/null; then
      echo "please upgrade LED" >&2
      return 1
    fi
    _dockercompose_file_check

    local dc_file="${LED_DOCKERCOMPOSE_FILE}"
    local dc_key=
    local dc_file_tmp=${dc_file}.tmp

    # shellcheck disable=SC2046
    set -- $(_lib_utils_get_options "de" "disable,enable" "$@")

    while [ -n "$#" ]; do
      case $1 in
          -e|--enable) xdebug_operation="enable"; shift;;
          -d|--disable) xdebug_operation="disable"; shift;;
          --) shift;break;;
      esac
    done

    if [ ! -f "${dc_file}" ]; then
      echo >&2 "${dc_file} not found"
      return 1
    fi

    if ! dc_key=$(_php_get_service_env_key "PHP_XDEBUG"); then
      return 1
    fi

    local xdebug_value=
    case ${xdebug_operation} in
        enable) xdebug_value=1;;
        disable) xdebug_value=0;;
        switch)
          xdebug_value=$(yq -r "${dc_key}" "${dc_file}")
          [ "${xdebug_value}" == "null" ] && xdebug_value=0
          # value can be 1 or 0, so substract to reverse
          xdebug_value=$((1 - xdebug_value))
          ;;
    esac


    if [ ${xdebug_value} -eq 0 ]; then
      yq -rY "del(${dc_key})" "${dc_file}" > "${dc_file_tmp}" \
      && mv "${dc_file_tmp}" "${dc_file}"
      ret=$?
      message="XDebug disabled"
    else
      yq -rY "${dc_key} = 1" "${dc_file}" > "${dc_file_tmp}" \
      && mv "${dc_file_tmp}" "${dc_file}"
      ret=$?
      message="XDebug enabled"
    fi

    # refresh container
    if [ $ret -eq 0 ]; then
      echo "${message}"
      $0 up
    fi


}

# memory
# Usage: led php memory [memory_in_MB]
#
# Manage PHP memory_limit value a docker-compose file
#
# Without value, remove entry to get container default value
# Each operation refresh the container
#
# @autocomplete php memory:
php_memory()
{

  if ! func_exists _dockercompose_file_check 2>/dev/null; then
    echo "please upgrade LED" >&2
    return 1
  fi
  _dockercompose_file_check

  local dc_file="${LED_DOCKERCOMPOSE_FILE}"
  local dc_file_tmp=${dc_file}.tmp
  local dc_key=

  local message=
  local ret=

  if [ ! -f "${dc_file}" ]; then
    echo >&2 "${dc_file} not found"
    return 1
  fi

  if ! dc_key=$(_php_get_service_env_key "PHP_MEMORY_LIMIT"); then
    return 1
  fi

  local memory=$1

  if [ -z "${memory}" ]; then
    # if no memory set, remove entry from configuration to get default container value
    yq -rY "del(${dc_key})" "${dc_file}" > "${dc_file_tmp}" \
    && mv "${dc_file_tmp}" "${dc_file}"
    ret=$?
    message="Memory limit is restored to the default value"
  else
    # if memory is set, override default container value
    if [[ ! ${memory} =~ ^[0-9]+$ ]]; then
      echo >&2 "memory value must be a number"
      return 1
    fi

    # set memory value in megabyte
    memory=${memory}M

    yq -rY "${dc_key} = \"${memory}\"" "${dc_file}" > "${dc_file_tmp}" \
    && mv "${dc_file_tmp}" "${dc_file}"
    ret=$?
    message="Memory limit fixed to ${memory}"
  fi

  # refresh container
  if [ $ret -eq 0 ]; then
    echo "${message}"
    $0 up
  fi

}
