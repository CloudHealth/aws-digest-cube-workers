ARG JDK_VERSION=jdk11

FROM artifactory.mgmt.cloudhealthtech.com/cht-docker/jruby:9.2.14.0-${JDK_VERSION}-maven-rvm

#Dockerfile is maintained by Vivek Kotecha (vkotecha@vmware.com)
LABEL maintainer=vkotecha@vmware.com

RUN apt-get install -y vim p7zip-full

ARG RELEASE_VERSION

# All the commands must be run using the bash shell which has the "source" binary.
# Otherwise all commands will run in /bin/sh which does not have source.
SHELL ["/bin/bash", "-c"]

COPY docker/config/maven/pom.xml /root/pom.xml
RUN mkdir -p /root/.m2/
COPY docker/config/maven/settings.xml /root/.m2/settings.xml
RUN cd /root && mvn dependency:copy
RUN rm -rf /root/.m2/repository/

# Copy the ssh credentials to be able to talk to git
RUN mkdir -p /root/.ssh
COPY docker/config/ssh/config /root/.ssh/config
COPY ssh_key /root/.ssh/id_rsa
RUN mkdir -p /root/cp-workers
COPY docker/config/cronbox.sh /root/cp-workers/cronbox.sh
COPY docker/config/cronboxjruby.sh /root/cp-workers/cronboxjruby.sh
RUN chmod 600 /root/.ssh/id_rsa /root/.ssh/config

COPY docker/config/bundle/config /root/.bundle/config
ADD docker/config/entrypoint-cube-workers_k8s.sh /root/cp-workers/entrypoint-cube-workers_k8s.sh

# Copy repo files and change the working directory
RUN mkdir -p /root/cp-workers/lib/cp-workers
COPY ./Gemfile* /root/cp-workers/
WORKDIR /root/cp-workers

#CUBINATOR JAR
#RUN curl https://artifactory.mgmt.cloudhealthtech.com/artifactory/cht-maven/com/cloudhealthtech/cubes/Cubinator/1.0-SNAPSHOT/Cubinator-1.0-20240423.150611-84.jar --output Cubinator.jar

# TITANS-2712
RUN curl https://artifactory.mgmt.cloudhealthtech.com/artifactory/cicd/asset-cache-exporter-1.0-SNAPSHOT-1.zip --output asset-cache-exporter-1.0-SNAPSHOT-1.zip
RUN unzip -o asset-cache-exporter-1.0-SNAPSHOT-1.zip

# copy gemfiles from sub-module
RUN mkdir /root/cp-workers/core
COPY ./core/Gemfile* /root/cp-workers/core/

#BUNDLE INSTALLS GOES HERE
# JRuby
RUN source /usr/local/rvm/scripts/rvm && \
    rvm use jruby-9.2.14.0 &&\
    gem install bundler:1.17.3 &&\
    BUNDLE_GEMFILE=GemfileMriAwsDigest bundle install --with development --no-deployment --binstubs=bin

# Cube workers are running on a different ruby engine and have a different start script.
RUN source /usr/local/rvm/scripts/rvm && \
    rvm use 2.5.5@cubes &&\
    gem install bundler:1.17.3 &&\
    gem install mysql2:0.3.21 &&\
    USE_SYSTEM_GECODE=1 BUNDLE_GEMFILE=GemfileMriAwsDigest bundle install --with development --no-deployment --binstubs=bin

# modify the copy contents such that cp-workers content and this repo is flattened. this repo contents are superceded
COPY core/ /root/cp-workers/
COPY .[^core]* /root/cp-workers
RUN chmod +x /root/cp-workers/docker/test_mysql_connection.sh

RUN touch /root/version.txt
RUN date +"%FT%H%M%S" > /root/version.txt

RUN echo "source /usr/local/rvm/scripts/rvm" >> /etc/bash.bashrc
RUN echo "rvm use 2.5.5@cubes" >> /etc/bash.bashrc
