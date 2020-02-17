FROM ubuntu:18.04
USER root
ARG DEBIAN_FRONTEND=noninteractive

#--- Packages list
ENV INIT_PACKAGES="apt-utils apt-transport-https ca-certificates curl openssh-server openssl sudo unzip wget" \
    TOOLS_PACKAGES="apg bash-completion colordiff git-core less locales nano nodejs python-pip s3cmd silversearcher-ag supervisor tmux vim zsh" \
    NET_PACKAGES="dnsutils iproute2 iputils-ping ldap-utils mtr-tiny netbase netcat net-tools tcpdump whois" \
    DEV_PACKAGES="python-dev build-essential libc6-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev zlib1g-dev libcurl4-openssl-dev" \
    RUBY_PACKAGES="gawk g++ gcc autoconf automake bison libgdbm-dev libncurses5-dev libtool libyaml-dev pkg-config sqlite3 libgmp-dev libreadline6-dev" \
    BDD_PACKAGES="mongodb-clients" \
    CF_PLUGINS="CLI-Recorder,doctor,manifest-generator,Statistics,Targets,Usage Report"

#--- Cli versions
ENV BBR_VERSION="1.5.2" \
    BOSH_CLI_VERSION="6.0.0" \
    BOSH_CLI_COMPLETION_VERSION="1.2.0" \
    BOSH_GEN_VERSION="0.101.1" \
    CF_CLI_VERSION="6.49.0" \
    CF_CLI7_VERSION="7.0.0-beta.28" \
    CF_UAAC_VERSION="4.2.0" \
    CREDHUB_VERSION="2.5.3" \
    DB_DUMPER_VERSION="1.4.2" \
    FLY_VERSION="5.8.0" \
    GO3FR_VERSION="0.5.0" \
    HELM_VERSION="3.0.0" \
    JQ_VERSION="1.6" \
    KUBECTL_VERSION="1.15.4" \
    K9S_VERSION="0.13.8" \
    MYSQL_SHELL_VERSION="8.0.16-1" \
    RUBY_BUNDLER_VERSION="1.17.3" \
    RUBY_VERSION="2.6" \
    RUBY_PATH_VERSION="2.6.3" \
    SHIELD_VERSION="8.6.2" \
    SPRUCE_VERSION="1.22.0" \
    TERRAFORM_PLUGIN_CF_VERSION="0.11.2" \
    TERRAFORM_VERSION="0.11.14" \
    VELERO_VERSION="1.2.0"

#--- Set ruby env for COA
ENV PATH="/usr/local/rvm/gems/ruby-${RUBY_PATH_VERSION}/bin:/usr/local/rvm/gems/ruby-${RUBY_PATH_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_PATH_VERSION}/bin:${PATH}" \
    GEM_HOME="/usr/local/rvm/gems/ruby-${RUBY_PATH_VERSION}" \
    GEM_PATH="/usr/local/rvm/gems/ruby-${RUBY_PATH_VERSION}:/usr/local/rvm/gems/ruby-${RUBY_PATH_VERSION}@global"

ADD bosh-cli/* /tmp/bosh-cli/

RUN printf '\n=====================================================\n Install system packages\n=====================================================\n' && \
    apt-get update && apt-get install -y --no-install-recommends ${INIT_PACKAGES} ${TOOLS_PACKAGES} ${NET_PACKAGES} ${DEV_PACKAGES} ${RUBY_PACKAGES} ${BDD_PACKAGES} && apt-get upgrade -y && \
    printf '=====================================================\n Install NodeJS and yarn\n=====================================================\n' && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y --no-install-recommends yarn && \
    apt-get upgrade -y && apt-get autoremove -y && apt-get clean && apt-get purge && \
    printf '\n=====================================================\n Install Ruby tools\n=====================================================\n' && \
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
    python -m pip install --upgrade pip && python -m pip install --upgrade setuptools && \
    python -m pip install python-openstackclient && python -m pip install pynsxv && \
    curl -sSLo /usr/local/bin/spruce "https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-amd64" && \
    curl -sSLo /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" && \
    curl -sSLo /usr/local/bin/bosh "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_CLI_VERSION}-linux-amd64" && \
    curl -sSLo /home/bosh/bosh-complete-linux "https://github.com/thomasmmitchell/bosh-complete/releases/download/v${BOSH_CLI_COMPLETION_VERSION}/bosh-complete-linux" && chmod 755 /home/bosh/bosh-complete-linux && \
    curl -sSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_VERSION}&source=github" | tar -xz -C /tmp && mv /tmp/cf /usr/local/bin/cf && \
    curl -sSLo /usr/share/bash-completion/completions/cf "https://raw.githubusercontent.com/cloudfoundry/cli/master/ci/installers/completion/cf"  && \
    curl -sSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI7_VERSION}&source=github" | tar -xz -C /tmp && mv /tmp/cf7 /usr/local/bin/cf7 && \
    curl -sSLo /usr/share/bash-completion/completions/cf7 "https://raw.githubusercontent.com/cloudfoundry/cli/master/ci/installers/completion/cf7"  && \
    curl -sSL "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-${CREDHUB_VERSION}.tgz" | tar -xz -C /usr/local/bin && \
    curl -sSL "https://github.com/concourse/concourse/releases/download/v${FLY_VERSION}/fly-${FLY_VERSION}-linux-amd64.tgz" | tar -xz -C /usr/local/bin && \
    curl -sSLo /usr/local/bin/shield "https://github.com/shieldproject/shield/releases/download/v${SHIELD_VERSION}/shield-linux-amd64" && \
    curl -sSL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_${K9S_VERSION}_Linux_x86_64.tar.gz" | tar -xz -C /tmp && mv /tmp/k9s /usr/local/bin/k9s && \
    curl -sSL "https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp && mv /tmp/velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero && \
    curl -sSL "https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v${BBR_VERSION}/bbr-${BBR_VERSION}.tar" | tar -x -C /tmp && mv /tmp/releases/bbr /usr/local/bin/bbr && \
    curl -sSLo /usr/local/bin/mc "https://dl.minio.io/client/mc/release/linux-amd64/mc" && \
    curl -sSL "https://github.com/rlmcpherson/s3gof3r/releases/download/v${GO3FR_VERSION}/gof3r_${GO3FR_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp && mv /tmp/gof3r_${GO3FR_VERSION}_linux_amd64/gof3r /usr/local/bin/go3fr && \
    curl -sSLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && chmod 755 /usr/local/bin/kubectl && /usr/local/bin/kubectl completion bash > /etc/bash_completion.d/kubectl && \
    curl -sSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp && mv /tmp/linux-amd64/helm /usr/local/bin/helm && chmod 755 /usr/local/bin/helm && /usr/local/bin/helm completion bash > /etc/bash_completion.d/helm && \
    curl -sSLo /tmp/mysql-shell.deb "https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${MYSQL_SHELL_VERSION}ubuntu16.04_amd64.deb"  && dpkg -i /tmp/mysql-shell.deb && \
    curl -sSLo /usr/local/bin/z.sh "https://raw.githubusercontent.com/rupa/z/master/z.sh" && \
    curl -sSLo /tmp/db-dumper-plugin "https://github.com/Orange-OpenSource/db-dumper-cli-plugin/releases/download/v${DB_DUMPER_VERSION}/db-dumper_linux_amd64" && chmod 755 /tmp/db-dumper-plugin && \
    curl -sSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && unzip -q /tmp/terraform.zip -d /usr/local/bin && \
    curl -sSLo /usr/local/bin/cf-cli-cmdb-functions.bash https://github.com/orange-cloudfoundry/cf-cli-cmdb-scripts/blob/master/cf-cli-cmdb-functions.bash && \
    export PROVIDER_CLOUDFOUNDRY_VERSION="v${TERRAFORM_PLUGIN_CF_VERSION}" && /bin/bash -c "$(wget https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O -)" && \
    git clone --depth 1 https://github.com/junegunn/fzf.git /home/bosh/.fzf && chown -R bosh:users /home/bosh/.fzf && su -l bosh -s /bin/bash -c "/home/bosh/.fzf/install --all" && \
    git clone --depth 1 https://github.com/orange-cloudfoundry/cf-cli-cmdb-scripts.git /tmp/cf-cli-cmdb-scripts && mv /tmp/cf-cli-cmdb-scripts/cf-cli-cmdb-functions.bash /usr/local/bin/cf-cli-cmdb-functions.bash && \
    printf '=====================================================\n Install CF plugins\n=====================================================\n' && \
    su -l bosh -s /bin/bash -c "export IFS=, ; for plug in \$(echo ${CF_PLUGINS}) ; do cf install-plugin \"\${plug}\" -r CF-Community -f ; done" && \
    su -l bosh -s /bin/bash -c "cf install-plugin /tmp/db-dumper-plugin -f" && rm -f /tmp/db-dumper-plugin && \
    printf '\n=====================================================\n Set system banner\n=====================================================\n' && \
    GIT_VERSION=$(git --version | awk '{print $3}') && MONGO_SHELL_VERSION=$(mongo --version | grep "MongoDB shell version" | awk '{print $4}') && \
    printf '\nYour are logged into an ubuntu docker container, which provides several tools :\n' > /etc/motd && \
    printf 'Generic tools:\n' >> /etc/motd && \
    printf "  bosh (${BOSH_CLI_VERSION}) - Bosh CLI (https://bosh.io/docs/cli-v2.html)\n" >> /etc/motd && \
    printf "  cf (${CF_CLI_VERSION}) - Cloud Foundry CLI (https://github.com/cloudfoundry/cli)\n" >> /etc/motd && \
    printf "  credhub (${CREDHUB_VERSION}) - Credhub CLI (https://github.com/cloudfoundry-incubator/credhub-cli)\n" >> /etc/motd && \
    printf "  fly (${FLY_VERSION}) - Concourse CLI (https://github.com/concourse/fly)\n" >> /etc/motd && \
    printf "  git (${GIT_VERSION}) - Git CLI\n" >> /etc/motd && \
    printf "  jq (${JQ_VERSION}) - JSON processing Tool (https://stedolan.github.io/jq/)\n" >> /etc/motd && \
    printf "  spruce (${SPRUCE_VERSION}) - YAML templating tool (https://github.com/geofffranks/spruce)\n" >> /etc/motd && \
    printf "  terraform (${TERRAFORM_VERSION}) - Provides a common configuration to launch infrastructure (https://www.terraform.io/)\n" >> /etc/motd && \
    printf "  uaac (${CF_UAAC_VERSION}) - Cloud Foundry UAA CLI (https://github.com/cloudfoundry/cf-uaac)\n" >> /etc/motd && \
    printf 'Admin tools:\n' >> /etc/motd && \
    printf "  bbr (${BBR_VERSION}) - Bosh Backup and Restore CLI (http://docs.cloudfoundry.org/bbr/)\n" >> /etc/motd && \
    printf "  gof3r (${GO3FR_VERSION}) - Client for fast, parallelized and pipelined streaming access to S3 bucket (https://github.com/rlmcpherson/s3gof3r)\n" >> /etc/motd && \
    printf "  mongo (${MONGO_SHELL_VERSION}) - MongoDB shell CLI (https://docs.mongodb.com/manual/mongo/)\n" >> /etc/motd && \
    printf "  mysqlsh (${MYSQL_SHELL_VERSION}) - MySQL shell CLI (https://dev.mysql.com/doc/mysql-shell-excerpt/5.7/en/)\n" >> /etc/motd && \
    printf "  shield (${SHIELD_VERSION}) - Shield CLI (https://docs.pivotal.io/partners/starkandwayne-shield/)\n" >> /etc/motd && \
    printf 'Kubernetes tools:\n' >> /etc/motd && \
    printf "  helm (${HELM_VERSION}) - Kubernetes Package Manager (https://docs.helm.sh/)\n" >> /etc/motd && \
    printf "  kubectl (${KUBECTL_VERSION}) - Kubernetes CLI (https://kubernetes.io/docs/reference/generated/kubectl/overview/)\n" >> /etc/motd && \
    printf "  k9s (${K9S_VERSION}) - Kubernetes CLI (https://github.com/derailed/k9s)\n" >> /etc/motd && \
    printf "  velero (${VELERO_VERSION}) - Kubernetes CLI for cluster resources backup/restore (https://github.com/vmware-tanzu/velero)\n" >> /etc/motd && \
    printf '\nNotes :\n' >> /etc/motd && \
    printf '  "tools" command tells you about the available tools.\n' >> /etc/motd && \
    printf '  "/data/shared" is a persistant data docker volume, shared with other container instances.\n' >> /etc/motd && \
    printf '  All other paths in this container will be reseted on restart/update (do not save data on it).\n\n' >> /etc/motd && \
    printf '\n=====================================================\n Configure system and cleanup docker image\n=====================================================\n' && \
    locale-gen en_US.UTF-8 && \
    mv /tmp/bosh-cli/*.sh /usr/local/bin/ && mv /tmp/bosh-cli/sshd.conf /etc/supervisor/conf.d/ && mv /tmp/bosh-cli/profile /home/bosh/.profile && chmod 664 /home/bosh/.profile && \
    mkdir -p /home/bosh/.ssh && chmod 700 /home/bosh /home/bosh/.ssh && \
    find /usr/local/bin -print0 | xargs -0 chown root:root && find /home/bosh /data -print0 | xargs -0 chown bosh:users && \
    chmod 755 /usr/local/bin/* /etc/profile.d/* && chmod 644 /etc/motd && \
    rm -fr /tmp/* /var/lib/apt/lists/* /var/tmp/* && find /var/log -type f -delete && \
    touch /var/log/lastlog && chgrp utmp /var/log/lastlog && chmod 664 /var/log/lastlog

#--- Launch supervisord daemon
CMD /usr/local/bin/supervisord.sh
EXPOSE 22