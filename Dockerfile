# Copyright 2016 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------------------------------------------------------------------------
#
# This is a Dockerfile for hawkular-services.
#

# FROM brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888/jboss-eap-7-tech-preview/eap70
FROM jboss-eap-7-tech-preview/eap70:1.2-41

# These versions are autmatically updated by ETT when the build is started using the UI
# ett_version comes from the package "Version" column in the ETT Task
# named_version comes from the MEAD build from where the archive(s) will come (see last-mead-build)
ENV ett_version=7.0.0
ENV named_version=0.23.0.Final-redhat-1

# The Version label must not include any dashes due to brew import NVR rules
LABEL BZComponent="hawkular-services-docker" \
      Architecture="x86_64" \
      Name="hawkular/hawkular-services" \
      Version="%{named_version}"

# AS_ROOT is the location of the app server inherited from the base container
# HAWKULAR_HOME is the location of hawkular installed in the app server, can be a link to the AS_ROOT
ENV HAWKULAR_VERSION=%{ett_version} \
    HAWKULAR_HOME=/opt/hawkular \
    HAWKULAR_DATA_DIR=/var/opt/hawkular \
    AS_ROOT=/opt/eap \
    HAWKULAR_BACKEND=cassandra \
    JAVA_OPTS="-Xms64m -Xmx512m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=$JBOSS_MODULES_SYSTEM_PKGS -Djava.awt.headless=true -agentlib:jdwp=transport=dt_socket,address=8787,server=y,suspend=n" \
    HAWKULAR_AGENT_ENABLE=true \
    ADD_HAWKULAR_USER=true \
    HAWKULAR_USERNAME=jdoe \
    HAWKULAR_PASSWORD=password \
    CASSANDRA_NODES=myCassandra \
    HAWKULAR_METRICS_TTL=14 \
    HAWKULAR_INVENTORY_JDBC_URL= \
    HAWKULAR_INVENTORY_JDBC_USERNAME= \
    HAWKULAR_INVENTORY_JDBC_PASSWORD=

EXPOSE 8080 8443 8787

# Install any necessary packages from jboss yum repo
USER root
ADD jboss.repo /etc/yum.repos.d/jboss.repo
RUN yum install -y --disablerepo=\* --enablerepo=jboss-rhel-\* hostname nmap-ncat \
    && yum clean all \
    && rm /etc/yum.repos.d/jboss.repo

# Install Hawkular Services
COPY hawkular-services-dist-docker-${HAWKULAR_VERSION}-docker-dist.zip \
     hawkular-start.sh \
     check-cnode.sh \
     /tmp/
RUN ln -s ${AS_ROOT} ${HAWKULAR_HOME} \
    && mv /tmp/hawkular-start.sh /tmp/check-cnode.sh ${HAWKULAR_HOME} \
    && unzip -q /tmp/hawkular-services-dist-docker-${HAWKULAR_VERSION}-docker-dist.zip -d /tmp \
    && rm -rf /tmp/hawkular-services-dist-docker-${HAWKULAR_VERSION}/opt/hawkular \
    && cp -R /tmp/hawkular-services-dist-docker-${HAWKULAR_VERSION}/opt/* /opt \
    && rm -rf /tmp/hawkular-services-dist-docker-${HAWKULAR_VERSION} \
    && rm -f /tmp/hawkular-services-dist-docker-${HAWKULAR_VERSION}-docker-dist.zip \
    && mkdir -p ${HAWKULAR_DATA_DIR} \
    && chown -R jboss:jboss ${HAWKULAR_HOME} ${HAWKULAR_DATA_DIR} \
    && chmod -R 0755 ${HAWKULAR_HOME} ${HAWKULAR_DATA_DIR}

# The "jboss" user id inherited from jboss-base container
USER 185

CMD /opt/hawkular/hawkular-start.sh

