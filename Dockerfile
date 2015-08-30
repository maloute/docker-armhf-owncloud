FROM armv7/armhf-ubuntu

MAINTAINER Maloute <Maloute@Me>

# Dependencies
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y curl cron inetutils-ping dnsutils net-tools bzip2 php5-cli php5-gd php5-pgsql php5-sqlite \
    php5-mysql php5-curl php5-intl php5-mcrypt php5-ldap php5-gmp php5-apcu \
    php5-imagick php5-fpm smbclient nginx supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# Config files and scripts
ADD nginx_default.conf /etc/nginx/sites-available/default
COPY cron.conf /etc/owncloud-cron.conf

# PHP config
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini

# Config supervisord
ADD supervisor-owncloud.conf /etc/supervisor/conf.d/supervisor-owncloud.conf

# Copy run script for owncloud
COPY run.sh /usr/bin/run.sh


# Install ownCloud
WORKDIR /var/www 
RUN curl https://download.owncloud.org/community/owncloud-8.1.1.tar.bz2 | tar xfj -
RUN su -s /bin/sh www-data -c "crontab /etc/owncloud-cron.conf"

# Config required for owncloud
RUN sed -i -e 's/;env\[PATH\]/env\[PATH\]/' /etc/php5/fpm/pool.d/www.conf
RUN echo 'apc.enable_cli = 1' >> /etc/php5/cli/conf.d/20-apcu.ini


EXPOSE 443

VOLUME ["/var/www/owncloud/config", "/var/www/owncloud/data", \
          "/var/log/nginx", \
        "/etc/ssl/certs/owncloud.crt", "/etc/ssl/private/owncloud.key"]


WORKDIR /var/www/owncloud
# USER www-data
CMD ["/usr/bin/run.sh"]

# Initializing
# Populate config directory with config.php and ca-bundle.crt (otherwise Owncloud complains that it can't connect to the internet...)

# Run Command:
# /usr/bin/docker run --name=owncloudv3 -h owncloud.example.com -p 443:443 --link mariadb:db -e DB_NAME=owncloud -e DB_USER=owncloud -e DB_PASS=owncloud -e ADMIN_USER=admin -e ADMIN_PASS=admin -e TIMEZONE=Europe/Paris -v /srv/docker/owncloud/config:/var/www/owncloud/config -v /srv/docker/owncloud/data:/var/www/owncloud/data -v /srv/docker/owncloud/logs/:/var/log/nginx -v /srv/docker/owncloud/owncloud.crt:/etc/ssl/certs/owncloud.crt -v /srv/docker/owncloud/owncloud.key:/etc/ssl/private/owncloud.key maloute/owncloudv3
