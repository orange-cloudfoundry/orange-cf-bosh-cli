FROM ubuntu:latest
MAINTAINER Olivier Grand <oliv.grand@orange.com>
USER root

#--- Tools versions
ENV bundler_version="1.13.6" \
    bosh_init_version="0.0.103" \
    bosh_gen_version="0.22.0" \
    bosh_cli_version="1.3262.24.0" \
    bosh_cli_v2_version="2.0.26" \
    spiff_version="1.0.8" \
    spiff_reloaded_version="1.0.8-ms.6" \
    spruce_version="1.8.9" \
    cf_cli_version="6.26.0" \
    cf_uaac_version="3.4.0" \
    terraform_version="0.9.8" \
    terraform_pcf_version="0.7.3" \
    fly_version="3.1.1" \
    shield_version="0.10.3" \
    credhub_version="1.1.0" \
    gof3r_version="0.0.5" \
    jq_version="1.5" \
    ruby_version="2.3.3" \
    golang_version="1.8.3" \
    container_login="bosh" \
    container_password="welcome" \
    cf_plugins="CLI-Recorder,Diego-Enabler,doctor,manifest-generator,Statistics,targets,Usage Report"

#--- Update image and install tools packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates apt-utils wget sudo && \
    echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" > /etc/apt/sources.list.d/git-core-ppa-trusty.list && \
    wget -q -O- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA1715D88E1DF1F24" | sudo apt-key add - && \
    echo "deb http://ppa.launchpad.net/ubuntu-lxc/lxd-stable/ubuntu trusty main" > /etc/apt/sources.list.d/lxd-stable.list && \
    wget -q -O- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD5495F657635B973" | sudo apt-key add - && \
    apt-get update && apt-get install -y --no-install-recommends \
      openssh-server \
      curl \
      git-core \
      unzip \
      openssl \
      s3cmd \
      supervisor \
      vim \
      nano \
      mlocate \
      net-tools \
      iputils-ping \
      netcat \
      dnsutils \
      build-essential \
      libxml2-dev \
      libsqlite3-dev \
      libxslt1-dev \
      libpq-dev \
      libmysqlclient-dev \
      libssl-dev \
      zlib1g-dev \
      screen \
      tmux \
      byobu \
      apt-transport-https \
      silversearcher-ag \
      colordiff && \
    apt-get upgrade -y && \
    apt-get clean && apt-get autoremove -y && apt-get purge && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--- Setup SSH access, secure root login (SSH login fix. Otherwise user is kicked off after login) and create bosh user
ADD scripts/supervisord scripts/check_ssh_security scripts/disable_ssh_password_auth /usr/local/bin/
ADD supervisord/sshd.conf /etc/supervisor/conf.d/
ADD scripts/homedir.sh scripts/cf.sh /etc/profile.d/
RUN mkdir -p /var/run/sshd /var/log/supervisor && \
    chmod 755 /usr/local/bin/supervisord /usr/local/bin/check_ssh_security /usr/local/bin/disable_ssh_password_auth /etc/profile.d/homedir.sh /etc/profile.d/cf.sh && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config && \
    echo "export VISIBLE=now" >> /etc/profile && \
    echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd && \
    useradd -m -g users -G sudo -s /bin/bash ${container_login} && \
    sed -i "s/<username>/${container_login}/g" /usr/local/bin/supervisord && \
    sed -i "s/<username>/${container_login}/g" /usr/local/bin/check_ssh_security && \
    sed -i "s/<username>/${container_login}/g" /usr/local/bin/disable_ssh_password_auth && \
    echo "${container_login} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${container_login} && \
    echo "${container_login}:${container_password}" | chpasswd && \
    chage -d 0 ${container_login} && \
    ln -s /tmp /home/${container_login}/tmp && \
    chown -R ${container_login}:users /home/${container_login} && chmod 700 /home/${container_login} && \
    mkdir -p /data && chown ${container_login}:users /data

ENV NOTVISIBLE "in users profile"

#--- Install Ruby Version Manager and Ruby packages (bundler, bosh-cli, bosh-gen & uaa client)
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} rvm requirements" && \
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} rvm install ${ruby_version}" && \
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} rvm use ${ruby_version}" && \
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} gem install bundler --no-ri --no-rdoc -v ${bundler_version}" && \ 
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} gem install bosh_cli --no-ri --no-rdoc -v ${bosh_cli_version}" && \
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} gem install bosh-gen --no-ri --no-rdoc -v ${bosh_gen_version}" && \
    /bin/bash -l -c "http_proxy=${http_proxy} https_proxy=${https_proxy} gem install cf-uaac --no-ri --no-rdoc -v ${cf_uaac_version}" && \
    mv /usr/local/rvm/gems/ruby-${ruby_version}/bin/bosh /usr/local/rvm/gems/ruby-${ruby_version}/bin/bosh1 && \
    usermod -a -G rvm ${container_login} && \
    /bin/bash -l -c "rvm cleanup all" && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--- Install ops tools & cf cli plugins
ADD scripts/go.sh /etc/profile.d/
RUN wget -nv -O /tmp/go.tar.gz https://storage.googleapis.com/golang/go${golang_version}.linux-amd64.tar.gz && tar -xzf /tmp/go.tar.gz -C /usr/local && chmod 755 /etc/profile.d/go.sh && rm -f /tmp/go.tar.gz && \
    export GOPATH=/tmp && export PATH=$PATH:/usr/local/go/bin && \
    wget -nv -O /usr/local/bin/bosh-init "https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${bosh_init_version}-linux-amd64" && chmod 755 /usr/local/bin/bosh-init && \
    wget -nv -O /tmp/spiff_linux_amd64.zip "https://github.com/cloudfoundry-incubator/spiff/releases/download/v${spiff_version}/spiff_linux_amd64.zip" && unzip -q /tmp/spiff_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/spiff && rm /tmp/spiff_linux_amd64.zip && \
    wget -nv -O /tmp/spiff_linux_amd64.zip "https://github.com/mandelsoft/spiff/releases/download/v${spiff_reloaded_version}/spiff_linux_amd64.zip" && unzip -q /tmp/spiff_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/spiff++ && rm /tmp/spiff_linux_amd64.zip && \
    wget -nv -O /usr/local/bin/spruce "https://github.com/geofffranks/spruce/releases/download/v${spruce_version}/spruce-linux-amd64" && chmod 755 /usr/local/bin/spruce && \
    wget -nv -O /usr/local/bin/bosh "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${bosh_cli_v2_version}-linux-amd64" && chmod 755 /usr/local/bin/bosh && \
    wget -nv -O /tmp/cf.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_version}&source=github-rel" && dpkg -i /tmp/cf.deb && rm /tmp/cf.deb && \
    wget -nv -O /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" && unzip -q /tmp/terraform.zip -d /usr/local/bin && chmod 755 /usr/local/bin/terraform && rm /tmp/terraform.zip && \
    export PROVIDER_CLOUDFOUNDRY_VERSION="v${terraform_pcf_version}" && \
    /bin/bash -c "$(wget https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O -)" && \
    wget -nv -O /usr/local/bin/fly "https://github.com/concourse/concourse/releases/download/v${fly_version}/fly_linux_amd64" && chmod 755 /usr/local/bin/fly && \
    wget -nv -O /tmp/credhub-linux.tgz "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${credhub_version}/credhub-linux-${credhub_version}.tgz" && tar -xzvf /tmp/credhub-linux.tgz -C /usr/local/bin && chmod 755 /usr/local/bin/credhub && rm /tmp/credhub-linux.tgz && \
    go get -v github.com/square/certstrap && mv /tmp/bin/certstrap /usr/local/bin/certstrap && chmod 755 /usr/local/bin/certstrap && rm -fr /tmp/* && \
    go get -v github.com/rlmcpherson/s3gof3r/gof3r && mv /tmp/bin/gof3r /usr/local/bin/gof3r && chmod 755 /usr/local/bin/gof3r && rm -fr /tmp/* && \
    wget -nv -O /usr/local/bin/shield "https://github.com/starkandwayne/shield/releases/download/v${shield_version}/shield-linux-amd64" && chmod 755 /usr/local/bin/shield && \
    wget -nv -O /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${jq_version}/jq-linux64" && chmod 755 /usr/local/bin/jq && \
    printf "\n\n# Interactive Unix filter for command-line" >> /home/${container_login}/.bashrc && \
    git clone --depth 1 https://github.com/junegunn/fzf.git /home/${container_login}/.fzf && chown -R ${container_login}:users /home/${container_login}/.fzf && su - ${container_login} -c "/home/${container_login}/.fzf/install --all" && \
    wget -nv -O /usr/local/bin/z.sh https://raw.githubusercontent.com/rupa/z/master/z.sh && \
    printf "\n# Maintain a jump-list of in use directories\nsource /usr/local/bin/z.sh" >> /home/${container_login}/.bashrc && \
    printf "\n\n# GIT Completion\nsource /usr/share/bash-completion/completions/git" >> /home/${container_login}/.bashrc && \
    mkdir -p /home/${container_login}_non_persistent_storage/cf_plugins && chown -R ${container_login}:users /home/${container_login}_non_persistent_storage && chmod 700 /home/${container_login}_non_persistent_storage && \
    su -c "export http_proxy=${http_proxy};export https_proxy=${https_proxy};export IFS=,;for plug in \`echo ${cf_plugins}\`; do cf install-plugin \"\${plug}\" -r CF-Community -f; done" -l ${container_login} -s /bin/bash && \
    rm -fr /tmp/*

#--- Tools publication on system banner, setup profile & cleanup
ADD  scripts/motd /etc/
RUN GIT_VERSION=`git --version | awk '{print $3}'` && \
    CERTSTRAP_VERSION=`/usr/local/bin/certstrap -v | awk '{print $3}'` && \
    sed -i "s/<git_version>/${GIT_VERSION}/g" /etc/motd && \
    sed -i "s/<bosh_init_version>/${bosh_init_version}/g" /etc/motd && \
    sed -i "s/<bosh_gen_version>/${bosh_gen_version}/g" /etc/motd && \
    sed -i "s/<bosh_cli_version>/${bosh_cli_version}/g" /etc/motd && \
    sed -i "s/<bosh_cli_v2_version>/${bosh_cli_v2_version}/g" /etc/motd && \
    sed -i "s/<spiff_version>/${spiff_version}/g" /etc/motd && \
    sed -i "s/<spiff_reloaded_version>/${spiff_reloaded_version}/g" /etc/motd && \
    sed -i "s/<spruce_version>/${spruce_version}/g" /etc/motd && \
    sed -i "s/<cf_cli_version>/${cf_cli_version}/g" /etc/motd && \
    sed -i "s/<cf_uaac_version>/${cf_uaac_version}/g" /etc/motd && \   
    sed -i "s/<terraform_version>/${terraform_version}/g" /etc/motd && \
    sed -i "s/<terraform_pcf_version>/${terraform_pcf_version}/g" /etc/motd && \
    sed -i "s/<fly_version>/${fly_version}/g" /etc/motd && \
    sed -i "s/<shield_version>/${shield_version}/g" /etc/motd && \ 
    sed -i "s/<credhub_version>/${credhub_version}/g" /etc/motd && \
    sed -i "s/<certstrap_version>/${CERTSTRAP_VERSION}/g" /etc/motd && \
    sed -i "s/<gof3r_version>/${gof3r_version}/g" /etc/motd && \
    sed -i "s/<jq_version>/${jq_version}/g" /etc/motd && \
    sed -i "s/<ruby_version>/${ruby_version}/g" /etc/motd && \
    sed -i "s/<golang_version>/${golang_version}/g" /etc/motd && \
    chmod 644 /etc/motd && \
    printf "\n# Persistant user configuration (on shared disk)\n" >> /home/${container_login}/.profile && \
    echo "export MY_BOSH_USER=\`hostname\`" >> /home/${container_login}/.profile && \
    echo "export HOME=/home/${container_login}/shared/\${MY_BOSH_USER}" >> /home/${container_login}/.profile && \
    echo "export XDG_CONFIG_HOME=\${HOME}" >> /home/${container_login}/.profile && \
    echo "export HISTFILE=\${HOME}/.bash_history" >> /home/${container_login}/.profile && \
    echo "export PATH=".:/home/${container_login}/shared/\${MY_BOSH_USER}/bin:/home/${container_login}/shared/tools:/usr/local/go/bin:${PATH}"" >> /home/${container_login}/.profile && \
    echo "if [ -f /home/${container_login}/shared/tools/bosh_cli_name ] ; then export BOSH_CLI_NAME=\`cat /home/${container_login}/shared/tools/bosh_cli_name\` ; else export BOSH_CLI_NAME=\"bosh-cli\" ; fi" >> /home/${container_login}/.profile && \
    printf "export PS1='\${debian_chroot:+(\$debian_chroot)}\[\\\033[01;32m\]\h@\${BOSH_CLI_NAME}\[\\\033[00m\]:\[\\\033[01;34m\]\w\[\\\033[00m\]$ '\n" >> /home/${container_login}/.profile && \
    printf  "echo -en \"\\\033]0;\${MY_BOSH_USER}@\${BOSH_CLI_NAME}:\${PWD}\\\007\"\n" >> /home/${container_login}/.profile && \
    echo "if [ ! -d \${HOME} ] ; then mkdir -p \${HOME} ; fi" >> /home/${container_login}/.profile && \
    echo "if [ ! -d \${HOME}/.cf ] ; then ln -s /home/${container_login}/.cf \${HOME}/.cf ; fi" >> /home/${container_login}/.profile && \
    echo "if [ -f \${HOME}/.bashrc ] ; then . \${HOME}/.bashrc ; fi" >> /home/${container_login}/.profile && \
    echo "cd \${HOME}" >> /home/${container_login}/.profile && \
    find /var/log -type f -delete && touch /var/log/lastlog && chgrp utmp /var/log/lastlog && chmod 664 /var/log/lastlog

#--- Launch supervisord daemon
EXPOSE 22
CMD /usr/local/bin/supervisord
