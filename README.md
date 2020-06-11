# spotweb-docker
spotweb for docker

Ubuntu latest with a fresh git-pull from spotweb source on container start (you can define the branch!).

# Usage

## Initial Installation

First create a database on your database server, and make sure the container has access to the database, then run a temporary container.

```
docker run -it --rm -p 80:80 \
	-e TZ='Europe/Amsterdam' \
	rayures/spotweb-docker:latest
```

Please NOTE that there is no database configuration here, this will enable the install process.

The run the Spotweb installer using the web interface: 'http://yourhost/install.php'. This will create the necessary database tables and users.

When you are done, exit the container (CTRL/CMD-c) and configure the permanent running container.

## Permanent installation

```
docker run --restart=always -d -p 80:80 \
	--hostname=spotweb \
	--name=spotweb \
	-v <hostdir_where_config_will_persistently_be_stored>:/config \
	-e 'TZ=Europe/Amsterdam' \
   	-e 'VERSION=master' \
	-e 'DB_TYPE=pdo_mysql' \
	-e 'DB_HOST=<database_server_hostname>' \
	-e 'DB_PORT=<database_port>' \
	-e 'DB_NAME=spotweb' \
	-e 'DB_USER=spotweb' \
	-e 'DB_PASS=spotweb' \
   	-e 'SPOTWEB_CRON_RETRIEVE={0 * * * * #every hour} [OPTIONAL]' \
  	-e 'SPOTWEB_CRON_CACHE_CHECK={* 4 * * * #every day at 04.00} [OPTIONAL]' \
	rayures/spotweb-docker:latest
```

Please NOTE that the volume is optional. Only necessary when you have special configuration settings. The database port is also optional. If omitted it will use the standard port for MySQL / PostgreSQL
You should now be able to reach the spotweb interface on port 80.

##### Spotweb github branch
you can define the spotweb branch via the VERSION environment variable. If not defined it defaults to MASTER.

## Automatic retrieval of new spots

To enable automatic retrieval, you can use the environment variables 
```
   -e 'SPOTWEB_CRON_RETRIEVE={0 * * * * #every hour} [OPTIONAL]' \
   -e 'SPOTWEB_CRON_CACHE_CHECK={* 4 * * * #every day at 04.00} [OPTIONAL]' \
```

## 
Docker-hub image will be auto updated every month.

special thanks to:
- https://hub.docker.com/r/jgeusebroek/spotweb
- https://hub.docker.com/r/jerheij/spotweb
