#!/usr/bin/env bash
# /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf

WebConf=/etc/apache2/conf.d/spotweb.conf
SSLWebConf=/etc/apache2/conf.d/spotweb_ssl.conf
WebDir=/var/www/spotweb

echo
echo "Installing Spotweb webfiles from github:"
git init ${WebDir}
cd ${WebDir}
git remote add origin https://github.com/spotweb/spotweb.git

if [[ ! -z ${VERSION} ]]
then
  echo "Downloading Spotweb ${VERSION}:"
  git pull origin ${VERSION}
else
  echo "Downloading Spotweb master"
  git pull origin master
fi

echo

case ${SSL} in
  enabled)
    echo "Deploying apache config with SSL support:"
    cat <<EOF > ${SSLWebConf}
<VirtualHost 0.0.0.0:443>
    ServerAdmin _

    SSLEngine on
    SSLCertificateFile "/etc/ssl/web/spotweb.crt"
    SSLCertificateKeyFile "/etc/ssl/web/spotweb.key"
    SSLCertificateChainFile "/etc/ssl/web/spotweb.chain.crt"

    DocumentRoot ${WebDir}
    <Directory ${WebDir}/>
        RewriteEngine on
        RewriteCond %{REQUEST_URI} !api/
        RewriteRule ^api/?$ index.php?page=newznabapi [QSA,L]
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
  chown apache: ${SSLWebConf}
  chmod 600 /etc/ssl/web/*
  apk add apache2-ssl
  ;;

  *)
    echo "Deploying apache config without SSL support:"
esac

cat <<EOF > ${WebConf}
<VirtualHost 0.0.0.0:80>
    ServerAdmin _

    DocumentRoot ${WebDir}
    <Directory ${WebDir}/>
        RewriteEngine on
        RewriteCond %{REQUEST_URI} !api/
        RewriteRule ^api/?$ index.php?page=newznabapi [QSA,L]
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
chown apache: ${WebConf}
sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf
sed -i "s/#ServerName www.example.com/ServerName $(hostname)/g" /etc/apache2/httpd.conf
echo "date.timezone = ${TZ}" >> /etc/php7/php.ini

echo
echo "Installing ${DB_TYPE} support:"
case ${DB_TYPE} in
  sqlite)
    apk add php7-pdo_sqlite
  ;;

  pdo_pgsql)
    apk add php7-pgsql php7-pdo_pgsql
  ;;

  pdo_mysql)
    apk add php7-mysqlnd php7-pdo_mysql
  ;;

  *)
    echo
    echo "Option SQL=${DB_TYPE} invalid, use sqlite, psql or mysql!"
  ;;
esac

#mkdir /config/
#touch /config/ownsettings.php #&& chown www-data:www-data /config/ownsettings.php
#rm -f /var/www/spotweb/ownsettings.php
#ln -s /config/ownsettings.php /var/www/spotweb/ownsettings.php

#if [[ -n "$DB_TYPE" && -n "$DB_HOST" && -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASS" ]]; then
#    echo "Creating database configuration"
#    touch /config/dbsettings.inc.php # && chown www-data:www-data ${WebDir}/dbsettings.inc.php
#    echo "<?php" > /config/dbsettings.inc.php
#    echo "\$dbsettings['engine'] = '$DB_TYPE';" >> /config/dbsettings.inc.php
#    echo "\$dbsettings['host'] = '$DB_HOST';" >> /config/dbsettings.inc.php
#    echo "\$dbsettings['dbname'] = '$DB_NAME';"  >> /config/dbsettings.inc.php
#    echo "\$dbsettings['user'] = '$DB_USER';" >> /config/dbsettings.inc.php
#    echo "\$dbsettings['pass'] = '$DB_PASS';"  >> /config/dbsettings.inc.php
#fi

#if [[ -n "$DB_PORT" ]]; then
#    echo "adding port settings in database configuration"
#    echo "\$dbsettings['port'] = '$DB_PORT';"  >> /config/dbsettings.inc.php
#fi

#if [ -f /config/dbsettings.inc.php ]; then
#	#chown www-data:www-data /config/dbsettings.inc.php
#	rm /var/www/spotweb/dbsettings.inc.php
#	ln -s /config/dbsettings.inc.php /var/www/spotweb/dbsettings.inc.php
#else
#	echo -e "\nWARNING: You have no database configuration file, either create /config/dbsettings.inc.php or restart this container with the correct environment variables to auto generate the config.\n"
#fi

if [[ ! -z ${UUID} ]]
then
  echo
  echo "Replacing old apache UID with ${UUID}"
  OldUID=$(getent passwd apache | cut -d ':' -f3)
  usermod -u ${UUID} apache
  find / -user ${OldUID} -exec chown -h apache {} \; &> /dev/null
fi

if [[ ! -z ${GUID} ]]
then
  echo "Replacing old apache GID with ${GUID}"
  OldGID=$(getent passwd apache | cut -d ':' -f4)
  groupmod -g ${GUID} apache
  find / -group ${OldGID} -exec chgrp -h apache {} \; &> /dev/null
fi

if [[ -n "$SPOTWEB_CRON_RETRIEVE" || -n "$SPOTWEB_CRON_CACHE_CHECK" ]]; then
    ln -sf /proc/$$/fd/1 /var/log/stdout
#    service cron start
	if [[ -n "$SPOTWEB_CRON_RETRIEVE" ]]; then
        echo "setting cron retrieve settings"
        echo "$SPOTWEB_CRON_RETRIEVE su -l www-data -s /usr/bin/php /var/www/spotweb/retrieve.php >/var/log/stdout 2>&1" > /etc/crontab
	fi
	if [[ -n "$SPOTWEB_CRON_CACHE_CHECK" ]]; then
        echo "setting cron cache check settings"
        echo "$SPOTWEB_CRON_CACHE_CHECK su -l www-data -s /usr/bin/php /var/www/spotweb/bin/check-cache.php >/var/log/stdout 2>&1" >> /etc/crontab
	fi
#    crontab /etc/crontab
fi

# Clean up apache pid (if there is one)
rm -rf /run/apache2/apache2.pid

chown -R apache: ${WebDir}
rm -rf /var/cache/apk/* && \

# Run database update (2 times)
#echo "update DB"
#	/usr/bin/php /var/www/spotweb/bin/upgrade-db.php >/dev/null 2>&1
#	/usr/bin/php /var/www/spotweb/bin/upgrade-db.php >/dev/null 2>&1

echo "Deployment done!"
exec "$@"

tail -F /var/log/apache2/* /dev/stdout /dev/stderr
