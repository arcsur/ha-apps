#!/command/with-contenv bashio
# shellcheck shell=bash

# Function to stop the script from running to debug the environment
debug_script() {
    if [ "$(bashio::config 'debug_mode')" == "true" ]; then
        bashio::log.warning "Debug mode enabled. Pausing script."

        # Start background task and wait for it
        sleep infinity &
        SLEEP_PID=$!
        bashio::log.info "To resume, run: kill ${SLEEP_PID}"
        wait

        bashio::log.info "Signal received! Resuming execution..."
    fi
}

# Function to retrieve a configuration value and log if it is empty
get_config_value() {
    local config_key="${1}"
    local config_value

    config_value=$(bashio::config "${config_key}")
    if [ -z "${config_value}" ]; then
        bashio::log.debug "Configuration value for ${config_key} is empty"
    fi
    printf '%s' "${config_value}"
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
    printf '%s' "${config_value}" > "/var/run/s6/container_environment/${env_name}"
}

# Function to resolve a path from the add-on configuration and ensure it is a valid absolute path
resolve_path() {
    local config_key="$1"
    local config_value
    local resolved_path

    config_value=$(get_config_value "${config_key}")
    if [ -z "${config_value}" ]; then
        bashio::log.warning "No path configured for ${config_key}, skipping resolution"
        return
    fi
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

    # Ensure the host-mapped directory exists (e.g., /share/my_folder)
    if ! bashio::fs.directory_exists "${mapped_path}"; then
        bashio::log.info "Creating directory ${mapped_path}"
        mkdir -p "${mapped_path}"
    fi
    # If the mapped path is the same as the app path, no need to create a symlink
    if [ -z "${mapped_path}" ] || [ "${mapped_path}" == "${app_path}" ]; then
        bashio::log.debug "Mapped path ${mapped_path} is the same as app path ${app_path}, skipping symlink creation"
        return
    fi
    # If the app's default directory exists and isn't a link, move it or remove it
    if [ -d "${app_path}" ] && [ ! -L "${app_path}" ]; then
        bashio::log.warning "Removing existing internal directory to make room for symlink"
        rm -rf "${app_path}"
    fi
    # Create the link
    ln -s "${mapped_path}" "${app_path}"
    bashio::log.success "Successfully mapped ${app_path} to ${mapped_path}"
}
