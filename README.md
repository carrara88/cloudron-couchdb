# CouchDB Cloudron README

CouchDB Cloudron docker app reeady to deploy.
Available also as docker-image ready for Cloudron deploy from docker-hub: (Docker Hub Image)[https://hub.docker.com/r/terapolis/cloudron-couchdb]

- Cloudron `proxyAuth` authentication layer on path `/_utils` for extendeed security
- CouchDB configuration on `default.ini` file available on cloudron file manager under `app/data` folder
- Ready for CORS on `localhost` and `localhost:4200`

### IMPORTANT! ADMINISTRATION PASSWORD
IMPORTANT! Change `administrator=password123` from default.ini file. Password will be auto-encrypted on first run.

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


