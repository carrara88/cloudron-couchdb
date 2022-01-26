# CouchDB Cloudron README

CouchDB Cloudron docker app to deploy DB with Fauxton.

- Cloudron authentication on Fauxton path "/_utils"
- CouchDB configuration on default.ini file


## Build dockerfile image

To build dockerfile image from source files run:
```
docker build -t your-docker-user/cloudron-couchdb .
```

To push docker image into docker-hub from source files run:
```
docker push your-docker-user/cloudron-couchdb
```
## Install on Cloudron from Docker-Hub with Cloudron CLI
To install docker image into cloudron from docker-hub run:
 ```
cloudron install --image your-docker-user/cloudron-couchdb
```


