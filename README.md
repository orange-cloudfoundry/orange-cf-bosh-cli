# Cloud Foundry Bosh Cli deployed using docker
The `cf-bosh-cli` project helps you deploy bosh cli and associated tools threw docker. Deploying all theses tools takes long time.

The tools deployed in this docker image are:

* `bosh client` – Client to interacte with bosh directors (https://bosh.io/docs/bosh-cli.html)
* `cf client` – The official command line client for Cloud Foundry (https://github.com/cloudfoundry/cli)
* `cf-uaac client` – CloudFoundry UAA Command Line Client (https://github.com/cloudfoundry/cf-uaac)
* `spiff` – This is a command line tool and declarative YAML templating system, specially designed for generating BOSH deployment manifests (https://github.com/cloudfoundry-incubator/spiff)
* `spruce` – This is a domain-specific YAML merging tool, for generating BOSH manifests (https://github.com/geofffranks/spruce)
* `bosh-gen` - Generators for creating and sharing BOSH releases (https://github.com/cloudfoundry-community/bosh-gen)
* `bosh-init` - A tool used to create and update the Director (its VM and persistent disk) in a BOSH environment (https://github.com/cloudfoundry/bosh-init)
* `cerstrap` - A simple certificate manager written in Go. Used by many bosh releases (https://github.com/square/certstrap)
* `git client` - The git client
* `ssh daemon`

The container expose ssh port (22).

## How to get it or build it?

### How to get it?
Pull the image from docker hub: <code>docker pull orangeopensource/orange-cf-bosh-cli</code>

### How to build it?
First, clone this repository: <code>git clone https://github.com/Orange-OpenSource/orange-cf-bosh-cli.git</code>

Then, build the image: <code>docker build -t cf-bosh-cli .</code>

## How to use it?

### How to use as standalone container?

If you have a simple docker host, launch the image. Don't miss to assign an host port to the container ssh port (22): <code>docker run -d -p 2222:22 cf-bosh-cli</code>

Then, log into the container with ssh: <code>ssh -p 2222 bosh@127.0.0.1</code>

The password at first logon is "welcome". Then, you have to change your password. When you are logged into the container, you can add your ssh public key into the file ~/.ssh/authorized_keys.

### How to use it using "Docker Bosh Release"

Another option is to deploy the container threw the "Docker Bosh Release" (https://github.com/cloudfoundry-community/docker-boshrelease).

In the following example:
* We deploy 4 instances of the container.
* The homedirectory of the bosh account is a private docker volume.
* The directory /data is a shared docker volume (from the container called "data_container").

Example of bosh deployment manifest:
```
<%
director_uuid = 'fa2a0823-b875-4fe3-9bf1-3de6a9bdddb8'
deployment_name = 'bosh-cli'
static_ip = '10.203.7.100'
dns_servers = '10.203.6.102'
http_proxy = 'http:/proxy:3128'
https_proxy = 'http://proxy:3128'
docker_image = 'orangeopensource/orange-cf-bosh-cli'
docker_tag = 'latest'
%>
---
name: <%= deployment_name %>
director_uuid: <%= director_uuid %>

releases:
 - name: docker
   version: latest

compilation:
  workers: 1
  network: default
  reuse_compilation_vms: true
  cloud_properties:
    cpu: 1
    disk: 8096
    ram: 2048

update:
  canaries: 0
  canary_watch_time: 30000-1200000
  update_watch_time: 30000-1200000
  max_in_flight: 32
  serial: false

networks:
- name: default
  type: manual
  subnets:
    - range: 10.203.6.0/23
      reserved:
      - 10.203.6.1-10.203.7.99
      - 10.203.7.102-10.203.7.253
      static:
      - <%= static_ip %>
      gateway: 10.203.7.254
      dns: [<%= dns_servers %>]
      cloud_properties:
        name: NET

resource_pools:
- name: default
  stemcell:
    name: bosh-vcloud-esxi-ubuntu-trusty-go_agent
    version: latest
  network: default
  cloud_properties:
    ram: 512
    disk: 4_096
    cpu: 2

jobs:
  - name: bosh-cli
    templates:
      - name: docker
      - name: containers
    instances: 1
    resource_pool: default
    persistent_disk: 102_400
    networks:
      - name: default
        default: [dns, gateway]
        static_ips:
          - <%= static_ip %>

properties:
  env:
    http_proxy: "<%= http_proxy %>"
    https_proxy: "<%= https_proxy %>"
  containers:
  - name: data_container
    image: <%= docker_image %>:<%= docker_tag %>
    volumes:
    - /data
  - name: &user1_bosh_cli user1_bosh_cli
    image: <%= docker_image %>:<%= docker_tag %>
    hostname: *user1_bosh_cli
    env_vars:
    - "http_proxy=<%= http_proxy %>"
    - "https_proxy=<%= https_proxy %>"
    bind_ports:
    - "2222:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
  - name: &user2_bosh_cli user2_bosh_cli
    image: <%= docker_image %>:<%= docker_tag %>
    hostname: *user2_bosh_cli
    env_vars:
    - "http_proxy=<%= http_proxy %>"
    - "https_proxy=<%= https_proxy %>"
    bind_ports:
    - "2223:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
  - name: &user3_bosh_cli user3_bosh_cli
    image: <%= docker_image %>:<%= docker_tag %>
    hostname: *user3_bosh_cli
    env_vars:
    - "http_proxy=<%= http_proxy %>"
    - "https_proxy=<%= https_proxy %>"
    bind_ports:
    - "2224:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
  - name: &user4_bosh_cli user4_bosh_cli
    image: <%= docker_image %>:<%= docker_tag %>
    hostname: *user4_bosh_cli
    env_vars:
    - "http_proxy=<%= http_proxy %>"
    - "https_proxy=<%= https_proxy %>"
    bind_ports:
    - "2225:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
```

Then, log into the container you want with ssh: <code>ssh -p 2222 bosh@127.0.0.1</code> to log into first container.

The password at first logon is "welcome". Then, you have to change your password. When you are logged into the container, you can add your ssh public key into the file ~/.ssh/authorized_keys.

