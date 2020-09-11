# Cloud Foundry Docker Bosh Cli [![Docker Automated build](docker_automated.svg)](https://hub.docker.com/r/orangecloudfoundry/orange-cf-bosh-cli/)
The `cf-bosh-cli` project helps you to deploy several cli tools through docker image:

## Installed tools

### Generic tools
* `apg` - Automated Password Generator
* `bosh` - Bosh directors V2 CLI (https://bosh.io/docs/cli-v2.html)
* `bosh-gen` - Generators for BOSH releases creation (https://github.com/cloudfoundry-community/bosh-gen)
* `cf` - Cloud Foundry CLI (https://github.com/cloudfoundry/cli)
* `credhub` - Credhub CLI (https://github.com/cloudfoundry-incubator/credhub-cli)
* `fly` - Concourse CLI (https://github.com/concourse/fly)
* `git` - Git client
* `jq` - JSON processing tool (https://stedolan.github.io/jq/)
* `spruce` - YAML templating tool, for BOSH deployment manifests generation (https://github.com/geofffranks/spruce)
* `terraform` - Provides a common configuration to launch infrastructure (https://www.terraform.io/)
* `uaac` - Cloud Foundry UAA CLI (https://github.com/cloudfoundry/cf-uaac)
* `yarn` - Package manager (https://yarnpkg.com/fr/)

### Admin tools
* `bbr` - Bosh Backup and Restore CLI (http://docs.cloudfoundry.org/bbr/)
* `gof3r` - Client for fast, parallelized and pipelined streaming access to S3 bucket (https://github.com/rlmcpherson/s3gof3r)
* `mc` - Minio S3 CLI (https://github.com/minio/mc)
* `mongo` - MongoDB shell CLI (https://docs.mongodb.com/manual/mongo/)
* `mysqlsh` - MySQL shell CLI (https://dev.mysql.com/doc/mysql-shell-excerpt/5.7/en/)
* `shield` - Shield CLI (https://docs.pivotal.io/partners/starkandwayne-shield/)

### Kubernetes tools
* `helm` - Kubernetes Package Manager (https://docs.helm.sh/)
* `kubectl` - Kubernetes CLI (https://kubernetes.io/docs/reference/generated/kubectl/overview/)
* `kapp` - Kubernetes YAML tool (https://github.com/k14s/kapp/)
* `klbd` - Kubernetes image build orchestrator tool (https://github.com/k14s/kbld/)
* `kustomize` Kubernetes template customize YAML files tool (https://github.com/kubernetes-sigs/kustomize/)
* `k9s` - Kubernetes CLI (https://github.com/derailed/k9s)
* `svcat` - Kubernetes Service Catalog CLI (https://github.com/kubernetes-sigs/service-catalog/)
* `ytt` - YAML Templating Tool (https://github.com/k14s/ytt/)
* `velero` - Kubernetes CLI for cluster resources backup/restore (https://github.com/vmware-tanzu/velero)

The container expose ssh port. Password or key (rsa only) authentication is supported.

## How to get it or build it

### How to get it
Pull the image from docker hub: <code>docker pull orangecloudfoundry/orange-cf-bosh-cli</code>

### How to build it
Clone the repository: <code>git clone https://github.com/orange-cloudfoundry/orange-cf-bosh-cli.git</code>

Then, build the image: <code>docker build -t cf-bosh-cli .</code>

## How to use it

### How to use as standalone container (if you have a simple docker host)

#### With public ssh key provided to the container

Launch the image. Don't miss to assign an host port to the container ssh port (22) :
<code>docker run --name bosh-cli -d -p 2222:22 -v /home/bosh -v /data -e "SSH_PUBLIC_KEY=<path to your public ssh-rsa key>" orangecloudfoundry/orange-cf-bosh-cli</code>

Then, log into the container with ssh : <code>ssh -p 2222 -i <path to your rsa private key> bosh@localhost</code>

The password is completely disabled. By default, the file containing the public key <code>~/.ssh/authorized_keys</code> is overwrited after container restart or update.

### How to use it using "Docker Bosh Release"
Another option is to deploy the container threw the "Docker Bosh Release" (https://github.com/cloudfoundry-community/docker-boshrelease).

In the following example:
* We deploy 1 instance of the container.
* The homedirectory of the bosh account is a private docker volume.
* The directory /data is a shared docker volume (from the container called "data_container").
* The first container has a provided public key.

Example of bosh deployment manifest:
```
deployment_name = 'bosh-cli'
static_ip = '10.203.7.100'
dns_servers = '10.203.6.102'
http_proxy = 'http:/proxy:3128'
https_proxy = 'http://proxy:3128'
docker_image = 'orangecloudfoundry/orange-cf-bosh-cli'
docker_tag = 'latest'
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
  containers:
  - name: data_container
    image: <%= docker_image %>:<%= docker_tag %>
    bind_volumes:
    - "/data"
    volumes:
    - "/etc/ssl/certs:/etc/ssl/certs:ro"
    - "/var/vcap/data/tmp/bosh-cli:/var/tmp/bosh-cli:ro"

  - name: user1_bosh_cli
    image: <%= docker_image %>:<%= docker_tag %>
    hostname: user1_bosh_cli
    env_vars:
    - "SSH_PUBLIC_KEY=<put here your ssh-rsa public key>"
    bind_ports:
    - "2222:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container

  - name: user2_bosh_cli
    image: <%= docker_image %>:<%= docker_tag %>
    hostname: user2_bosh_cli
    env_vars:
    - "SSH_PUBLIC_KEY=<put here your ssh-rsa public key>"
    bind_ports:
    - "2223:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
```

Then, log into the container you want with ssh : <code>ssh -i <path to your rsa private key> -p 2222 bosh@docker.bosh.release.deployment</code> to log into first container (replace docker.bosh.release.deployment with IP or dns name of docker host deployed using bosh release).

You can see cli/tools/aliases list by using the `tools` command from your shell interface.