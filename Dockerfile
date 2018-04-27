FROM ubuntu:16.04
USER root

#--- Packages versions
ENV BUNDLER_VERSION="1.13.6" \
    RUBY_VERSION="2.3.3" \
    GOLANG_VERSION="1.8.3" \
    SPIFF_VERSION="1.0.8" \
    SPIFF_RELOADED_VERSION="1.0.8-ms.6" \
    SPRUCE_VERSION="1.13.1" \
    JQ_VERSION="1.5" \
    BOSH_GEN_VERSION="0.22.0" \
    BOSH_CLI_VERSION="1.3262.26.0" \
    BOSH_CLI_V2_VERSION="2.0.45" \
    CF_CLI_VERSION="6.33.1" \
    CF_UAAC_VERSION="4.1.0" \
    CREDHUB_VERSION="1.6.0" \
    FLY_VERSION="3.9.2" \
    TERRAFORM_VERSION="0.10.2" \
    TERRAFORM_PCF_VERSION="0.9.1" \
    SHIELD_VERSION="0.10.9" \
    BBR_VERSION="1.2.0" \
    KUBECTL_VERSION="1.9.1" \
    HELM_VERSION="2.8.1" \
    MYSQL_SHELL_VERSION="1.0.11-1"

#--- Install tools packages
ARG DEBIAN_FRONTEND=noninteractive
ENV INIT_PACKAGES="apt-utils ca-certificates sudo wget curl unzip openssh-server openssl apt-transport-https" \
    TOOLS_PACKAGES="supervisor git-core s3cmd bash-completion vim less mlocate nano yarn screen tmux byobu silversearcher-ag colordiff" \
    NET_PACKAGES="net-tools iproute2 iputils-ping dnsutils ldap-utils netcat tcpdump mtr-tiny" \
    DEV_PACKAGES="nodejs python-pip python-setuptools python-dev build-essential libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev libssl-dev zlib1g-dev" \
    BDD_PACKAGES="libprotobuf9v5 mongodb-clients" \
    CF_PLUGINS="CLI-Recorder,doctor,manifest-generator,Statistics,Targets,Usage Report"

RUN apt-get update && apt-get install -y --no-install-recommends ${INIT_PACKAGES} && \
    apt-get upgrade -y && apt-get clean && apt-get autoremove -y && apt-get purge && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list  && \
    apt-get update && apt-get install -y --no-install-recommends ${TOOLS_PACKAGES} ${NET_PACKAGES} ${DEV_PACKAGES} ${BDD_PACKAGES} && \
    apt-get upgrade -y && apt-get clean && apt-get autoremove -y && apt-get purge && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--- Install Ruby Version Manager and Ruby packages (bundler, bosh-cli, bosh-gen & uaa client)
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "rvm requirements" && \
    /bin/bash -l -c "rvm install ${RUBY_VERSION}" && \
    /bin/bash -l -c "rvm use ${RUBY_VERSION}" && \
    /bin/bash -l -c "gem install bundler --no-ri --no-rdoc -v ${BUNDLER_VERSION}" && \
    /bin/bash -l -c "gem install bosh_cli --no-ri --no-rdoc -v ${BOSH_CLI_VERSION}" && \
    /bin/bash -l -c "gem install bosh-gen --no-ri --no-rdoc -v ${BOSH_GEN_VERSION}" && \
    /bin/bash -l -c "gem install cf-uaac --no-ri --no-rdoc -v ${CF_UAAC_VERSION}" && \
    mv /usr/local/rvm/gems/ruby-${RUBY_VERSION}/bin/bosh /usr/local/rvm/gems/ruby-${RUBY_VERSION}/bin/bosh1 && \
    /bin/bash -l -c "rvm cleanup all" && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--- Setup SSH access, secure root login (SSH login fix. Otherwise user is kicked off after login) and create user
ENV CONTAINER_LOGIN="bosh" CONTAINER_PASSWORD="welcome"
ADD scripts/supervisord scripts/check_ssh_security scripts/disable_ssh_password_auth /usr/local/bin/
ADD supervisord/sshd.conf /etc/supervisor/conf.d/
ADD scripts/homedir.sh scripts/cf.sh scripts/go.sh /etc/profile.d/

RUN echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd /var/log/supervisor && \
    chmod 755 /usr/local/bin/supervisord /usr/local/bin/check_ssh_security /usr/local/bin/disable_ssh_password_auth /etc/profile.d/homedir.sh /etc/profile.d/cf.sh /etc/profile.d/go.sh && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    useradd -m -g users -G sudo,rvm -s /bin/bash ${CONTAINER_LOGIN} && echo "${CONTAINER_LOGIN}:${CONTAINER_PASSWORD}" | chpasswd && \
    sed -i "s/<username>/${CONTAINER_LOGIN}/g" /usr/local/bin/supervisord && \
    sed -i "s/<username>/${CONTAINER_LOGIN}/g" /usr/local/bin/check_ssh_security && \
    sed -i "s/<username>/${CONTAINER_LOGIN}/g" /usr/local/bin/disable_ssh_password_auth && \
    echo "${CONTAINER_LOGIN} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${CONTAINER_LOGIN} && \
    chage -d 0 ${CONTAINER_LOGIN} && ln -s /tmp /home/${CONTAINER_LOGIN}/tmp && chown -R ${CONTAINER_LOGIN}:users /home/${CONTAINER_LOGIN} && chmod 700 /home/${CONTAINER_LOGIN} && \
    mkdir -p /data && chown ${CONTAINER_LOGIN}:users /data && \
    mkdir -p /data/shared/tools/certs && chown ${CONTAINER_LOGIN}:users /data/shared/tools && chown ${CONTAINER_LOGIN}:users /data/shared/tools/certs && \
    rm -fr /tmp/*

#--- Install ops tools & cf cli plugins
RUN wget "https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-amd64.tar.gz" -nv -O - | tar -xz -C /usr/local && chmod 755 /etc/profile.d/go.sh && \
    wget "https://github.com/cloudfoundry-incubator/spiff/releases/download/v${SPIFF_VERSION}/spiff_linux_amd64.zip" -nv -O /tmp/spiff_linux_amd64.zip && unzip -q /tmp/spiff_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/spiff && rm /tmp/spiff_linux_amd64.zip && \
    wget "https://github.com/mandelsoft/spiff/releases/download/v${SPIFF_RELOADED_VERSION}/spiff_linux_amd64.zip" -nv -O /tmp/spiff_linux_amd64.zip && unzip -q /tmp/spiff_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/spiff++ && rm /tmp/spiff_linux_amd64.zip && \
    wget "https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-amd64" -nv -O /usr/local/bin/spruce && chmod 755 /usr/local/bin/spruce && \
    wget "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" -nv -O /usr/local/bin/jq && chmod 755 /usr/local/bin/jq && \
    wget "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_CLI_V2_VERSION}-linux-amd64" -nv -O /usr/local/bin/bosh && chmod 755 /usr/local/bin/bosh && \
    wget "https://cli.run.pivotal.io/stable?release=debian64&version=${CF_CLI_VERSION}&source=github-rel" -nv -O /tmp/cf.deb && dpkg -i /tmp/cf.deb && rm /tmp/cf.deb && \
    wget "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-${CREDHUB_VERSION}.tgz" -nv -O - | tar -xz -C /usr/local/bin && chmod 755 /usr/local/bin/credhub && \
    wget "https://github.com/concourse/concourse/releases/download/v${FLY_VERSION}/fly_linux_amd64" -nv -O /usr/local/bin/fly && chmod 755 /usr/local/bin/fly && \
    wget "https://github.com/starkandwayne/shield/releases/download/v${SHIELD_VERSION}/shield-linux-amd64" && mv shield-linux-amd64 /usr/local/bin/shield && chmod 755 /usr/local/bin/shield && \
    wget "https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v${BBR_VERSION}/bbr-${BBR_VERSION}.tar" -nv -O - | tar -x -C /tmp releases/bbr && mv /tmp/releases/bbr /usr/local/bin/bbr && chmod 755 /usr/local/bin/bbr && \
    wget "https://dl.minio.io/client/mc/release/linux-amd64/mc" -nv -O /usr/local/bin/mc && chmod 755 /usr/local/bin/mc && \
    wget "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -nv -O /usr/local/bin/kubectl && chmod 755 /usr/local/bin/kubectl && \
    wget "https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -nv -O - | tar -xz -C /tmp linux-amd64/helm && mv /tmp/linux-amd64/helm /usr/local/bin/helm && chmod 755 /usr/local/bin/helm && \
    wget "https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${MYSQL_SHELL_VERSION}ubuntu16.04_amd64.deb" -nv -O /tmp/mysql-shell.deb && dpkg -i /tmp/mysql-shell.deb && rm /tmp/mysql-shell.deb && \
    wget "https://raw.githubusercontent.com/rupa/z/master/z.sh" -nv -O /usr/local/bin/z.sh && chmod 755 /usr/local/bin/z.sh && printf "\n# Maintain a jump-list of in use directories\nif [ -f /usr/local/bin/z.sh ] ; then\n  source /usr/local/bin/z.sh\nfi\n" >> /home/${CONTAINER_LOGIN}/.bashrc && \
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -nv -O /tmp/terraform.zip && unzip -q /tmp/terraform.zip -d /usr/local/bin && chmod 755 /usr/local/bin/terraform && rm /tmp/terraform.zip && \
    export PROVIDER_CLOUDFOUNDRY_VERSION="v${TERRAFORM_PCF_VERSION}" && /bin/bash -c "$(wget https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O -)" && \
    mkdir -p /home/${CONTAINER_LOGIN}_non_persistent_storage/cf_plugins && chown -R ${CONTAINER_LOGIN}:users /home/${CONTAINER_LOGIN}_non_persistent_storage && chmod 700 /home/${CONTAINER_LOGIN}_non_persistent_storage && \
    su -l ${CONTAINER_LOGIN} -s /bin/bash -c "export http_proxy=${http_proxy};export https_proxy=${https_proxy};export IFS=,;for plug in \`echo ${CF_PLUGINS}\`; do cf install-plugin \"\${plug}\" -r CF-Community -f; done" && \
    export GOPATH=/tmp && export PATH=$PATH:/usr/local/go/bin && \
    go get -v github.com/square/certstrap && mv /tmp/bin/certstrap /usr/local/bin/certstrap && chmod 755 /usr/local/bin/certstrap && rm -fr /tmp/* && \
    go get -v github.com/rlmcpherson/s3gof3r/gof3r && mv /tmp/bin/gof3r /usr/local/bin/gof3r && chmod 755 /usr/local/bin/gof3r && rm -fr /tmp/* && \
    pip install --upgrade pip && \
    python -m pip install python-keystoneclient python-novaclient python-swiftclient python-neutronclient python-cinderclient python-glanceclient python-openstackclient && \
    git clone --depth 1 https://github.com/junegunn/fzf.git /home/${CONTAINER_LOGIN}/.fzf && \
    chown -R ${CONTAINER_LOGIN}:users /home/${CONTAINER_LOGIN}/.fzf && \
    su -l ${CONTAINER_LOGIN} -s /bin/bash -c "export http_proxy=${http_proxy};export https_proxy=${https_proxy};/home/${CONTAINER_LOGIN}/.fzf/install --all" && \
    sed -i "/source ~\/.fzf.bash/d" /home/${CONTAINER_LOGIN}/.bashrc && \
    printf "# Interactive filter for command-line\nif [ -f /home/${CONTAINER_LOGIN}/.fzf.bash ] ; then\n  source /home/${CONTAINER_LOGIN}/.fzf.bash\nfi\n" >> /home/${CONTAINER_LOGIN}/.bashrc && \
    rm -fr /tmp/*

#--- Provide tools information on system banner, setup profile & cleanup
ADD scripts/motd /etc/
ADD scripts/profile /home/${CONTAINER_LOGIN}/.profile
ADD scripts/tools /data/shared/tools/
ADD scripts/log-bosh /data/shared/tools/
ADD scripts/log-cf /data/shared/tools/
ADD scripts/log-credhub /data/shared/tools/
ADD scripts/log-fly /data/shared/tools/
ADD scripts/log-mc /data/shared/tools/
ADD scripts/log-openstack /data/shared/tools/

RUN chmod 644 /etc/motd && chmod 755 /data/shared/tools/* && \
    GIT_VERSION=`git --version | awk '{print $3}'` && \
    CERTSTRAP_VERSION=`/usr/local/bin/certstrap -v | awk '{print $3}'` && \
    GO3FR_VERSION=`gof3r --version 2>&1 | awk '{print $3}'` && \
    MONGO_SHELL_VERSION=`mongo --version 2>&1 | awk '{print $4}'` && \
    NODEJS_VERSION=`node -v` && \
    YARN_VERSION=`yarn -v` && \
    sed -i "s/<ruby_version>/${RUBY_VERSION}/g" /etc/motd && \
    sed -i "s/<golang_version>/${GOLANG_VERSION}/g" /etc/motd && \
    sed -i "s/<nodejs_version>/${NODEJS_VERSION}/g" /etc/motd && \
    sed -i "s/<git_version>/${GIT_VERSION}/g" /etc/motd && \
    sed -i "s/<spiff_version>/${SPIFF_VERSION}/g" /etc/motd && \
    sed -i "s/<spiff_reloaded_version>/${SPIFF_RELOADED_VERSION}/g" /etc/motd && \
    sed -i "s/<spruce_version>/${SPRUCE_VERSION}/g" /etc/motd && \
    sed -i "s/<jq_version>/${JQ_VERSION}/g" /etc/motd && \
    sed -i "s/<certstrap_version>/${CERTSTRAP_VERSION}/g" /etc/motd && \
    sed -i "s/<yarn_version>/${YARN_VERSION}/g" /etc/motd && \
    sed -i "s/<bosh_gen_version>/${BOSH_GEN_VERSION}/g" /etc/motd && \
    sed -i "s/<bosh_cli_version>/${BOSH_CLI_VERSION}/g" /etc/motd && \
    sed -i "s/<bosh_cli_v2_version>/${BOSH_CLI_V2_VERSION}/g" /etc/motd && \
    sed -i "s/<cf_cli_version>/${CF_CLI_VERSION}/g" /etc/motd && \
    sed -i "s/<cf_uaac_version>/${CF_UAAC_VERSION}/g" /etc/motd && \
    sed -i "s/<credhub_version>/${CREDHUB_VERSION}/g" /etc/motd && \
    sed -i "s/<fly_version>/${FLY_VERSION}/g" /etc/motd && \
    sed -i "s/<terraform_version>/${TERRAFORM_VERSION}/g" /etc/motd && \
    sed -i "s/<terraform_pcf_version>/${TERRAFORM_PCF_VERSION}/g" /etc/motd && \
    sed -i "s/<shield_version>/${SHIELD_VERSION}/g" /etc/motd && \
    sed -i "s/<bbr_version>/${BBR_VERSION}/g" /etc/motd && \
    sed -i "s/<gof3r_version>/${GO3FR_VERSION}/g" /etc/motd && \
    sed -i "s/<kubectl_version>/${KUBECTL_VERSION}/g" /etc/motd && \
    sed -i "s/<helm_version>/${HELM_VERSION}/g" /etc/motd && \
    sed -i "s/<mysql_shell_version>/${MYSQL_SHELL_VERSION}/g" /etc/motd && \
    sed -i "s/<mongodb_shell_version>/${MONGO_SHELL_VERSION}/g" /etc/motd && \
    chown -R ${CONTAINER_LOGIN}:users /home/${CONTAINER_LOGIN}/.profile && chmod 644 /home/${CONTAINER_LOGIN}/.profile && \
    sed -i "s/<username>/${CONTAINER_LOGIN}/g" /home/${CONTAINER_LOGIN}/.profile && \
    find /var/log -type f -delete && touch /var/log/lastlog && chgrp utmp /var/log/lastlog && chmod 664 /var/log/lastlog

#--- Launch supervisord daemon
EXPOSE 22
CMD /usr/local/bin/supervisord
