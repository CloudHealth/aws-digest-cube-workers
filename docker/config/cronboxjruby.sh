#!/bin/bash
cd /root/cp-workers
export RAKE_PATH="/usr/local/rvm/rubies/jruby-9.2.14.0/bin/rake"
export PATH=/usr/local/rvm/gems/jruby-9.2.14.0/bin:/usr/local/rvm/gems/jruby-9.2.14.0@global/bin:/usr/local/rvm/rubies/jruby-9.2.14.0/bin:/usr/local/rvm/bin:/usr/local/bundle/bin:/opt/jruby/bin:/usr/local/openjdk-11/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
source /usr/local/rvm/scripts/rvm
rvm use jruby-9.2.14.0
export BUNDLE_GEMFILE=/root/cp-workers/Gemfile
export RAILS_ENV=production
export TZ=UTC
export JRUBY_OPTS="-J-Dfile.encoding=UTF-8 -J-Xmx12288m -J-verbose:gc"
export CP_WORKER_ACTION="processor"
bundle exec "$RAKE_PATH" "$1"
