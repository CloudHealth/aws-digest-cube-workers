#!/bin/bash --login

# This copies the config files (database.yml, server.json) from /etc/helm_config to /root/cp-workers/config/
# These files are required by the service pod to know how to interact with dependent services (rabbitmq, redis, mysql)
if [ -d /etc/helm_config ]; then
  cp /etc/helm_config/* /root/cp-workers/config/
fi

if [[ ! -z "${CRON_BOX}" ]]; then
  cp /root/cp-workers/cronbox* /root/cp-workers/config/
  service cron start
  crontab /etc/cron.d/cp-workers
fi

rvm use 2.5.5@cubes
export TZ=UTC

$@