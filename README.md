# Email OAuth 2.0 Proxy - Docker

Containerized Version of [Email OAuth 2.0 Proxy](https://github.com/simonrob/email-oauth2-proxy/) This runs in `--no-gui` mode.

This updated and modified version is based on a merge of [blacktirion/email-oauth2-proxy-docker](https://github.com/blacktirion/email-oauth2-proxy-docker) and [mirawara/email-oauth2-proxy-docker](https://github.com/mirawara/email-oauth2-proxy-docker)

## Docker Updates

This repository has an automated method that will rebuild the docker container if an issue is opened (see the issues tab). This is to accommodate any changes to the python on [Email OAuth 2.0 Proxy](https://github.com/simonrob/email-oauth2-proxy/). If this docker image is out of date, please submit that request and it will build automatically.

## Config File Placement

The config file should be named `emailproxy.config` and placed in whichever folder you map via Docker Run or Docker Compose. (The example is using `./config`)

Example (redacted):

```ini
[Email OAuth 2.0 Proxy configuration file]

[Server setup]

[SMTP-2465]
server_address = smtp.gmail.com
server_port = 465
local_address = 0.0.0.0

[Account setup]

[testuser@gmail.com]
permission_url = https://accounts.google.com/o/oauth2/auth
token_url = https://oauth2.googleapis.com/token
oauth2_scope = https://mail.google.com/
redirect_uri = http://localhost:8080
redirect_listen_address = http://0.0.0.0:80
client_id = *** your client id here ***
client_secret = *** your client secret here ***

[Advanced proxy configuration]

[emailproxy]
delete_account_token_on_password_error = True
encrypt_client_secret_on_first_use = False
use_login_password_as_client_credentials_secret = False
allow_catch_all_accounts = False

```

## Running the email OAuth2 proxy

The email OAuth2 proxy can be run using either Docker compose or Docker run.

### Docker compose

``` yaml
name: emailproxy
services:
    emailproxy:
        container_name: emailproxy
        environment:
            # CACHE_STORE: /config/credstore.config
            DEBUG: "true"
            LOCAL_SERVER_AUTH: "true"
            LOGFILE: "true"
        hostname: emailproxy
        image: ghcr.io/superjc710e/email-oauth2-proxy-docker:latest
        labels:
            icon: https://auth-email.com/static/img/logo.svg
        network_mode: bridge
        ports:
            - "2465:2465"
            - "8080:80"
        restart: always
        volumes:
            - ./config:/config
```

Put the compose details in a file named `docker-compose.yml` or `compose.yml` and run something like `docker compoose up -d` in the same directory.

This will create a new container with the email OAuth2 proxy and start it. In this example the proxy will be listening on port `2465` and will provide SMTP service.

The `volumes` section of the Docker compose file mounts the `./config` volume into the container. This volume contains the configuration files for the email OAuth2 proxy.

The `ports` section of the Docker compose file exposes port `2465` from the container to the host machine. This is the port that the email OAuth2 proxy listens on.

The `environment` section of the Docker compose file sets the following environment variables in the container:

- `LOGFILE`: Whether or not the email OAuth2 proxy should log to a file.
- `DEBUG`: Whether or not the email OAuth2 proxy should run in debug mode.
- `CACHE_STORE`: The path to the file that the email OAuth2 proxy will use to store its cache. This should always be stored in `/config/<filename>` This is because it needs to write to a persistent storage to keep the tokens. If using AWS Secrets Manager, see the main proxy github for more details. If you do not specify a cache store file, it will be written to the config file (`/config/emailproxy.config`).
- `LOCAL_SERVER_AUTH`: Puts the proxy in local server auth mode. See the proxy github for details. Defaults to external auth.

### Docker run

To run the email OAuth2 proxy using Docker run, use the following command:

```shell
docker run -d \
    --name emailproxy \
    -e DEBUG=false \
    -e CACHE_STORE=/config/credstore.config \
    -e LOGFILE=true \
    -e LOCAL_SERVER_AUTH=true \
    -v ./config:/config \
    -p 2465:2465 \
    -p 8080:80 \
    superjc710e/email-oauth2-proxy-docker:latest
```

This will create a new container with the email OAuth2 proxy and start it. In this example the proxy will be listening on port `2465` and will provide SMTP service.

### Windows Support

@gerneio [opened an issue regarding native windows support](https://github.com/blacktirion/email-oauth2-proxy-docker/issues/22). I do not use containers in windows, but he did put together a basic guide that can get you started. I will leave that issue open and pinned for now, just in case there are other questions. I cannot support this directly, as I am not familiar with windows docker images, but I will reply in thread if questions are asked. It seems pretty straightforward.

## Initial Token Retrieval

Getting the initial tokens can be more difficult in the containerized environment. It can be helpful to run an ssh tunnel to the host with the host port forwarded to the same host post on the ssh target.

For example:

```shell
ssh -L 8080:localhost:8080 <user>@<container_host>
```

Then you can initiate the token request using telnet (or other tools), for example (`base64` version of `testuser@gmail.com` and `testpassword` respectively, modify these to use the account specified in the config file, to do so you can run something like `echo "testuser@gmail.com" | base64 -w0` in a *nix environment. *The password does not need to be a real password, any password will trigger the OAuth process*):

```shell
{ sleep 6; echo "EHLO test.local"; sleep 1; echo "AUTH LOGIN"; sleep 1; echo "dGVzdHVzZXJAZ21haWwuY29tCg=="; sleep 1; echo "dGVzdHBhc3N3b3JkCg=="; sleep 5; } | telnet <container_host_ip_address> 2465
```

In another prompt, in the directory where you stored your compose file, follow the logs from the container, and access the link provided to complete the OAuth process (`CTRL+C` to exit). Open that link on the client system from which you SSH'd to the container host with the SSH tunnel.

Docker compose:

```shell
docker compose logs -f
```

Docker run (also works for compose method):

```shell
docker logs -f emailproxy
```

It is important to set these options in your configuration file:

```ini
redirect_uri = http://localhost:8080
redirect_listen_address = http://0.0.0.0:80
```

- Set `redirect_uri` to localhost, and the host_port of the container web ports (left side of port specification)
- Set `redirect_listen_address` to the listening address (`0.0.0.0` is a good choice) and the container_port of the web ports (right side of port specification)

## All Flags and Options

| Type | Flag | Description |
| --- | --- | --- |
| Name | `--name`/`container_name` | The name of the container. |
| Environment | `DEBUG=true` | Enables debug mode in logging. |
| Environment | `LOGFILE=true` | Outputs logs to a file in the config directory. Logs also still stream to docker logging daemon. |
| Environment | `LOCAL_SERVER_AUTH=true` | Puts the proxy in local server auth mode. See the proxy github for details. Defaults to external auth. |
| Environment | `CACHE_STORAGE=<path/to/file or AWS string>` | Allows storing the tokens and secrets in either a separate file or AWS Secrets Manager. If it is a file, it must be /config/\<filename\>. See the main proxy github for details.|
| Volume | `./config:/config` | Maps the `/config` directory in the container to a local folder/location. |
| Ports | `2465:2465` | Allows the docker daemon to forward all requests to the container on this port. This may change, depending on if you are using POP3 or other proxy methods. This particular method is for SMTP. |
| Ports | `8080:80` | Allows the docker daemon to forward all requests to the container on port 8080 and map to the proxy on port 80. Useful for the `LOCAL_SERVER_AUTH` flag. |
| Image | `ghcr.io/superjc710e/email-oauth2-proxy-docker` | The location/name of the image. This is published on Github Container Repository. |
