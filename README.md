# Cloud Foundry Bosh Cli deployed using docker [![Docker Automated buil](https://img.shields.io/docker/automated/jrottenberg/ffmpeg.svg?style=plastic)](https://hub.docker.com/r/orangecloudfoundry/orange-cf-bosh-cli/)

The `cf-bosh-cli` project helps you to deploy bosh cli and associated tools through docker.

The tools deployed in this docker image are:

* `git client` - Git client
* `bosh-init` - Tool used to create and update (its VM and persistent disk) BOSH Director (https://github.com/cloudfoundry/bosh-init)
* `bosh-gen` - Generators for creating and sharing BOSH releases (https://github.com/cloudfoundry-community/bosh-gen)
* `bosh client V1` - Bosh directors V1 command line client (https://bosh.io/docs/bosh-cli.html)
* `bosh client V2` - Bosh directors V2 command line client (https://bosh.io/docs/cli-v2.html)
* `spiff` - YAML templating system, for generating BOSH deployment manifests (https://github.com/cloudfoundry-incubator/spiff)
* `spiff++` - Also known as spiff reloaded, spiff++ is a spiff enhanced fork (https://github.com/mandelsoft/spiff)
* `spruce` - YAML templating system, for generating BOSH deployment manifests (https://github.com/geofffranks/spruce)
* `cf client` - Cloud Foundry command line client (https://github.com/cloudfoundry/cli)
* `cf-uaac client` - Cloud Foundry UAA command line client (https://github.com/cloudfoundry/cf-uaac)
* `shield` - Shield command line client (backup)(https://github.com/starkandwayne/shield)
* `terraform` - Provides a common configuration to launch infrastructure (https://www.terraform.io/)
* `terraform-provider-cloudfoundry` - Terraform plugin for Cloudfoundry (https://github.com/orange-cloudfoundry/terraform-provider-cloudfoundry)
* `fly` - Concourse command line client (https://github.com/concourse/fly)
* `credhub` - Credhub command line client (https://github.com/cloudfoundry-incubator/credhub-cli)
* `cerstrap` - Simple certificate manager, used by many bosh releases (https://github.com/square/certstrap)
* `gof3r` - Client for fast, parallelized and pipelined streaming access to S3 bucket (https://github.com/rlmcpherson/s3gof3r)
* `jq` - Tool for processing JSON inputs (https://stedolan.github.io/jq/)
* `ruby` - Ruby Programming Language (https://www.ruby-lang.org/)
* `go` - Go Programming Language (https://golang.org/)

The container expose ssh port. Password or key (rsa only) authentication is supported.

## How to get it or build it ?

### How to get it ?
Pull the image from docker hub: <code>docker pull orangecloudfoundry/orange-cf-bosh-cli</code>

### How to build it ?
First, clone this repository: <code>git clone https://github.com/orange-cloudfoundry/orange-cf-bosh-cli.git</code>

Then, build the image: <code>docker build -t cf-bosh-cli .</code>

## How to use it ?

### How to use as standalone container (if you have a simple docker host)

#### Without public ssh key provided to the container

Launch the image. Don't miss to assign an host port to the container ssh port (22) :
<code>docker run --name cf-bosh-cli -d -p 2222:22 -v /home/bosh -v /data orangecloudfoundry/orange-cf-bosh-cli</code>

Then, log into the container with ssh : <code>ssh -p 2222 bosh@127.0.0.1</code>

The password at first logon is "welcome" (you have to change your password). When you are logged into the container, you must add your ssh public key into the file <code>~/.ssh/authorized_keys</code> (RSA format). This last step will make the container secure after each restart/update (password auth will be disabled).

#### With public ssh key provided to the container

It's also possible to add your public key to the container threw an environment variable.

Launch the image. Don't miss to assign an host port to the container ssh port (22) :
<code>docker run --name cf-bosh-cli -d -p 2222:22 -v /home/bosh -v /data -e "SSH_PUBLIC_KEY=<put here your ssh-rsa public key>" orangecloudfoundry/orange-cf-bosh-cli</code>

Then, log into the container with ssh : <code>ssh -p 2222 -i <path to your rsa private key> bosh@127.0.0.1</code>

The password in this case is completely disabled. By default, the file containing the public key <code>~/.ssh/authorized_keys</code> is overwrited after container restart or update. By setting the variable <code>SSH_PUBLIC_KEY_DONT_OVERWRITE=true</code>, this file is not overwrited if it already exists and is not empty.

### How to use it using "Docker Bosh Release"

Another option is to deploy the container threw the "Docker Bosh Release" (https://github.com/cloudfoundry-community/docker-boshrelease).

In the following example:
* We deploy 1 instance of the container.
* The homedirectory of the bosh account is a private docker volume.
* The directory /data is a shared docker volume (from the container called "data_container").
* The first container has a provided public key.

Example of bosh deployment manifest:
```
<%
director_uuid = 'fa2a0823-b875-4fe3-9bf1-3de6a9bdddb8'
deployment_name = 'bosh-cli'
static_ip = '10.203.7.100'
dns_servers = '10.203.6.102'
http_proxy = 'http:/proxy:3128'
https_proxy = 'http://proxy:3128'
docker_image = 'orangecloudfoundry/orange-cf-bosh-cli'
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
    #This container will be provisioned with a publioc key. The other containers will use standard password authentication
    - "SSH_PUBLIC_KEY=< put here your ssh-rsa public key >"
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
```

Then, log into the container you want with ssh : <code>ssh -i privateKey -p 2222 bosh@docker.bosh.release.deployment</code> to log into first container (replace docker.bosh.release.deployment with IP or dns name of docker host deployed using bosh release).
