# spotweb-docker
spotweb for docker

Alpine with a fresh git-pull from spotweb source on container start. 

Environment variables:
   - TZ=Europe/Amsterdam
   - VERSION={master|develop}
   - DB_TYPE={psql|mysql|sqlite}
   - BD_HOST={name}
   - DB_PORT={port}
   - DB_NAME={spotweb}
   - DB_USER={username}
   - DB_PASS={password}
   - SPOTWEB_CRON_RETRIEVE={0 * * * * #every hour}
   - SPOTWEB_CRON_CACHE_CHECK={* 4 * * * #every day at 04.00}

Docker-hub image auto updates every month.
