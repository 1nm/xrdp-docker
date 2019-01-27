# Usage

```
docker build -t xrdp-docker .
docker run -d --shm-size=1g --name xrdp-docker --hostname xrdp-docker --restart always -e USERNAME=xrdp -e PASSWORD=xrdp -p 3389:3389 --cap-add SYS_ADMIN xrdp-docker
```
