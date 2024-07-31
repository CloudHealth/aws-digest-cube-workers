#!/bin/bash -e

# This copies the config files (database.yml, server.json) from /etc/helm_config to /root/cp-workers/config/
# These files are required by the service pod to know how to interact with dependent services (rabbitmq, redis, mysql)
if [ -d /etc/helm_config ]; then
  cp /etc/helm_config/* /root/cp-workers/config/
fi

if [ -d /root/cp-workers/collector_config ]; then
  cp /root/cp-workers/collector_config/* /root/cp-workers/config/
fi

if [ -d /root/cp-workers/processor_config ]; then
  cp /root/cp-workers/processor_config/* /root/cp-workers/config/
fi

# Run collector/processor based on the argument given to entrypoint
if [[ "$1" == "collector" ]]; then
  BUNDLE_GEMFILE=Gemfile CP_WORKER_ACTION=collector bundle exec jruby --server -J-Xss$XSS -J-Xmx$XMX -J-Xms$XMS -J-Dfile.encoding=UTF-8 $(which rake) collectors:start
elif [[ "$1" == "processor" ]]; then
  BUNDLE_GEMFILE=Gemfile CP_WORKER_ACTION=processor bundle exec jruby --server -J-Xss$XSS -J-Xmx$XMX -J-Xms$XMS -J-Dfile.encoding=UTF-8 $(which rake) processors:start
else
  $@ # Run the command that was given to the script
fi