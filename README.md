# Cloud Foundry Docker Bosh cli [![Docker Automated build](build_automated.svg)](https://github.com/orange-cloudfoundry/orange-cf-bosh-cli/pkgs/container/orange-cf-bosh-cli)
`cf-bosh-cli` is used to deploy several cli tools through docker image.  
The container expose ssh port. Password or key (rsa only) authentication is supported.

## Installed tools

### Bosh tools
* `bbr` - Bosh Backup and Restore cli (http://docs.cloudfoundry.org/bbr/)
* `bosh` - Bosh cli (https://bosh.io/docs/cli-v2.html)
* `bosh-gen` - Bosh releases creation (https://github.com/cloudfoundry-community/bosh-gen)
* `cf` - Cloud Foundry cli (https://github.com/cloudfoundry/cli)
* `credhub` - Credhub cli (https://github.com/cloudfoundry-incubator/credhub-cli)
* `fly` - Concourse cli (https://github.com/concourse/fly)
* `uaac` - Cloud Foundry UAA cli (https://github.com/cloudfoundry/cf-uaac)
* `shield` - Shield cli (https://docs.pivotal.io/partners/starkandwayne-shield/)

### Kubernetes tools
* `argo` - Kubernetes workflow management (https://argoproj.github.io/argo-workflows/)
* `cilium` - Kubernetes cilium network management (https://github.com/cilium/cilium-cli)
* `cnpg` - Cloud Native Postgres cli (https://github.com/cloudnative-pg/cloudnative-pg)
* `crossplane` - Kubernetes crossplane (https://docs.crossplane.io/latest/cli)
* `flux` - Kubernetes Gitops management (https://fluxcd.io/docs/cmd/)
* `helm` - Kubernetes Package Manager (https://docs.helm.sh/)
* `hubble` - Kubernetes Monitoring management (https://github.com/cilium/hubble/)
* `klbd` - Kubernetes image build orchestrator tool (https://github.com/k14s/kbld/)
* `kubectl` - Kubernetes cli (https://kubernetes.io/docs/reference/generated/kubectl/overview/)
* `kyverno` Kubernetes policy engine (https://github.com/kyverno/kyverno/)
* `k9s` - Kubernetes cli (https://github.com/derailed/k9s)
* `loki` - Loki cli (https://github.com/grafana/loki/)
* `nu` - NuShell cli (https://github.com/nushell/nushell/)
* `oc` - Openshift cli (https://docs.openshift.com/dedicated/welcome/)
* `pinniped` - Identity services cli (https://github.com/vmware-tanzu/pinniped/)
* `oc` - Openshift cli (https://docs.openshift.com/dedicated/welcome/)
* `rbac-tool` - Rbac cli (https://github.com/alcideio/rbac-tool/)
* `task` - Task runner cli (https://github.com/go-task/task/)
* `vault` - Vault cli (https://releases.hashicorp.com/vault/)
* `vcluster` - VCluster cli (https://github.com/loft-sh/vcluster/)

### Other tools
* `cmctl` - Cert-manager cli (https://github.com/cert-manager/cmctl)
* `gcloud` - Google Cloud Platform cli (https://cloud.google.com/sdk/gcloud)
* `git` - Git cli
* `git-filter-repo` - Git rewriting history tool (https://github.com/newren/git-filter-repo)
* `govc` - Vsphere cli (https://github.com/vmware/govmomi/tree/master/govc/)
* `mc` - Minio S3 cli (https://github.com/minio/mc)
* `jq` - JSON processing tool (https://stedolan.github.io/jq/)
* `mdless` - Provides a formatted and highlighted view of Markdown files in Terminal (https://github.com/ttscoff/mdless)
* `mongo` - MongoDB shell cli for bosh (https://docs.mongodb.com/manual/mongo/)
* `mongosh` - MongoDB shell cli for k8s (https://docs.mongodb.com/manual/mongo/)
* `mysqlsh` - MySQL shell cli (https://dev.mysql.com/doc/mysql-shell-excerpt/5.7/en/)
* `redis` - Redis cli (https://redis.io/topics/rediscli/)
* `spruce` - YAML templating tool, for Bosh deployment manifests generation (https://github.com/geofffranks/spruce)
* `terraform` - Terraform cli (https://www.terraform.io/)
* `vendir` - Define and fetch components to target directory (https://github.com/vmware-tanzu/carvel-vendir/)
* `yarn` - Package manager (https://yarnpkg.com/fr/)
* `ytt` - YAML Templating Tool (https://github.com/k14s/ytt/)

## How to get it or build it

### How to get it
Pull the image from github container registry:  
<code>docker pull ghcr.io/orange-cloudfoundry/orange-cf-bosh-cli:<image_tag></code>

### How to build it
Clone the repository:  
<code>git clone https://github.com/orange-cloudfoundry/orange-cf-bosh-cli.git</code>

Then, build the image:  
<code>docker build -t cf-bosh-cli:<image_tag> .</code>

## How to use it

>**Note:**  
> When connected, you can see cli/tools/aliases list with `tools` command from shell interface.

### How to use as standalone container (if you have a simple docker host)

#### With public ssh key provided to the container

Launch the image (don't miss to assign an host port to the container ssh port 22) :  
<code>docker run --name bosh-cli -d -p 2222:22 -v /home/bosh -v /data -e "SSH_PUBLIC_KEY=<path_to_your_public_ssh-rsa_key>" orangecloudfoundry/orange-cf-bosh-cli</code>

Then, log into the container with ssh :  
<code>ssh -p 2222 -i <path_to_your_rsa_private_key> bosh@localhost</code>

The password is completely disabled. By default, the file containing the public key <code>~/.ssh/authorized_keys</code> is overwrited after container restart or update.

### How to use it using "Docker Bosh Release"
Another option is to deploy the container threw the "Docker Bosh Release" (https://github.com/cloudfoundry-community/docker-boshrelease).

In the following example:
* We deploy 1 instance of the container.
* The homedirectory of the bosh account is a private docker volume.
* The directory /data is a shared docker volume (from the container called "data_container").
* The first container has a provided public key.

Bosh deployment manifest exmple:

```
deployment_name = 'bosh-cli'
static_ip = 'xx.xx.xx.xx'
dns_servers = 'xx.xx.xx.xx'
http_proxy = 'http://proxy:3128'
https_proxy = 'http://proxy:3128'
docker_image = 'orangecloudfoundry/orange-cf-bosh-cli'
docker_tag = 'latest'
---
name: <deployment_name>
director_uuid: <director_uuid>

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
    - range: xx.xx.xx.xx/xx
      reserved:
      - xx.xx.xx.xx-xx.xx.xx.xx
      static:
      - <static_ip>
      gateway: xx.xx.xx.xx
      dns: [<dns_servers>]
      cloud_properties:
        name: NET

resource_pools:
- name: default
  stemcell:
    name: xxx
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
          - <static_ip>

properties:
  containers:
  - name: data_container
    image: <docker_image>:<docker_tag>
    bind_volumes:
    - "/data"
    volumes:
    - "/etc/ssl/certs:/etc/ssl/certs:ro"
    - "/var/vcap/data/tmp/bosh-cli:/var/tmp/bosh-cli:ro"

  - name: user1_bosh_cli
    image: <docker_image>:<image_tag>
    hostname: user1_bosh_cli
    env_vars:
    - "SSH_PUBLIC_KEY=<your_ssh-rsa_public_key>"
    bind_ports:
    - "2222:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container

  - name: user2_bosh_cli
    image: <docker_image>:<image_tag>
    hostname: user2_bosh_cli
    env_vars:
    - "SSH_PUBLIC_KEY=<your_ssh-rsa_public_key>"
    bind_ports:
    - "2223:22"
    volumes:
    - /home/bosh
    depends_on:
    - data_container
    volumes_from:
    - data_container
```

Then, log into the container you want with ssh :  
<code>ssh -i <path_to_your_rsa_private_key> -p 2222 bosh@docker.bosh.release.deployment</code>  

To log into first container (replace docker.bosh.release.deployment with IP or dns name of docker host deployed using bosh release).

# Appendices

## k9s hotkeys

|Shortcut       |Description          |
|---------------|---------------------|
|`F1`           | View kustomizations |
|`F2`           | View namespaces     |
|`F3`           | View pods           |
|`F4`           | View deployments    |
|`F5`           | View daemonsets     |
|`F6`           | View services       |
|`F7`           | View helmreleases   |
|`F8`           | View configmaps     |
|`F1`           | View secrets        |

## k9s shorcuts

|Shortcut       |Description          |
|---------------|---------------------|
|`<0>`          | Select all objects  |
|`<?>`          | Help                |
|`<:q>`         | Quit                |
|`<enter>`      | View                |
|`<esc>`        | Back                |
|`<backtab>`    | Field Previous      |
|`<space>`      | Mark raw            |
|`<tab>`        | Next field          |
|`</term>`      | Filter mode         |
<BR>

|Shortcut       |Description             |Scope                  | Plugin |
|---------------|------------------------|-----------------------|--------|
|`<a>`          | Attach/List all values | pod, container/chart  | X      |
|`<b>`          | Bench Run/Stop         | service, portforwards |        |
|`<c>`          | Copy                   | node, pod, container  |        |
|`<d>`          | Describe               | all                   |        |
|`<e>`          | Edit                   | all                   |        |
|`<f>`          | Show PortForward       | pod, container        |        |
|`<g>`          | Goto Top               | all                   |        |
|               | Namespace inventory    | namespaces            | X      |
|`<h>`          | Left                   | all                   |        |
|`<i>`          | Set Image              |                       |        |
|`<j>`          | Down                   | all                   |        |
|`<k>`          | Up                     | all                   |        |
|`<l>`          | Right/Logs             | all                   |        |
|`<m>`          | Mark                   |                       |        |
|`<n>`          | Copy Namespace         | pod                   |        |
|               | Flux inventory         | namespaces            | X      |
|`<o>`          | Show Node              | pod                   |        |
|`<p>`          | Logs Previous          |                       |        |
|               | PSQL shell             | cluster               | X      |
|`<r>`          | Toggle Auto-Refresh    |                       |        |
|`<s>`          | Shell                  |                       |        |
|               | Cnpg status            | cluster               | X      |
|`<t>`          | Trigger cron           |                       |        |
|               | Run argo workflow      | workflowtemplates     | X      |
|`<u>`          | Use/UsedBy             |                       |        |
|`<v>`          | Vulnerabilities        |                       |        |
|               | Helm values            | helm                  | X      |
|`<w>`          | Watch events           | all                   | X      |
|`<x>`          | Decode                 | secrets               |        |
|`<y>`          | YAML                   |                       |        |
|`<z>`          | zorg                   |                       |        |
<BR>

|Shortcut       |Description           |Scope                                  | Plugin |
|---------------|----------------------|---------------------------------------|--------|
|`<ctrl-a>`     | Aliases              |                                       |        |
|`<ctrl-b>`     | Page Up              |                                       |        |
|`<ctrl-d>`     | Delete               |                                       |        |
|`<ctrl-e>`     | Toggle Header        |                                       |        |
|`<ctrl-f>`     | Page Down            |                                       |        |
|`<ctrl-g>`     | Toggle Crumbs        |                                       |        |
|`<ctrl-j>`     | Display dependencies |                                       | X      |
|`<ctrl-k>`     | Kill                 |                                       |        |
|`<ctrl-l>`     | Display logs         | deployment, daemonset, pod, container | X      |
|`<ctrl-q>`     | Sort MEM/L           |                                       |        |
|`<ctrl-r>`     | Refresh/Reload       |                                       |        |
|`<ctrl-s>`     | Save                 |                                       |        |
|`<ctrl-u>`     | Command Clear        |                                       |        |
|`<ctrl-w>`     | Toggle Wide          |                                       |        |
|`<ctrl-x>`     | Sort CPU/L           |                                       |        |
|`<ctrl-\>`     | Mark Clear           |                                       |        |
|`<ctrl-space>` | Mark Range           |                                       |        |
<BR>

|Shortcut       |Description          |Scope                                                                                        | Plugin |
|---------------|---------------------|---------------------------------------------------------------------------------------------|--------|
|`<shift-a>`    | Sort Age            | all                                                                                         |        |
|`<shift-b>`    | Sort Binding        | policy                                                                                      |        |
|               | Display shell cmd   | all                                                                                         | X      |
|`<shift-c>`    | Sort CPU            | all                                                                                         |        |
|               | Show certs          | secrets                                                                                     | X      |
|`<shift-d>`    | Sort desired        | ds/rs                                                                                       |        |
|               | Add debug container | containers                                                                                  | X      |
|`<shift-e>`    | Sort errors         | popeye                                                                                      |        |
|`<shift-f>`    | Port-Forward        | containers, events                                                                          |        |
|`<shift-g>`    | Goto Bottom         | all                                                                                         |        |
|`<shift-h>`    | Helm inventory      | helmreleases                                                                                | X      |
|`<shift-i>`    | Sort IP             | pods/popeye                                                                                 |        |
|`<shift-j>`    | NOT USED            |                                                                                             |        |
|`<shift-k>`    | Sort Kind           | workloads, groups, users                                                                    |        |
|`<shift-l>`    | Sort MEM            |                                                                                             |        |
|`<shift-m>`    | Sort Name           |                                                                                             |        |
|`<shift-n>`    | Sort Name           |                                                                                             |        |
|`<shift-o>`    | Sort Node           |                                                                                             |        |
|`<shift-p>`    | Sort Ready          |                                                                                             |        |
|`<shift-q>`    | Blame               | all                                                                                         | X      |
|`<shift-r>`    | Sort Ready          |                                                                                             |        |
|`<shift-s>`    | Sort Status         | all                                                                                         |        |
|               | List suspended      | helmreleases, kustomizations                                                                | X      |
|               | Certificate status  | certificates                                                                                | X      |
|`<shift-t>`    | Sort Restart        | all                                                                                         |        |
|               | Suspend/resume      | helmreleases, kustomizations, gitrepositories, terraform                                    | X      |
|`<shift-u>`    | Sort UpToDate       | dp/pf/ds                                                                                    |        |
|`<shift-v>`    | Sort Volume         | reference/pvc/img_scan                                                                      |        |
|`<shift-w>`    | Sort Warning        | popeye                                                                                      |        |
|`<shift-x>`    | Sort CPU/R          | pod                                                                                         |        |
|`<shift-y>`    | NOT USED            |                                                                                             |        |
|`<shift-z>`    | Sort MEM/R          | pod                                                                                         |        |
|               | Flux reconcile      | gitrepositories, helmreleases, helmrepositories, kustomizations, ocirepositories, terraform | X      |
