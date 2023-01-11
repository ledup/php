#!/bin/bash
_php_plugin_desc()
{
    echo "Manage PHP (memory, switch xdebug status)"
}

# get env key from a service starting with "php" or "apache"
# _php_get_service_key "ENV_VARIABLE"
_php_get_service_key()
{
  local service_key=$1
  local service_value=$2

  local services service
  local dc_key

  services=$(${VENDORS_BIN_JYPARSER}  "${dc_file}" get ".services | keys" | cut -c3-)
  for service in ${services}
  do
    # if a service start with "php" or "apache", stop and get his env key
    if [[ "${service}" == php* ]] || [[ "${service}" == apache* ]]; then
      dc_key=".services.${service}.${service_key}"

      if [ ! -z "${service_value}" ]; then
        dc_key="${dc_key}.${service_value}"
      fi

      break
    fi
  done

  if [ -z "${dc_key}" ]; then
    echo >&2 "Can't detect a service starting with 'apache' or 'php'"
    exit 1
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

  # ensure constant for jyparser is available
  if [ -z "${VENDORS_BIN_JYPARSER}" ]; then
    echo "This plugin cannot work with this version of led, please upgrade"
    exit 1
  fi

  case $command in
      xdebug) php_xdebug "${options[*]}";;
      memory) php_memory "${options[*]}";;
      "") help plugin php;;
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
      exit 1
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
      exit 1
    fi

    if ! dc_xdebug_key=$(_php_get_service_key "environment" "PHP_XDEBUG"); then
      exit 1
    fi

    local xdebug_value=
    case ${xdebug_operation} in
        enable) xdebug_value=1;;
        disable) xdebug_value=0;;
        switch)
          xdebug_value=$(${VENDORS_BIN_JYPARSER} "${dc_file}" get "${dc_xdebug_key}")
          [ "${xdebug_value}" == "null" ] && xdebug_value=0
          # value can be 1 or 0, so substract to reverse
          xdebug_value=$((1 - xdebug_value))
          ;;
    esac

    local dc_xdebug_value=$(${VENDORS_BIN_JYPARSER} "${dc_file}" get "${dc_xdebug_key}")
    if [ ${xdebug_value} -eq 0 ]; then
      _check_xdebug_state ${dc_xdebug_value} ${xdebug_value}

      ${VENDORS_BIN_JYPARSER} "${dc_file}" del "${dc_xdebug_key}" > "${dc_file_tmp}" \
      && mv "${dc_file_tmp}" "${dc_file}"
      _disable_debugger
      ret=$?
      message="XDebug disabled"
    else
      _check_xdebug_state ${dc_xdebug_value} ${xdebug_value}

      ${VENDORS_BIN_JYPARSER} "${dc_file}" set "${dc_xdebug_key}" 1 > "${dc_file_tmp}" \
      && mv "${dc_file_tmp}" "${dc_file}"
      _enable_debugger
      ret=$?
      message="XDebug enabled"
    fi

    # refresh container
    if [ $ret -eq 0 ]; then
      echo "${message}"
#      $0 up
    fi
}

_enable_debugger()
{
    local phpstorm_ip
    local plugin_dir="$(_plugin_files_dir "php")"
    local origin_xdebug_config_file="${plugin_dir}/90-xdebug-config.ini"
    local dc_volumes_key=$(_php_get_service_key "volumes")
    local dc_ide_config_key=$(_php_get_service_key "environment" "PHP_IDE_CONFIG")
    local dc_volumes_length
    local dc_xdebug_env_value

    if [[ -f "${origin_xdebug_config_file}" ]]; then
      target_xdebug_config=".led/90-xdebug-config.ini"

      #get the ip of docker network
      phpstorm_ip=$(docker network inspect bridge | jq -r '.[].IPAM.Config[].Gateway')
      #put it into xdebug config file
      sed "s/DOCKER_IP/${phpstorm_ip}/" "${origin_xdebug_config_file}" > "${target_xdebug_config}"
      dc_xdebug_env_value="${target_xdebug_config}:/etc/php.d/90-xdebug-config.ini"

      dc_volumes_length=$(${VENDORS_BIN_JYPARSER} "${dc_file}" get "${dc_volumes_key} | length")
      #edit docker-compose file
      ${VENDORS_BIN_JYPARSER} "${dc_file}" set "${dc_volumes_key}[${dc_volumes_length}]" \"${dc_xdebug_env_value}\" > "${dc_file_tmp}" \
      && mv "${dc_file_tmp}" "${dc_file}"
      ${VENDORS_BIN_JYPARSER} "${dc_file}" set "${dc_ide_config_key}" \"serverName=localhost\" > "${dc_file_tmp}" \
      && mv "${dc_file_tmp}" "${dc_file}"
    fi
}

_disable_debugger()
{
    local dc_volumes_key=$(_php_get_service_key "volumes")
    local dc_ide_config_key=$(_php_get_service_key "environment" "PHP_IDE_CONFIG")
    local dc_volumes_length
    target_xdebug_config=".led/90-xdebug-config.ini"
    dc_volumes_length=$(${VENDORS_BIN_JYPARSER} "${dc_file}" get "${dc_volumes_key} | length")

    #edit docker-compose file
    ${VENDORS_BIN_JYPARSER} "${dc_file}" del "${dc_volumes_key}[${dc_volumes_length} - 1]" > "${dc_file_tmp}" \
    && mv "${dc_file_tmp}" "${dc_file}"
    ${VENDORS_BIN_JYPARSER} "${dc_file}" del "${dc_ide_config_key}" > "${dc_file_tmp}" \
    && mv "${dc_file_tmp}" "${dc_file}"

    if [[ -e "${target_xdebug_config}" ]]; then
          rm "${target_xdebug_config}"
    fi
}

# Checks the state of xDebug in led, in order to avoid that some
# manipulations are performed several times in a row
_check_xdebug_state()
{
  local dc_xdebug_value=$1
  local xdebug_arg_value=$2

  if [[ "${dc_xdebug_value}" -eq 0 && "${xdebug_arg_value}" -eq 0 ]]; then
      echo "Xdebug is already disabled"
      exit 1;
  fi

  if [[ "${dc_xdebug_value}" -eq 1 && "${xdebug_arg_value}" -eq 1 ]]; then
      echo "Xdebug is already enabled"
      exit 1;
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
    exit 1
  fi
  _dockercompose_file_check

  local dc_file="${LED_DOCKERCOMPOSE_FILE}"
  local dc_file_tmp=${dc_file}.tmp
  local dc_key=

  local message=
  local ret=

  if [ ! -f "${dc_file}" ]; then
    echo >&2 "${dc_file} not found"
    exit 1
  fi

  if ! dc_key=$(_php_get_service_key "environment" "PHP_MEMORY_LIMIT"); then
    exit 1
  fi

  local memory=$1

  if [ -z "${memory}" ]; then
    # if no memory set, remove entry from configuration to get default container value
    ${VENDORS_BIN_JYPARSER} "${dc_file}" del "${dc_key}" > "${dc_file_tmp}" \
    && mv "${dc_file_tmp}" "${dc_file}"
    ret=$?
    message="Memory limit is restored to the default value"
  else
    # if memory is set, override default container value
    if [[ ! ${memory} =~ ^[0-9]+$ ]]; then
      echo >&2 "memory value must be a number"
      exit 1
    fi

    # set memory value in megabyte
    memory=${memory}M

    ${VENDORS_BIN_JYPARSER} "${dc_file}" set "${dc_key}" \""${memory}"\" > "${dc_file_tmp}" \
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
