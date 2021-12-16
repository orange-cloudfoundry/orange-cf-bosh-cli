FROM ubuntu:20.04 AS orange_cli
USER root
ARG DEBIAN_FRONTEND=noninteractive

#--- clis versions
ENV BBR_VERSION="1.9.20" \
    BOSH_CLI_VERSION="6.4.9" \
    BOSH_CLI_COMPLETION_VERSION="1.2.0" \
    BOSH_GEN_VERSION="0.101.1" \
    CF_CLI_VERSION="7.4.0" \
    CF_UAAC_VERSION="4.3.0" \
    CREDHUB_VERSION="2.9.1" \
    FLUX_VERSION="0.23.0" \
    FLY_VERSION="7.6.0" \
    GOVC_VERSION="0.27.2" \
    GO3FR_VERSION="0.5.0" \
    HELM_VERSION="3.5.3" \
    JQ_VERSION="1.6" \
    K14S_KAPP_VERSION="0.43.0" \
    K14S_KLBD_VERSION="0.32.0" \
    K14S_YTT_VERSION="0.38.0" \
    K9S_VERSION="0.25.12" \
    KREW_VERSION="0.4.2" \
    KUBECTL_VERSION="1.20.7" \
    KUSTOMIZE_VERSION="4.4.1" \
    MONGO_SHELL_VERSION="4.0.25" \
    MYSQL_SHELL_VERSION="8.0.25-1" \
    REDIS_CLI_VERSION="6.2.4" \
    RUBY_BUNDLER_VERSION="1.17.3" \
    RUBY_VERSION="2.6.5" \
    SHIELD_VERSION="8.7.4" \
    SPRUCE_VERSION="1.29.0" \
    SVCAT_VERSION="0.3.1" \
    TERRAFORM_PLUGIN_CF_VERSION="0.11.2" \
    TERRAFORM_VERSION="0.11.14" \
    VENDIR_VERSION="0.23.0"

#--- Packages list, ruby env for COA and cf plugins
ENV INIT_PACKAGES="apt-transport-https ca-certificates curl openssh-server openssl sudo unzip wget" \
    TOOLS_PACKAGES="apg bash-completion colordiff git-core gnupg less locales nano python3-tabulate python3-openstackclient s3cmd silversearcher-ag supervisor tmux byobu yarnpkg vim" \
    NET_PACKAGES="dnsutils iproute2 iputils-ping traceroute tcptraceroute ldap-utils mtr-tiny netbase netcat net-tools tcpdump whois iperf3" \
    DEV_PACKAGES="python-dev build-essential libc6-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev zlib1g-dev libcurl4-openssl-dev" \
    RUBY_PACKAGES="gawk g++ gcc autoconf automake bison libgdbm-dev libncurses5-dev libtool libyaml-dev pkg-config sqlite3 libgmp-dev libreadline6-dev" \
    PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}/bin:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:${PATH}" \
    GEM_HOME="/usr/local/rvm/gems/ruby-${RUBY_VERSION}" \
    GEM_PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global" \
    CF_PLUGINS="cli-Recorder,doctor,manifest-generator,Statistics,Targets,Usage Report" \
    KUBECTL_PLUGINS="get-all"

ADD bosh-cli/* /tmp/bosh-cli/

RUN printf '\n=====================================================\n Install system packages\n=====================================================\n' && \
    apt-get update && apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y --no-install-recommends ${INIT_PACKAGES} ${TOOLS_PACKAGES} ${NET_PACKAGES} ${DEV_PACKAGES} ${RUBY_PACKAGES} && \
    apt-get upgrade -y && apt-get autoremove -y && apt-get clean && apt-get purge && \
    cp /usr/bin/chardetect3 /usr/local/bin/chardetect && \
    printf '\n=====================================================\n Install ruby tools\n=====================================================\n' && \
    curl -sSL https://rvm.io/mpapis.asc | gpg --import - && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "source /etc/profile.d/rvm.sh ; rvm install ${RUBY_VERSION}" && \
    /bin/bash -l -c "gem install bundler -v ${RUBY_BUNDLER_VERSION} --no-document" && \
    /bin/bash -l -c "gem install bosh-gen -v ${BOSH_GEN_VERSION} --no-document" && \
    /bin/bash -l -c "gem install cf-uaac -v ${CF_UAAC_VERSION} --no-document" && \
    /bin/bash -l -c "rvm cleanup all" && \
    printf '\n=====================================================\n Setup bosh account, ssh and supervisor\n=====================================================\n' && \
    echo "root:$(date +%s | sha256sum | base64 | head -c 32 ; echo)" | chpasswd && \
    useradd -m -g users -G sudo,rvm -s /bin/bash bosh && echo "bosh ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/bosh && \
    echo "bosh:$(date +%s | sha256sum | base64 | head -c 32 ; echo)" | chpasswd && \
    mkdir -p /var/run/sshd /var/log/supervisor /data/shared && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd && \
    sed -i 's/^PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config && \
    sed -i 's/^ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config && \
    sed -i 's/^PubkeyAuthentication .*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config && \
    sed -i 's/^.*PasswordAuthentication yes.*/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    printf '\n=====================================================\n Install ops tools\n=====================================================\n' && \
    printf '\n=> Add BBR-CLI\n' && curl -sSL "https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v${BBR_VERSION}/bbr-${BBR_VERSION}.tar" | tar -x -C /tmp && mv /tmp/releases/bbr /usr/local/bin/bbr && \
    printf '\n=> Add BOSH-CLI\n' && curl -sSLo /usr/local/bin/bosh "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_CLI_VERSION}-linux-amd64" && \
    printf '\n=> Add BOSH-CLI completion\n' && curl -sSLo /home/bosh/bosh-complete-linux "https://github.com/thomasmmitchell/bosh-complete/releases/download/v${BOSH_CLI_COMPLETION_VERSION}/bosh-complete-linux" && chmod 755 /home/bosh/bosh-complete-linux && \
    printf '\n=> Add CF-CLI\n' && curl -sSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_VERSION}&source=github" | tar -xz -C /tmp && mv /tmp/cf7 /usr/local/bin/cf && \
    printf '\n=> Add CF-CLI completion\n' && curl -sSLo /usr/share/bash-completion/completions/cf "https://raw.githubusercontent.com/cloudfoundry/cli-ci/master/ci/installers/completion/cf7" && \
    printf '\n=> Add CF-PLUGINS\n' && su -l bosh -s /bin/bash -c "export IFS=, ; for plugin in \$(echo \"${CF_PLUGINS}\") ; do cf install-plugin \"\${plugin}\" -r CF-Community -f ; done" && \    
    printf '\n=> Add CMDB-CLI-FUNCTIONS\n' && git clone --depth 1 https://github.com/orange-cloudfoundry/cf-cli-cmdb-scripts.git /tmp/cf-cli-cmdb-scripts && mv /tmp/cf-cli-cmdb-scripts/cf-cli-cmdb-functions.bash /usr/local/bin/cf-cli-cmdb-functions.bash && \
    printf '\n=> Add CREDHUB-CLI\n' && curl -sSL "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-${CREDHUB_VERSION}.tgz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add FLY-CLI\n' && curl -sSL "https://github.com/concourse/concourse/releases/download/v${FLY_VERSION}/fly-${FLY_VERSION}-linux-amd64.tgz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add FLUX-CLI\n' && curl -sSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add GOVC-CLI\n' && curl -sSL "https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/govc_Linux_x86_64.tar.gz" | tar -xz -C /tmp && mv /tmp/govc /usr/local/bin/govc && \
    printf '\n=> Add GO3FR-CLI\n' && curl -sSL "https://github.com/rlmcpherson/s3gof3r/releases/download/v${GO3FR_VERSION}/gof3r_${GO3FR_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp && mv /tmp/gof3r_${GO3FR_VERSION}_linux_amd64/gof3r /usr/local/bin/go3fr && \
    printf '\n=> Add HELM-CLI\n' && curl -sSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp && mv /tmp/linux-amd64/helm /usr/local/bin/helm && chmod 755 /usr/local/bin/helm && \
    printf '\n=> Add HELM-CLI completion\n' && /usr/local/bin/helm completion bash > /etc/bash_completion.d/helm && \
    printf '\n=> Add JQ-CLI\n' && curl -sSLo /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" && \
    printf '\n=> Add KUBECTL-CLI\n' && curl -sSLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && chmod 755 /usr/local/bin/kubectl && \
    printf '\n=> Add KUBECTL-CLI completion\n' && kubectl completion bash > /etc/bash_completion.d/kubectl && kubectl completion bash | sed -e "s+kubectl+k+g" > /etc/bash_completion.d/k && \ 
    printf '\n=> Add KREW-CLI\n' && curl -sSL "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/krew-linux_amd64.tar.gz" | tar -xz -C /tmp && chmod 1777 /tmp && \
    printf '\n=> Add KUBECTL_PLUGINS\n' && su -l bosh -s /bin/bash -c "export KREW_ROOT=/home/bosh/.krew ; export PATH=/home/bosh/.krew/bin:${PATH} ; /tmp/krew-linux_amd64 install krew ; export IFS=, ; for plugin in \$(echo \"${KUBECTL_PLUGINS}\") ; do kubectl krew install \${plugin} ; done" && \
    printf '\n=> Add KUSTOMIZE-CLI\n' && curl -sSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp && mv /tmp/kustomize /usr/local/bin/kustomize && \
    printf '\n=> Add K14S-KAPP-CLI\n' && curl -sSLo /usr/local/bin/kapp "https://github.com/k14s/kapp/releases/download/v${K14S_KAPP_VERSION}/kapp-linux-amd64" && \
    printf '\n=> Add K14S-KLBD-CLI\n' && curl -sSLo /usr/local/bin/klbd "https://github.com/k14s/kbld/releases/download/v${K14S_KLBD_VERSION}/kbld-linux-amd64" && \
    printf '\n=> Add K14S-YTT-CLI\n' && curl -sSLo /usr/local/bin/ytt "https://github.com/k14s/ytt/releases/download/v${K14S_YTT_VERSION}/ytt-linux-amd64" && \
    printf '\n=> Add K9S-CLI\n' && curl -sSL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_x86_64.tar.gz" | tar -xz -C /tmp && mv /tmp/k9s /usr/local/bin/k9s && \
    printf '\n=> Add MINIO-CLI\n' && curl -sSLo /usr/local/bin/mc "https://dl.minio.io/client/mc/release/linux-amd64/mc" && \
    printf '\n=> Add MONGO-SHELL-VERSION\n' && curl -sSL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGO_SHELL_VERSION}.tgz" | tar -xz -C /tmp && cd /tmp/mongodb-linux-x86_64-${MONGO_SHELL_VERSION}/bin && mv mongo mongostat mongotop /usr/local/bin && \
    printf '\n=> Add MYSQL-SHELL-CLI\n' && curl -sSLo /tmp/mysql-shell.deb "https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${MYSQL_SHELL_VERSION}ubuntu20.04_amd64.deb" && dpkg -i /tmp/mysql-shell.deb && \
    printf '\n=> Add REDIS-CLI\n' && curl -sSL "https://download.redis.io/releases/redis-${REDIS_CLI_VERSION}.tar.gz" | tar -xz -C /tmp && cd /tmp/redis-${REDIS_CLI_VERSION} && make > /dev/null 2>&1 && mv /tmp/redis-${REDIS_CLI_VERSION}/src/redis-cli /usr/local/bin/redis && chmod 755 /usr/local/bin/redis && \
    printf '\n=> Add SHIELD-CLI\n' && curl -sSLo /usr/local/bin/shield "https://github.com/shieldproject/shield/releases/download/v${SHIELD_VERSION}/shield-linux-amd64" && \
    printf '\n=> Add SPRUCE-CLI\n' && curl -sSLo /usr/local/bin/spruce "https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-amd64" && \
    printf '\n=> Add SVCAT-CLI\n' && curl -sSLo /usr/local/bin/svcat "https://download.svcat.sh/cli/v${SVCAT_VERSION}/linux/amd64/svcat" && \
    printf '\n=> Add TERRAFORM-CLI\n' && curl -sSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && unzip -q /tmp/terraform.zip -d /usr/local/bin && \
    printf '\n=> Add TERRAFORM-CF-PROVIDER\n' && export PROVIDER_CLOUDFOUNDRY_VERSION="v${TERRAFORM_PLUGIN_CF_VERSION}" && /bin/bash -c "$(wget https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O -)" && \
    printf '\n=> Add VENDIR-CLI\n' && curl -sSLo /usr/local/bin/vendir "https://github.com/vmware-tanzu/carvel-vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64" && \
    printf '\n=====================================================\n Set system banner\n=====================================================\n' && \
    GIT_VERSION=$(git --version | awk '{print $3}') && \
    printf '\nYour are logged into an ubuntu docker container, which provides several tools :\n' > /etc/motd && \
    printf 'Generic tools:\n' >> /etc/motd && \
    printf "  %-20s %s\n" "bosh (${BOSH_CLI_VERSION})" "Bosh cli (https://bosh.io/docs/cli-v2.html)" >> /etc/motd && \
    printf "  %-20s %s\n" "cf (${CF_CLI_VERSION})" "Cloud Foundry cli (https://github.com/cloudfoundry/cli/)" >> /etc/motd && \
    printf "  %-20s %s\n" "credhub (${CREDHUB_VERSION})" "Credhub cli (https://github.com/cloudfoundry-incubator/credhub-cli/)" >> /etc/motd && \
    printf "  %-20s %s\n" "fly (${FLY_VERSION})" "Concourse cli (https://github.com/concourse/fly/)" >> /etc/motd && \
    printf "  %-20s %s\n" "git (${GIT_VERSION})" "Git cli" >> /etc/motd && \
    printf "  %-20s %s\n" "jq (${JQ_VERSION})" "JSON processing Tool (https://stedolan.github.io/jq/)" >> /etc/motd && \
    printf "  %-20s %s\n" "spruce (${SPRUCE_VERSION})" "YAML templating tool (https://github.com/geofffranks/spruce/)" >> /etc/motd && \
    printf "  %-20s %s\n" "terraform (${TERRAFORM_VERSION})" "Manage infrastructure creation by configuration (https://www.terraform.io/)" >> /etc/motd && \
    printf "  %-20s %s\n" "uaac (${CF_UAAC_VERSION})" "Cloud Foundry UAA cli (https://github.com/cloudfoundry/cf-uaac/)" >> /etc/motd && \
    printf "  %-20s %s\n" "vendir (${VENDIR_VERSION})" "Define and fetch components to target directory (https://github.com/vmware-tanzu/carvel-vendir/)" >> /etc/motd && \
    printf 'Admin tools:\n' >> /etc/motd && \
    printf "  %-20s %s\n" "bbr (${BBR_VERSION})" "Bosh Backup and Restore cli (http://docs.cloudfoundry.org/bbr/)" >> /etc/motd && \
    printf "  %-20s %s\n" "govc (${GOVC_VERSION})" "vSphere cli (https://github.com/vmware/govmomi/tree/master/govc/)" >> /etc/motd && \
    printf "  %-20s %s\n" "gof3r (${GO3FR_VERSION})" "client for parallelized and pipelined S3 streaming (https://github.com/rlmcpherson/s3gof3r/)" >> /etc/motd && \
    printf "  %-20s %s\n" "mongo (${MONGO_SHELL_VERSION})" "MongoDB shell cli (https://docs.mongodb.com/manual/mongo/)" >> /etc/motd && \
    printf "  %-20s %s\n" "mysqlsh (${MYSQL_SHELL_VERSION})" "MySQL shell cli (https://dev.mysql.com/doc/mysql-shell-excerpt/5.7/en/)" >> /etc/motd && \
    printf "  %-20s %s\n" "redis (${REDIS_CLI_VERSION})" "Redis cli (https://redis.io/topics/rediscli)" >> /etc/motd && \
    printf "  %-20s %s\n" "shield (${SHIELD_VERSION})" "Shield cli (https://docs.pivotal.io/partners/starkandwayne-shield/)" >> /etc/motd && \
    printf 'Kubernetes tools:\n' >> /etc/motd && \
    printf "  %-20s %s\n" "helm (${HELM_VERSION})" "Kubernetes Package Manager (https://docs.helm.sh/)" >> /etc/motd && \
    printf "  %-20s %s\n" "flux (${FLUX_VERSION})" "Kubernetes Gitops cli (https://fluxcd.io/)" >> /etc/motd && \
    printf "  %-20s %s\n" "kubectl (${KUBECTL_VERSION})" "Kubernetes cli (https://kubernetes.io/docs/reference/generated/kubectl/overview/)" >> /etc/motd && \
    printf "  %-20s %s\n" "kapp (${K14S_KAPP_VERSION})" "Kubernetes YAML tool (https://github.com/k14s/kapp/)" >> /etc/motd && \
    printf "  %-20s %s\n" "klbd (${K14S_KLBD_VERSION})" "Kubernetes image build orchestrator tool (https://github.com/k14s/kbld/)" >> /etc/motd && \
    printf "  %-20s %s\n" "kustomize (${KUSTOMIZE_VERSION})" "Kubernetes template customize YAML files tool (https://github.com/kubernetes-sigs/kustomize/)" >> /etc/motd && \
    printf "  %-20s %s\n" "k9s (${K9S_VERSION})" "Kubernetes admin tool (https://github.com/derailed/k9s/)" >> /etc/motd && \
    printf "  %-20s %s\n" "svcat (${SVCAT_VERSION})" "Kubernetes Service Catalog cli (https://github.com/kubernetes-sigs/service-catalog/)" >> /etc/motd && \
    printf "  %-20s %s\n" "ytt (${K14S_YTT_VERSION})" "YAML Templating Tool (https://github.com/k14s/ytt/)" >> /etc/motd && \
    printf '\nNotes :\n' >> /etc/motd && \
    printf '  "tools" command gives available tools.\n' >> /etc/motd && \
    printf '  All path except "/data/shared" are not persistant (do not save data on it).\n\n' >> /etc/motd && \
    printf '\n=====================================================\n Configure system and cleanup docker image\n=====================================================\n' && \
    locale-gen en_US.UTF-8 && \
    mv /tmp/bosh-cli/*.sh /usr/local/bin/ && mv /tmp/bosh-cli/sshd.conf /etc/supervisor/conf.d/ && mv /tmp/bosh-cli/profile /home/bosh/.profile && chmod 664 /home/bosh/.profile && \
    chmod 644 /etc/motd && mkdir -p /home/bosh/.ssh && chmod 700 /home/bosh /home/bosh/.ssh && \
    chmod 1777 /tmp && chmod 755 /usr/local/bin/* /etc/profile.d/* && \
    find /usr/local/bin -print0 | xargs -0 chown root:root && find /home/bosh /data -print0 | xargs -0 chown bosh:users && \
    rm -fr /tmp/* /var/lib/apt/lists/* /var/tmp/* && find /var/log -type f -delete && \
    touch /var/log/lastlog && chgrp utmp /var/log/lastlog && chmod 664 /var/log/lastlog

#--- Launch supervisord daemon
CMD /usr/local/bin/supervisord.sh
EXPOSE 22

#--- Test clis/tools availability
FROM orange_cli AS tests
RUN /usr/local/bin/check-available-clis.sh

#--- Export bosh-cli image
FROM orange_cli