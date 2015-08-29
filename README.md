# docker-armhf-owncloud
## Construction de l'image
```
docker build -t maloute/owncloud .
```

## Execution de l'image
```
/usr/bin/docker run --name=owncloudv3 -h owncloud.example.com -p 443:443 --link mariadb:db -e DB_NAME=owncloud -e DB_USER=owncloud -e DB_PASS=owncloud -e ADMIN_USER=admin -e ADMIN_PASS=admin -e TIMEZONE=Europe/Paris -v /srv/docker/owncloud/config:/var/www/owncloud/config -v /srv/docker/owncloud/data:/var/www/owncloud/data -v /srv/docker/owncloud/logs/:/var/log/nginx -v /srv/docker/owncloud/owncloud.crt:/etc/ssl/certs/owncloud.crt -v /srv/docker/owncloud/owncloud.key:/etc/ssl/private/owncloud.key maloute/owncloudv3
```
