#!/bin/bash
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

set -eu
sed -e "s,##APP_DOMAIN##,${CLOUDRON_APP_DOMAIN}," /app/code/nginx.conf  > /run/nginx.conf



echo "==> Starting supervisor"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i CouchDBApp
# cloudron supervisor instead
#echo "==> Starting couchdb"
#exec /opt/couchdb/bin/couchdb -couch_ini /app/data/default.ini
