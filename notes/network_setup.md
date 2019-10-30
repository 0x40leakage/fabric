# network_setup.sh

```bash
# The arguments must be in order.
# UP_DOWN="$1"
# CH_NAME="$2"
# CLI_TIMEOUT="$3"
# IF_COUCHDB="$4"
./network_setup <up|down> <$channel-name> <$cli_timeout> <couchdb>.
```

- By default Compose sets up a single network for your app. 
- Each container for a service joins the default network and is both *reachable* by other containers on that network, and *discoverable* by them at a hostname identical to the container name. 
    - Your app’s network is given a name based on the “project name”, which is based on the name of the directory it lives in. You can override the project name with either the `--project-name` flag or the `COMPOSE_PROJECT_NAME` environment variable.
- Example

    ```yaml
    # in a directory called myapp
    version: "3"
    services:
      web:
        build: .
          ports:
          - "8000:8000"
      db:
          image: postgres
          ports:
          - "8001:5432"
    ```

    - When you run `docker-compose up`, the following happens:
        1. A network called `myapp_default` is created.
        2. A container is created using `web`’s configuration. It joins the network `myapp_default` under the name `web`.
        3. A container is created using `db`’s configuration. It joins the network `myapp_default` under the name `db`.
    - Each container can now look up the hostname `web` or `db` and get back the appropriate container’s IP address.
        - For example, `web`’s application code could connect to the URL `postgres://db:5432` and start using the Postgres database.
    - It is important to note the distinction between `HOST_PORT` and `CONTAINER_PORT`. 
        - In the above example, for `db`, the `HOST_PORT` is `8001` and the container port is `5432` (postgres default). 
        - Networked service-to-service communication use the `CONTAINER_PORT`. 
        - When `HOST_PORT` is defined, the service is accessible **outside** the swarm as well.
        - Within the `web` container, your connection string to `db` would look like `postgres://db:5432`, and from the host machine, the connection string would look like `postgres://{DOCKER_IP}:8001`.
- > https://docs.docker.com/compose/networking/
## generateArtifacts.sh

```bash
# FABRIC_ROOT: /home/centos/go/src/github.com/hyperledger/fabric
# FABRIC_CFG_PATH: /home/centos/go/src/github.com/hyperledger/fabric/examples/e2e_cli
```