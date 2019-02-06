#!/usr/bin/env bash

MYSQL_ROOT_PASSWORD=P@ssword
MYSQL_DJANGO_PASSWORD=P@ssword


setup_mysql()
{
  echo "Checking whether MySQL server is installed"
  dpkg-query -l mysql-server > /dev/null
  install_status=$?
  if [ ${install_status} -ne 0 ]; then
    echo "Updating packages..."
    apt-get update -y > /dev/null

    echo "Installing MySQL server"
    apt-get install mysql-server -y

    mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION; FLUSH PRIVILEGES;
    CREATE DATABASE django DEFAULT CHARACTER SET utf8;
    GRANT ALL PRIVILEGES ON django.* TO 'django'@'localhost' IDENTIFIED BY '${MYSQL_DJANGO_PASSWORD}'; FLUSH PRIVILEGES;
EOF

    cp my.cnf /etc/mysql
    service mysql restart

  else
    echo "MySQL server installed"
  fi
}

start_mysql()
{
  local process_count=$(pgrep mysql | wc -l)
  if [ ${process_count} -eq 0 ]; then
    echo "Starting MySQL server"
    service mysql start
  else
    echo "MySQL server is running..."
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
  python manage.py runserver 0.0.0.0:8000
}

setup_mysql
start_mysql

setup_application
run_application
