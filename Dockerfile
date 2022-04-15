FROM cloudron/base:2.0.0@sha256:f9fea80513aa7c92fe2e7bf3978b54c8ac5222f47a9a32a7f8833edf0eb5a4f4
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

#########################################################
# CouchDB cloudron dockerfile
# based on official coucdb dockerfile https://github.com/apache/couchdb-docker
# admin:password default user available at default.ini

#0
######################################################### DIRECTORIES (start)
RUN echo "0 DIRECTORIES (start-deploy)"
RUN mkdir -p /app/code
RUN mkdir -p /app/data
RUN chown -R cloudron:cloudron /app/data
#WORKDIR /app/code
######################################################### DIRECTORIES (end)




#2
######################################################### COUCHDB REPO (start)
#RUN echo "1 POUCHDB (start-deploy)"
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN apt update && sudo apt install -y curl apt-transport-https gnupg
######################################################### COUCHDB REPO (end)

#3
######################################################### COUCHDB (start)
LABEL maintainer="CouchDB Developers dev@couchdb.apache.org"
# Add CouchDB user account to make sure the IDs are assigned consistently
RUN groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb
RUN apt-get update
# be sure GPG and apt-transport-https are available and functional
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        dirmngr \
        gnupg \
     ; \
    rm -rf /var/lib/apt/lists/*

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# grab gosu for easy step-down from root and tini for signal handling and zombie reaping
# see https://github.com/apache/couchdb-docker/pull/28#discussion_r141112407
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gosu; \
    rm -rf /var/lib/apt/lists/*; \
    gosu nobody true; \
    /tini --version


# http://docs.couchdb.org/en/latest/install/unix.html#installing-the-apache-couchdb-packages
ENV GPG_COUCH_KEY \
# gpg: rsa8192 205-01-19 The Apache Software Foundation (Package repository signing key) <root@apache.org>
    390EF70BB1EA12B2773962950EE62FB37A00258D
RUN set -eux; \
    apt-get update; \
    apt-get install -y curl; \
    export GNUPGHOME="$(mktemp -d)"; \
    curl -fL -o keys.asc https://couchdb.apache.org/repo/keys.asc; \
    gpg --batch --import keys.asc; \
    gpg --batch --export "${GPG_COUCH_KEY}" > /usr/share/keyrings/couchdb-archive-keyring.gpg; \
    command -v gpgconf && gpgconf --kill all || :; \
    rm -rf "$GNUPGHOME"; \
    apt-key list; \
    apt purge -y --autoremove curl; \
    rm -rf /var/lib/apt/lists/*

ENV COUCHDB_VERSION 3.2.1

RUN . /etc/os-release; \
    echo "deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couchdb-deb/ ${VERSION_CODENAME} main" | \
        tee /etc/apt/sources.list.d/couchdb.list >/dev/null

# https://github.com/apache/couchdb-pkg/blob/master/debian/README.Debian
RUN set -eux; \
    apt-get update; \
    \
    echo "couchdb couchdb/mode select none" | debconf-set-selections; \
# we DO want recommends this time
    DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
            couchdb="$COUCHDB_VERSION"~bionic \
    ; \
# Undo symlinks to /var/log and /var/lib
    rmdir /var/lib/couchdb /var/log/couchdb; \
    rm /opt/couchdb/data /opt/couchdb/var/log; \
    mkdir -p /app/data /opt/couchdb/var/log; \
    chown couchdb:couchdb /app/data /opt/couchdb/var/log; \
    chmod 777 /app/data /opt/couchdb/var/log; \
# Remove file that sets logging to a file
    rm /opt/couchdb/etc/default.d/10-filelog.ini; \
# Check we own everything in /opt/couchdb. Matches the command in dockerfile_entrypoint.sh
    find /opt/couchdb \! \( -user couchdb -group couchdb \) -exec chown -f couchdb:couchdb '{}' +; \
# Setup directories and permissions for config. Technically these could be 555 and 444 respectively
# but we keep them as 755 and 644 for consistency with CouchDB defaults and the dockerfile_entrypoint.sh.
    find /opt/couchdb/etc -type d ! -perm 0755 -exec chmod -f 0755 '{}' +; \
    find /opt/couchdb/etc -type f ! -perm 0644 -exec chmod -f 0644 '{}' +; \
# apt clean-up
    rm -rf /var/lib/apt/lists/*;
######################################################### COUCHDB (end)



#1
######################################################### FILES (start)
RUN echo "2 WEBAPP (start-deploy)"
# copy code
COPY start.sh /app/code/


#production run
COPY prod.sh /app/code/
RUN chmod +x /app/code/prod.sh

#default couchdb configuration
COPY default.ini /app/data/default.ini

COPY supervisor/app.conf /etc/supervisor/conf.d/app.conf
COPY supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf

RUN ln -sf /run/supervisord.log /var/log/supervisor/supervisord.log
# copy code
COPY dist/ /app/code/
# lock www-data but allow su - www-data to work
RUN passwd -l www-data && usermod --shell /bin/bash --home /app/data www-data
######################################################### FILES (end)




######################################################### nginxs (start)
# add nginx config

#RUN rm /etc/nginx/sites-enabled/*


COPY nginx.conf /app/code/nginx.conf
COPY nginx_readonlyrootfs.conf /etc/nginx/conf.d/readonlyrootfs.conf

# ensure that data directory is owned by 'cloudron' user
RUN chown -R cloudron:cloudron /app/code
RUN chown -R cloudron:cloudron /app/data
RUN chown -R cloudron:cloudron /run
#RUN sed -e "s,##APP_DOMAIN##,${CLOUDRON_APP_DOMAIN}," /app/code/nginx.conf  > /run/nginx.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

#start couchdb
#ENTRYPOINT ["/tini", "--", "/app/code/start.sh"]
#fix startup single node missing tables


#VOLUME /app/data
# 5984: Main CouchDB endpoint
# 4369: Erlang portmap daemon (epmd)
# 9100: CouchDB cluster communication port
EXPOSE 5984 4369 9100 8000 3000
#CMD ["/opt/couchdb/bin/couchdb -couch_ini /app/data/default.ini" ]
CMD ["/app/code/start.sh","/app/code/prod.sh"]
