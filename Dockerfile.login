FROM jenkins:2.46.3
WORKDIR /tmp

# Environment variables used throughout this Dockerfile
#
# $JENKINS_HOME     will be the final destination that Jenkins will use as its
#                   data directory. This cannot be populated before Marathon
#                   has a chance to create the host-container volume mapping.
#
ENV JENKINS_FOLDER /usr/share/jenkins

# Build Args
ARG LIBMESOS_DOWNLOAD_URL=https://downloads.mesosphere.com/libmesos-bundle/libmesos-bundle-1.8.7-1.0.2-2.tar.gz
ARG LIBMESOS_DOWNLOAD_SHA256=9757b2e86c975488f68ce325fdf08578669e3c0f1fcccf24545d3bd1bd423a25
ARG BLUEOCEAN_VERSION=1.0.1
ARG JENKINS_STAGING=/usr/share/jenkins/ref/
ARG PORT1=8080

USER root

# install dependencies
RUN apt-get update && apt-get install -y python zip jq
# libmesos bundle
RUN curl -fsSL "$LIBMESOS_DOWNLOAD_URL" -o libmesos-bundle.tar.gz  \
  && echo "$LIBMESOS_DOWNLOAD_SHA256 libmesos-bundle.tar.gz" | sha256sum -c - \
  && tar -C / -xzf libmesos-bundle.tar.gz  \
  && rm libmesos-bundle.tar.gz
# update to newer git version
RUN echo "deb http://ftp.debian.org/debian testing main" >> /etc/apt/sources.list \
  && apt-get update && apt-get -t testing install -y git

# Override the default property for DNS lookup caching
RUN echo 'networkaddress.cache.ttl=60' >> ${JAVA_HOME}/jre/lib/security/java.security

# bootstrap scripts and needed dir setup
RUN mkdir -p "$JENKINS_HOME" "${JENKINS_FOLDER}/war"

# jenkins setup
COPY conf/config.xml "${JENKINS_STAGING}/config.xml"
COPY conf/nodeMonitors.xml "${JENKINS_STAGING}/nodeMonitors.xml"

# add plugins
RUN /usr/local/bin/install-plugins.sh       \
  ant:1.4                        \
  ace-editor:1.1                 \
  ansicolor:0.5.0                \
  antisamy-markup-formatter:1.5  \
  artifactory:2.10.4             \
  authentication-tokens:1.3      \
  azure-slave-plugin:0.3.4       \
  branch-api:2.0.9               \
  build-name-setter:1.6.5        \
  build-timeout:1.18             \
  cloudbees-folder:6.0.4         \
  conditional-buildstep:1.3.5    \
  config-file-provider:2.15.7    \
  copyartifact:1.38.1            \
  cvs:2.13                       \
  docker-build-publish:1.3.2     \
  docker-workflow:1.10           \
  durable-task:1.13              \
  ec2:1.36                       \
  embeddable-build-status:1.9    \
  external-monitor-job:1.7       \
  ghprb:1.36.2                   \
  git:3.3.0                      \
  git-client:2.4.5               \
  git-server:1.7                 \
  github:1.27.0                  \
  github-api:1.85                \
  github-branch-source:2.0.5     \
  github-organization-folder:1.6 \
  gitlab:1.4.5                   \
  gradle:1.26                    \
  greenballs:1.15                \
  handlebars:1.1.1               \
  ivy:1.27.1                     \
  jackson2-api:2.7.3             \
  job-dsl:1.61                   \
  jobConfigHistory:2.16          \
  jquery:1.11.2-0                \
  ldap:1.15                      \
  mapdb-api:1.0.9.0              \
  marathon:1.4.0                 \
  matrix-auth:1.5                \
  matrix-project:1.10            \
  maven-plugin:2.15.1            \
  mesos:0.14.1                   \
  metrics:3.1.2.9                \
  momentjs:1.1.1                 \
  monitoring:1.65.1              \
  nant:1.4.3                     \
  node-iterator-api:1.5.0        \
  pam-auth:1.3                   \
  parameterized-trigger:2.33     \
  pipeline-build-step:2.5        \
  pipeline-github-lib:1.0        \
  pipeline-input-step:2.7        \
  pipeline-milestone-step:1.3.1  \
  pipeline-model-definition:1.1.4 \
  pipeline-rest-api:2.6          \
  pipeline-stage-step:2.2        \
  pipeline-stage-view:2.6        \
  plain-credentials:1.4          \
  rebuild:1.25                   \
  role-strategy:2.4.0            \
  run-condition:1.0              \
  s3:0.10.12                     \
  saferestart:0.3                \
  saml:0.13                      \
  scm-api:2.1.1                  \
  ssh-agent:1.15                 \
  ssh-slaves:1.17                \
  timestamper:1.8.8              \
  translation:1.15               \
  variant:1.1                    \
  workflow-aggregator:2.5        \
  workflow-api:2.13              \
  workflow-basic-steps:2.4       \
  workflow-cps:2.30              \
  workflow-cps-global-lib:2.8    \
  workflow-durable-task-step:2.11 \
  workflow-job:2.10              \
  workflow-multibranch:2.14      \
  workflow-scm-step:2.4          \
  workflow-step-api:2.9          \
  workflow-support:2.14

# disable first-run wizard
RUN echo 2.0 > ${JENKINS_STAGING}/jenkins.install.UpgradeWizard.state

# RUN export LD_LIBRARY_PATH=/libmesos-bundle/lib:/libmesos-bundle/lib/mesos:$LD_LIBRARY_PATH \
#  && export MESOS_NATIVE_JAVA_LIBRARY=$(ls /libmesos-bundle/lib/libmesos-*.so)

CMD export LD_LIBRARY_PATH=/libmesos-bundle/lib:/libmesos-bundle/lib/mesos:$LD_LIBRARY_PATH \
  && export MESOS_NATIVE_JAVA_LIBRARY=$(ls /libmesos-bundle/lib/libmesos-*.so)   \
  && java ${JVM_OPTS}                                \
     -Dhudson.udp=-1                                 \
     -Djava.awt.headless=true                        \
     -Dhudson.DNSMultiCast.disabled=true             \
     -Djenkins.install.runSetupWizard=false          \
     -jar ${JENKINS_FOLDER}/jenkins.war              \
     ${JENKINS_OPTS}                                 \
     --httpPort=8080                                 \
     --webroot=${JENKINS_FOLDER}/war                 \
     --ajp13Port=-1                                  \
     --httpListenAddress=127.0.0.1                   \
     --ajp13ListenAddress=127.0.0.1                  \
     --argumentsRealm.passwd.admin=password          \
     --argumentsRealm.roles.user=admin               \
     --prefix=${JENKINS_CONTEXT}
