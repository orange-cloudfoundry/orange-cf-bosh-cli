# Cloud Foundry Bosh Cli deployed using docker
The `cf-bosh-cli` project helps you deploy bosh cli and associated tools through docker. Deploying all theses tools takes long time.

The tools deployed in this docker image are:

* `bosh client` – Client to interact with bosh directors (https://bosh.io/docs/bosh-cli.html)
* `cf client` – The official command line client for Cloud Foundry (https://github.com/cloudfoundry/cli)
* `cf-uaac client` – CloudFoundry UAA Command Line Client (https://github.com/cloudfoundry/cf-uaac)
* `spiff` – This is a command line tool and declarative YAML templating system, specially designed for generating BOSH deployment manifests (https://github.com/cloudfoundry-incubator/spiff)
* `spiff++` - Also known as spiff reloaded, spiff++ is a fork of spiff offering a rich set of new features not yet available in spiff (https://github.com/mandelsoft/spiff)
* `spruce` – This is a domain-specific YAML merging tool, for generating BOSH manifests (https://github.com/geofffranks/spruce)
* `bosh-gen` - Generators for creating and sharing BOSH releases (https://github.com/cloudfoundry-community/bosh-gen)
* `bosh-init` - A tool used to create and update the Director (its VM and persistent disk) in a BOSH environment (https://github.com/cloudfoundry/bosh-init)
* `cerstrap` - A simple certificate manager written in Go. Used by many bosh releases (https://github.com/square/certstrap)
* `git client` - The git client
* `ssh daemon`

The container expose ssh port (22). Password or key (rsa only) authentication is supported.

## How to get it or build it?

### How to get it?
Pull the image from docker hub: <code>docker pull orangecloudfoundry/orange-cf-bosh-cli</code>

### How to build it?
First, clone this repository: <code>git clone https://github.com/orange-cloudfoundry/orange-cf-bosh-cli.git</code>

Then, build the image: <code>docker build -t cf-bosh-cli .</code>

## How to use it?

### How to use as standalone container (if you have a simple docker host)

#### Without public ssh key provided to the container?

Launch the image. Don't miss to assign an host port to the container ssh port (22): <code>docker run --name cf-bosh-cli -d -p 2222:22 -v /home/bosh -v /data orangecloudfoundry/orange-cf-bosh-cli</code>

Then, log into the container with ssh: <code>ssh -p 2222 bosh@127.0.0.1</code>

The password at first logon is "welcome". Then, you have to change your password. When you are logged into the container, you must add your ssh public key into the file ~/.ssh/authorized_keys (RSA format). This last step will make the container secure after each restart/update (password auth will be disabled).

#### With public ssh key provided to the container?

It's also possible to add your public key to the container threw an environment variable.

Launch the image. Don't miss to assign an host port to the container ssh port (22): <code>docker run --name cf-bosh-cli -d -p 2222:22 -v /home/bosh -v /data -e "SSH_PUBLIC_KEY=< put here your ssh-rsa public key >" orangecloudfoundry/orange-cf-bosh-cli</code>

Then, log into the container with ssh: <code>ssh -p 2222 -i <path to your rsa private key> bosh@127.0.0.1</code>

The password in this case is completely disabled. By default, the file containing the public key (~/.ssh/authorized_keys) is overwrited after container restart or update. By setting the variable SSH_PUBLIC_KEY_DONT_OVERWRITE=true, this file is not overwrited if it already exists and is not empty.

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
    bind_ports:
    - "2222:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
	#This container will be provisioned with a publioc key. The other containers will use standard password authentication
    env_vars:
    - "SSH_PUBLIC_KEY=< put here your ssh-rsa public key >"
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

Then, log into the container you want with ssh: <code>ssh -p 2222 bosh@docker.bosh.release.deployment</code> to log into first container (replace docker.bosh.release.deployment with IP or dns name of docker host deployed using bosh release).

The password at first logon is "welcome". Then, you have to change your password. When you are logged into the container, you must add your ssh public key into the file ~/.ssh/authorized_keys (RSA format). This last step will make the container secure after each restart/update (password auth will be disabled).




#  SSH Private/Public key configuration



In this tutorial, we assume that you installed docker-bosh-cli in a single machine.

If you have multiple user, each one of them will use the same IP address with different port.
 
The default user is "bosh" and the default password is "welcome"

To log on to your docker container :

``` ssh -p Port bosh@ipAdresse```

Port : Port attributed to current user

ipAdresse : The IP adresse of the container (you can obtain it after installing docker-boch-cli using the command (```bosh instances``` )

At the first time you log on, you will be asked to change password. After changing it, your connexion will be closed and you will need to log on again with your new password.
In the case where your container is restarted or updated, your password will be reset to the default password "welcome".

To ensure the persistance of your password, you will need to use Private/Public Key auhtentification.


First of all, you need to generate your Private/Public key :
```
ssh-keygen -t RSA
```
The last commande will generate a pair of keys (public and private). You need to save the private key in a file that will be used to connect to your container.

The next step is to add your public key to your container. 

 * Log on in your container using your password
 * If the directory ~/.ssh does not exist:
```
mkdir -p ~/.ssh
chmod 700 ~/.
``` 
 * Copy the content of the public key (your_key.pub) into "~/.ssh/authorized_keys"
 * After copying the public key into the "authorized_keys" file, we need to ensure that we have the right permission.
```
chmod 600 ~/.ssh/authorized_keys
```

The last step is to log out from your container then try to log on using your private key:

``` ssh -p Port -i yourPrivateKey bosh@ipAdresse ```





