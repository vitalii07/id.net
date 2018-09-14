#!/bin/bash

MYSQL="mysql -h $MYSQL_PORT_3306_TCP_ADDR -P$MYSQL_PORT_3306_TCP_PORT -uroot"
DB="idnet_development"

$MYSQL -e "DROP DATABASE IF EXISTS $DB" &&
$MYSQL -e "CREATE DATABASE $DB" &&

cp config/database.docker.yml config/database.yml &&
cp config/mongoid.docker.yml config/mongoid.yml &&

bundle exec rake global_phone:install &&
bundle exec rake geoip:install &&
bundle exec rake db:mongoid:purge &&
bundle exec rake db:mongoid:create_indexes &&
bundle exec rake active_record:db:migrate &&
bundle exec rake db:migrate &&
bundle exec rake db:seed &&
bundle exec rake setup:bootstrap &&
bundle exec rake environment elasticsearch:import:all FORCE=true
