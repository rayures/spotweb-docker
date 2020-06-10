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

Docker-hub image auto updates every month.
