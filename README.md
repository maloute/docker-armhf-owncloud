# docker-armhf-owncloud
Basé sur l'image pschmitt/owncloud (https://hub.docker.com/r/pschmitt/owncloud/) modifié pour coller à mon odroid u3
## Construction de l'image
```
docker build -t maloute/owncloud .
```

## Execution de l'image
```
/usr/bin/docker run --name=owncloudv3 -h owncloud.example.com -p 443:443 --link mariadb:db -e DB_NAME=owncloud -e DB_USER=owncloud -e DB_PASS=owncloud -e ADMIN_USER=admin -e ADMIN_PASS=admin -e TIMEZONE=Europe/Paris -v /srv/docker/owncloud/config:/var/www/owncloud/config -v /srv/docker/owncloud/data:/var/www/owncloud/data -v /srv/docker/owncloud/logs/:/var/log/nginx -v /srv/docker/owncloud/owncloud.crt:/etc/ssl/certs/owncloud.crt -v /srv/docker/owncloud/owncloud.key:/etc/ssl/private/owncloud.key maloute/owncloudv3
```
## Autostart on boot
- Faire un cd vers le répertoire où se trouve le fichier docker-owncloud.service
- Activer le service systemd via la commande suivante:

```
systemctl enable /srv/docker/owncloud/docker-owncloud.service
```

## Notes
- Comme le dossier /config sera partagé avec l'hôte, il faudra copier le fichier config/ca-bundle.crt du tarball d'owncloud vers le dossier /config, sinon owncloud se plaindra qu'il n'a pas accès au net
- La partie memcache sera activé au deuxième lancement du container, owncloud ne gérant pas encore l'option 'memcache.local' dans le fichier autoconfig.php
