# Cloud Foundry Bosh Cli deployed using docker
The `cf-bosh-cli` project helps you deploy bosh cli and associated tools threw docker. Deploying all theses tools takes long time.

The tools deployed in this docker image are:

* `bosh client` – Client to interacte with bosh directors (https://bosh.io/docs/bosh-cli.html)
* `cf client` – The official command line client for Cloud Foundry (https://github.com/cloudfoundry/cli)
* `cf-uaac client` – CloudFoundry UAA Command Line Client (https://github.com/cloudfoundry/cf-uaac)
* `spiff` – This is a command line tool and declarative YAML templating system, specially designed for generating BOSH deployment manifests (https://github.com/cloudfoundry-incubator/spiff)
* `bosh-gen` - Generators for creating and sharing BOSH releases (https://github.com/cloudfoundry-community/bosh-gen)
* `bosh-init` - A tool used to create and update the Director (its VM and persistent disk) in a BOSH environment (https://github.com/cloudfoundry/bosh-init)
* `cerstrap` - A simple certificate manager written in Go. Used by many bosh releases (https://github.com/square/certstrap)
* `git client` - The git client
* `ssh daemon`

The container expose ssh port (22).

## How to build?

First, clone this repository: <code>git clone https://github.com/Orange-OpenSource/elpaaso-sandbox-service.git</code>

Then, build the image: <code>docker build -t cf-bosh-cli .</code>

## How to use?

If you have a simple docker host, launch the image. Don't miss to assign an host port to the container ssh port (22): <code>docker run -d -p 2222:22 cf-bosh-cli</code>

Then, log into the container threw ssh: <code>ssh -p 2222 bosh@127.0.0.1</code>

The password at first logon is "welcome".


Another option is to deploy the container threw the "Docker Bosh Release" (https://github.com/cloudfoundry-community/docker-boshrelease).
