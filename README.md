# xrdp docker

Runs Ubuntu 22.04 Mate Desktop environment in a docker container and connects through xrdp

## Usage

1. Build the image
   ```shell
   docker build -t xrdp-docker .
   ```


2. Run the container
   ```shell
   docker run -d --shm-size=1g --name xrdp-docker --hostname xrdp-docker --restart always -e USERNAME=xrdp -e PASSWORD=xrdp -p 3389:3389 --cap-add SYS_ADMIN xrdp-docker
   ```

3. Use Microsoft Remote Desktop Client to connect
