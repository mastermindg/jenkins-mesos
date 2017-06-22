FROM jenkins:2.46.3
WORKDIR /tmp

# Build Args
ARG LIBMESOS_DOWNLOAD_URL=https://downloads.mesosphere.com/libmesos-bundle/libmesos-bundle-1.8.7-1.0.2-2.tar.gz
ARG LIBMESOS_DOWNLOAD_SHA256=9757b2e86c975488f68ce325fdf08578669e3c0f1fcccf24545d3bd1bd423a25
ARG BLUEOCEAN_VERSION=1.0.1
ARG JENKINS_STAGING=/usr/share/jenkins/ref/

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

RUN export LD_LIBRARY_PATH=/libmesos-bundle/lib:/libmesos-bundle/lib/mesos:$LD_LIBRARY_PATH \
  && export MESOS_NATIVE_JAVA_LIBRARY=$(ls /libmesos-bundle/lib/libmesos-*.so)   \
