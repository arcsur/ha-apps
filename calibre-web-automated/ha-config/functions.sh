#!/command/with-contenv bashio
# shellcheck shell=bash

# Function to stop the script from running to debug the environment
debug_wait() {
    if [ "$(bashio::config 'debug_mode')" == "true" ]; then
        bashio::log.info "Debug mode enabled. Pausing script."

        # Start background task and wait for it
        sleep infinity &
        SLEEP_PID=$!
        bashio::log.info "To resume, run: kill ${SLEEP_PID}"
        wait

        bashio::log.info "Signal received! Resuming execution..."
    fi
}

trap_handler() {
    local exit_code="${1}"
    local line_number=${2:-BASH_LINENO}
    local command="${3:-${BASH_COMMAND}}"

    bashio::log.error "Error ${exit_code} occurred during execution.\n[${line_number}] ${command}"
    debug_wait
    return "${exit_code}"
}

debug_setup() {
    if [ "$(bashio::config 'debug_mode')" == "true" ]; then
        bashio::log.info "Debug mode enabled. Setting log level to debug."
        bashio::log.level debug
    fi
    trap 'trap_handler $? ${LINENO} "${BASH_COMMAND}"; exit $?' ERR
}

# Function to retrieve a configuration value with a default value option and log if it is empty
get_config_value() {
    local config_key="${1}"
    local default_value="${2:-}"
    local config_value

    bashio::log.debug "Configuration key ${config_key} requested"
    config_value=$(bashio::config "${config_key}")
    if [ -z "${config_value}" ] || [ "${config_value}" = "null" ]; then
        bashio::log.error "Configuration value for ${config_key} is empty"
        config_value="${default_value}"
    fi
    printf '%s' "${config_value}"
}

# Function to set an environment variable for later s6 scripts
set_env_var() {
    local env_name="${1}"
    local env_value="${2}"

    printf '%s' "${env_value}" > "/var/run/s6/container_environment/${env_name}"
}

# Function to set environment variables based on add-on configuration
set_env_var_from_config() {
    local config_key="${1}"
    local env_name="${2}"
    local config_value

    config_value=$(get_config_value "${config_key}")
    if [ -z "${config_value}" ]; then
        bashio::log.debug "Skipping setting environment variable for empty ${config_key}"
        return
    fi
    set_env_var "${env_name}" "${config_value}"
}

# Function to resolve a path from the add-on configuration and ensure it is a valid absolute path
resolve_path() {
    local config_key="${1}"
    local default_path="${2:-}"
    local config_value
    local resolved_path

    config_value=$(get_config_value "${config_key}" "${default_path}")
    if [ -z "${config_value}" ]; then
        bashio::log.fatal "No path configured for ${config_key}"
        bashio::exit.nok
    fi
    # Ensure the host-mapped directory exists (e.g., /share/my_folder)
    if ! bashio::fs.directory_exists "${config_value}"; then
        bashio::log.debug "Creating directory ${config_value}"
        mkdir -p "${config_value}"
    fi
    # Resolve the absolute path inside the container
    resolved_path=$(realpath "/${config_value}") || {
        bashio::log.fatal "Failed to resolve ${config_key}: ${config_value}"
        bashio::exit.nok
    }

    printf '%s' "${resolved_path}"
}

# Function to map a host directory to the application's expected path using a symbolic link
map_path() {
    local mapped_path="${1}"
    local app_path="${2}"
    local file_name="${3:-}"

    # If the mapped path is the same as the app path, no need to create a symlink
    if [ -z "${mapped_path}" ] || [ "${mapped_path}" == "${app_path}" ]; then
        bashio::log.debug "Mapped path ${mapped_path} is the same as app path ${app_path}, skipping symlink creation"
        return
    fi
    # If we don't have a filename and the app's default directory exists and isn't a link, move it or remove it
    if [ -z "${file_name}" ] && [ -d "${app_path}" ] && [ ! -L "${app_path}" ]; then
        bashio::log.warning "Removing existing internal directory to make room for symlink"
        rm -rf "${app_path}"
    fi
    # Create the link
    if [ -n "${file_name}" ]; then
        ln -s "${mapped_path}/${file_name}" "${app_path}/${file_name}"
        bashio::log.info "Successfully mapped ${mapped_path}/${file_name} to ${app_path}/${file_name}"
    else
        ln -s "${mapped_path}" "${app_path}"
        bashio::log.info "Successfully mapped ${mapped_path} to ${app_path}"
    fi
}
