#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR=${DIR}/app
MYSQL_ROOT_PASSWORD=P@ssword
MYSQL_DJANGO_PASSWORD=password

log ()
{
        timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
        echo "[${timestamp}] $1"
}

setup_mysql()
{
  dpkg-query -l mysql-server > /dev/null
  install_status=$?
  if [ ${install_status} -ne 0 ]; then
    log "Updating packages..."
    apt-get update -y > /dev/null

    log "Installing MySQL server"
    apt-get install mysql-server -y > /dev/null
  fi
}

start_mysql()
{
  local process_count=$(pgrep mysql | wc -l)
  if [ ${process_count} -eq 0 ]; then
    log "Starting MySQL server..."
    service mysql start
    sleep 5
  fi
}

prepare_db()
{
  setup_mysql
  start_mysql

  log "Preparing databases..."
  mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS django DEFAULT CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON django.* TO 'django'@'localhost' IDENTIFIED BY '${MYSQL_DJANGO_PASSWORD}'; FLUSH PRIVILEGES;
EOF

  if [ ! -f "/etc/mysql/django.cnf" ]; then
    cp django.cnf /etc/mysql/
    service mysql restart
  fi
}

setup_application()
{
  pip install -r requirements.txt

  python manage.py migrate

  cat <<EOF | python manage.py shell
from django.contrib.auth.models import User

if not User.objects.filter(is_superuser=True):
  User.objects.create_superuser('admin', 'admin@example.com', '${MYSQL_DJANGO_PASSWORD}')

EOF

}

run_application()
{
  setup_application
  python manage.py runserver 0.0.0.0:8000
}

pushd ${APP_DIR} > /dev/null

prepare_db
run_application

popd > /dev/null
