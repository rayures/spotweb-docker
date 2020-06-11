#!/bin/bash

WebDir=/var/www/spotweb

echo -e "\nInstalling Spotweb webfiles from github:"
git init ${WebDir}
cd ${WebDir}
git remote add origin https://github.com/spotweb/spotweb.git

if [[ ! -z $VERSION ]]
then
  echo -e "\nDownloading Spotweb $VERSION:"
  git pull origin $VERSION
else
  echo -e "\nDownloading Spotweb master"
  git pull origin master
fi

if [ ! -f /config/ownsettings.php ] && [ -f /var/www/spotweb/ownsettings.php ]; then
  cp /var/www/spotweb/ownsettings.php /config/ownsettings.php
  echo -e "\nCreating settings files"
fi

touch /config/ownsettings.php && chown www-data:www-data /config/ownsettings.php
rm -f /var/www/spotweb/ownsettings.php
ln -s /config/ownsettings.php /var/www/spotweb/ownsettings.php

chown -R www-data:www-data /var/www/spotweb

if [[ -n "$DB_TYPE" && -n "$DB_HOST" && -n "$DB_NAME" && -n "$DB_USER" && -n "$DB_PASS" ]]; then
    echo -e "\nFOUND DB settings: Creating database configuration"
    echo "<?php" > /config/dbsettings.inc.php
    echo "\$dbsettings['engine'] = '$DB_TYPE';" >> /config/dbsettings.inc.php
    echo "\$dbsettings['host'] = '$DB_HOST';" >> /config/dbsettings.inc.php
    echo "\$dbsettings['dbname'] = '$DB_NAME';"  >> /config/dbsettings.inc.php
    echo "\$dbsettings['user'] = '$DB_USER';" >> /config/dbsettings.inc.php
    echo "\$dbsettings['pass'] = '$DB_PASS';"  >> /config/dbsettings.inc.php
fi

if [[ -n "$DB_PORT" ]]; then
    echo -e "\nFOUND DB port settins: adding DB port to database configuration"
    echo "\$dbsettings['port'] = '$DB_PORT';"  >> /config/dbsettings.inc.php
fi

if [ -f /config/dbsettings.inc.php ]; then
    echo -e "make a link to dbsettings"
	chown www-data:www-data /config/dbsettings.inc.php
	rm /var/www/spotweb/dbsettings.inc.php
	ln -s /config/dbsettings.inc.php /var/www/spotweb/dbsettings.inc.php
else
	echo -e "\nWARNING: You have no database configuration file, either create /config/dbsettings.inc.php or restart this container with the correct environment variables to auto generate the config.\n"
fi

TZ=${TZ:-"Europe/Amsterdam"}
echo -e "\nSetting (PHP) time zone to ${TZ}\n"
sed -i "s#^;date.timezone =.*#date.timezone = ${TZ}#g"  /etc/php/7.*/*/php.ini

echo -e "\nSetting PHP Memory limit"
sed -i "s/.*memory_limit.*/memory_limit = 256M/" /etc/php/7.*/*/php.ini

if [[ -n "$SPOTWEB_CRON_RETRIEVE" || -n "$SPOTWEB_CRON_CACHE_CHECK" ]]; then
    echo "setting cron"
    ln -sf /proc/$$/fd/1 /var/log/stdout
    service cron start
	if [[ -n "$SPOTWEB_CRON_RETRIEVE" ]]; then
    # >> /proc/1/fd/1 forces log to redirect to PID1. if proces is not PID1 docker will not see te log
        echo "$SPOTWEB_CRON_RETRIEVE su -l www-data -s /usr/bin/php /var/www/spotweb/retrieve.php --force >> /proc/1/fd/1" > /etc/crontab
	fi
	if [[ -n "$SPOTWEB_CRON_CACHE_CHECK" ]]; then
        echo "$SPOTWEB_CRON_CACHE_CHECK su -l www-data -s /usr/bin/php /var/www/spotweb/bin/check-cache.php >> /proc/1/fd/1" >> /etc/crontab
	fi
    crontab /etc/crontab
fi

# move custom htacces to spotweb folder # Add caching and compression config to .htaccess
echo -e "\nImport custom .htaccess" 
cat /001-htaccess.conf >> /var/www/spotweb/.htaccess
    
# Run database update
echo -e "\nrun DB update"
/usr/bin/php /var/www/spotweb/bin/upgrade-db.php >/dev/null 2>&1
/usr/bin/php /var/www/spotweb/bin/upgrade-db.php >/dev/null 2>&1

# Clean up apache pid (if there is one)
echo -e "\nclean apache pid" 
rm -rf /run/apache2/apache2.pid

# Enabling PHP mod rewrite, expires and deflate (they may be on already by default)
unset rt
/usr/sbin/a2enmod rewrite && rt=1
/usr/sbin/a2enmod expires && rt=1
/usr/sbin/a2enmod deflate && rt=1

# Only restart if one of the enmod commands succeeded 
if [[ -n $rt ]]; then
    /etc/init.d/apache2 restart
fi

echo -e "\ndone" 
tail -f /var/log/apache2/error.log /dev/stdout /dev/stderr
