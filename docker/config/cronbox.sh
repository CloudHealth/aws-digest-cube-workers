#!/bin/bash
cd /root/cp-workers
export RAKE_PATH="/usr/local/rvm/rubies/ruby-2.5.5/bin/rake"
export PATH=/usr/local/rvm/gems/ruby-2.5.5@cubes/bin:/usr/local/rvm/gems/ruby-2.5.5@global/bin:/usr/local/rvm/rubies/ruby-2.5.5/bin:/usr/local/rvm/bin:/usr/local/bundle/bin:/opt/jruby/bin:/usr/local/openjdk-11/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
source /usr/local/rvm/scripts/rvm
rvm use 2.5.5@cubes
export BUNDLE_GEMFILE=/root/cp-workers/GemfileMri
export RAILS_ENV=production
export TZ=UTC
bundle exec "$RAKE_PATH" "$1"