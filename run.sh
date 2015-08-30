#!/usr/bin/env bash

set -e

DB_TYPE=${DB_TYPE:-sqlite}
DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-owncloud}
DB_USER=${DB_USER:-owncloud}
DB_PASS=${DB_PASS:-owncloud}
DB_TABLE_PREFIX=${DB_TABLE_PREFIX:-oc_}
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-changeme}
DATA_DIR=${DATA_DIR:-/var/www/owncloud/data}

# Database vars
# TODO: Add support for Oracle DB (and SQLite?)
if [[ "$DB_PORT_5432_TCP_ADDR" ]]
then
    DB_TYPE=pgsql
    DB_HOST=$DB_PORT_5432_TCP_ADDR
elif [[ "$DB_PORT_3306_TCP_ADDR" ]]
then
    DB_TYPE=mysql
    DB_HOST=$DB_PORT_3306_TCP_ADDR
fi

# echo "The $DB_TYPE database is listening on ${DB_HOST}:${DB_PORT}"

update_config_line() {
    local -r config="$1" option="$2" value="$3"

    # Skip if value is empty.
    if [[ -z "$value" ]]; then
        return
    fi

    # Check if the option is set.
    if grep "$option" "$config" >/dev/null 2>&1
    then
        # Update existing option
        sed -i "s|\([\"']$option[\"']\s\+=>\).*|\1 '$value',|" "$config"
    else
        # Create autoconfig.php if necessary
        [[ -f "$config" ]] || {
            echo -e '<?php\n$AUTOCONFIG = array (' > "$config"
        }

        # Add to config
        sed -i "s|\(CONFIG\s*=\s*array\s*(\).*|\1\n  '$option' => '$value',|" "$config"
    fi
}

owncloud_autoconfig() {
    echo -n "Creating autoconfig.php... "
    local -r config=/var/www/owncloud/config/autoconfig.php
    # Remove existing autoconfig
    rm -f "$config"
    update_config_line "$config" dbtype "$DB_TYPE"
    echo -n "Updating dbhost with $DB_HOST value... "
    update_config_line "$config" dbhost "$DB_HOST"
    update_config_line "$config" dbname "$DB_NAME"
    update_config_line "$config" dbuser "$DB_USER"
    update_config_line "$config" dbpass "$DB_PASS"
    update_config_line "$config" dbtableprefix "$DB_TABLE_PREFIX"
    update_config_line "$config" adminlogin "$ADMIN_USER"
    update_config_line "$config" adminpass "$ADMIN_PASS"
    update_config_line "$config" directory "$DATA_DIR"
    update_config_line "$config" memcache.local "\\\\OC\\\\Memcache\\\\APCu"
    # Add closing tag
    if ! grep ');' "$config"
    then
        echo ');' >> "$config"
    fi
    echo "Done !"
}

update_owncloud_config() {
    echo -n "Updating config.php... "
    local -r config=/var/www/owncloud/config/config.php
    update_config_line "$config" dbtype "$DB_TYPE"
    update_config_line "$config" dbhost "$DB_HOST"
    update_config_line "$config" dbname "$DB_NAME"
    update_config_line "$config" dbuser "$DB_USER"
    update_config_line "$config" dbpassword "$DB_PASS"
    update_config_line "$config" dbtableprefix "$DB_TABLE_PREFIX"
    update_config_line "$config" directory "$DATA_DIR"
    update_config_line "$config" memcache.local "\\\\OC\\\\Memcache\\\\APCu"
    echo "Done !"
}

# Update the config if the config file exists, otherwise autoconfigure owncloud
if [[ -f /var/www/owncloud/config/config.php ]]
then
    update_owncloud_config
else
    owncloud_autoconfig
fi

# Create data directory
mkdir -p "$DATA_DIR"

# Fix permissions
chown -R www-data:www-data /var/www/owncloud

# FIXME: This setup is intended for running supervisord as www-data
# Supervisor setup
# touch /var/run/supervisord.pid
# chown www-data:www-data /var/run/supervisord.pid
# touch /var/log/supervisor/supervisord.log
# chown www-data:www-data /var/log/supervisor/supervisord.log
# mkdir -p /var/log/supervisor
# chown www-data:www-data /var/log/supervisor

# PHP-FPM setup
# touch /var/log/php5-fpm.log
# chown www-data:www-data /var/log/php5-fpm.log

# nginx setup
# mkdir -p /var/log/nginx
# chown www-data:www-data /var/log/nginx

update_timezone() {
    echo -n "Setting timezone to $1... "
    ln -sf "/usr/share/zoneinfo/$1" /etc/localtime
    [[ $? -eq 0 ]] && echo "Done !" || echo "FAILURE"
}
if [[ -n "$TIMEZONE" ]]
then
    update_timezone "$TIMEZONE"
fi

exec supervisord -n -c /etc/supervisor/supervisord.conf
