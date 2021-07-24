#!/bin/bash


set -e

if ! [[ "$1" =~ (web|worker|cron)$ ]]; then
  echo "Usage: $0 [service]"
  echo "Service can be web; worker; cron"
  exit 1
fi

while ! mysqladmin ping -h$DB_HOST -u$DB_USERNAME -p$DB_PASSWORD -P${DB_PORT:-3306} --silent; do
   echo "Database container still booting"
   sleep 3
done

while ! redis-cli -h $REDIS_HOST ping; do
    echo "Redis container still booting"
   sleep 3
done

echo "startup.sh for wirepath has started"


function web_service() {
  echo "starting web service"
  echo "should have trusted proxy"

  php artisan migrate
  php artisan eve:update:sde -n
  composer dump-autoload

  chown -R www-data:www-data /var/www/esitest

  apache2-foreground
}

function start_worker(){

  chown -R www-data:www-data storage

  php artisan horizon

}

function start_cron() {

    echo 'Starting Cron Service'

    while :
    do
      php /var/www/esitest/artisan schedule:run &
      php /var/www/esitest/artisan short-schedule:run --lifetime=60
    done
}

case $1 in
  web)
    echo "Starting web service"
    web_service
    ;;
  worker)
    echo "starting workers"
    start_worker
    ;;
  cron)
    echo "Starting Cron"
    start_cron
    ;;


esac
