#!/bin/bash
# wait until MySQL is really available
maxcounter=60

HOST_PORT=$1
OPEN_MYSQL_PORT=$2

counter=1
while ! mysql --protocol TCP -u root -pCl0udPercept123 -h ${HOST_PORT} -P ${OPEN_MYSQL_PORT} -e "show databases;" > /dev/null 2>&1; do
    sleep 1
    counter=`expr $counter + 1`
    if [ $counter -gt $maxcounter ]; then
        >&2 echo "We have been waiting for MySQL too long already; failing."
        exit 1
    fi;
done
