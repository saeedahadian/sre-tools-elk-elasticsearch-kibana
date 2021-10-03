# Elastic Stack

This is the basic setup for running an Elastic stack cluster to monitor _servers_ and _services_. It is consisted of 3 elasticsearch nodes and 1 kibana instance by default but the configuration and number of nodes could be changed on demand. The cluster will run with SSL/TLS enabled.

## Initialization

### Environment Variables

First off, you need to set some basic environment variables like different paths and version numbers. Use the sample file and change it based on your needs.

```bash
cp .env.sample .env
```

### Generating TLS Certificates

To run the cluster, first generate your certificates. You need to have an understanding of your stack and edit the `instances.yml` file based on your specific design. So, copy the sample file in a `instances.yml` file and change it based on your preferations. 

```bash
cp instances.yml.sample instances.yml
```

When `instances.yml` was completed, use this command to generate certificates for the cluster:

```bash
docker-compose -f create-certs.yml run --rm create-certs
```

Note that by running this command, you only generate certificates for _internode communications_ but you still need certificates for _RESTful HTTP clients_ to be able to interact with the server using TLS. To achieve this, run an ephemeral elasticsearch container with the `elastic-certs` volume:

```bash
docker run --rm -it --volume elastic-certs:/certs elasticsearch/elasticsearch:7.15.0 bash
```

Then, run this command to generate HTTP certificates.

```bash
/bin/elasticsearch-certutil http
```

Answer questions accordingly. Give the list of all your elasticsearch hosts when asked. This command will finally generate a `elasticsearch-ssl-http.zip` file. Unzip this file into the certs directory so that it gets stored in the volume.

```bash
unzip elasticsearch-ssl-http.zip -d /certs
```

Congrats! Now you have all the necessary certificates to run the elastic stack.

#### Transfering Certificates to Other Servers

To move certificates from one server to another, there is a bash script which makes it a lot easier. What it basically does is to create a temporary docker container with the certs volume and then compressing and moving the certificates to a mounted location on the host.

```bash
# To backup certificates on the original server.
chmod +x use-volume.sh
./use-volume.sh backup elastic-certs

# To restore certificates as a docker volume on the target server.
chmod +x use-volume.sh
./use-volume.sh restore elastic-certs
```

### Nodes Discovery

Elasticsearch needs to know where to search for nodes that should be joined to the current cluster. These nodes could be added as an environment variable but if the number of nodes grow beyond a handful, adding them as an environment variable might be hard. For this purpose, we only need to take a copy of `unicast_hosts.txt` file and change it based on our own nodes.

```bash
cp unicast_hosts.txt.sample unicast_hosts.txt
```

This file should be mounted on elastic's config directory. It will be automatically recognized by elasticsearch while starting.

### Generating Passwords for Built-in Users

After running the cluster, you need to first generate passwords for Elastic _built-in_ users by running this command:

```bash
docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords \
auto --batch \
--url https://es01:9200"
```

It will output passwords for all _built-in_ users. Then, stop the Kibana service and update `docker-compose.yml` file with username and password for kibana.
