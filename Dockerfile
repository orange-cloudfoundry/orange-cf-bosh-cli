FROM ubuntu:latest
MAINTAINER Olivier Grand <oliv.grand@orange.com>
USER root

#--- Tools versions
ENV bundler_version="1.13.6" \
    bosh_init_version="0.0.103" \
    bosh_gen_version="0.22.0" \
    bosh_cli_version="1.3262.26.0" \
    bosh_cli_v2_version="2.0.36" \
    spiff_version="1.0.8" \
    spiff_reloaded_version="1.0.8-ms.6" \
    spruce_version="1.8.9" \
    cf_cli_version="6.30.0" \
    cf_uaac_version="3.4.0" \
    terraform_version="0.9.8" \
    terraform_pcf_version="0.7.3" \
    fly_version="3.4.1" \
    credhub_version="1.1.0" \
    jq_version="1.5" \
    ruby_version="2.3.3" \
    golang_version="1.8.3" \
    container_login="bosh" \
    container_password="welcome" \
    cf_plugins="CLI-Recorder,Diego-Enabler,doctor,manifest-generator,Statistics,Targets,Usage Report"

#--- Update image and install tools packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates apt-utils wget sudo && \
    echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" > /etc/apt/sources.list.d/git-core-ppa-trusty.list && \
    echo "deb http://ppa.launchpad.net/ubuntu-lxc/lxd-stable/ubuntu trusty main" > /etc/apt/sources.list.d/lxd-stable.list && \
    echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list && \
    wget -q -O - "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA1715D88E1DF1F24" | sudo apt-key add - && \
    wget -q -O - "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD5495F657635B973" | sudo apt-key add - && \
    wget -q -O - "https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key" | apt-key add - && \
    apt-get update && apt-get install -y --no-install-recommends \
        openssh-server openssl supervisor \
        git-core s3cmd bash-completion curl unzip vim less mlocate nano screen tmux byobu silversearcher-ag colordiff \
        net-tools iproute2 iputils-ping netcat dnsutils apt-transport-https tcpdump shield \
        python-pip python-setuptools python-dev build-essential libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev libssl-dev zlib1g-dev && \
    apt-get upgrade -y && apt-get clean && apt-get autoremove -y && apt-get purge && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
    /bin/bash -l -c "rvm cleanup all" && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

#--- Setup SSH access, secure root login (SSH login fix. Otherwise user is kicked off after login) and create user
ADD scripts/supervisord scripts/check_ssh_security scripts/disable_ssh_password_auth /usr/local/bin/
ADD supervisord/sshd.conf /etc/supervisor/conf.d/
ADD scripts/homedir.sh scripts/cf.sh scripts/go.sh /etc/profile.d/
RUN echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config && \
    mkdir -p /var/run/sshd /var/log/supervisor && \
    chmod 755 /usr/local/bin/supervisord /usr/local/bin/check_ssh_security /usr/local/bin/disable_ssh_password_auth /etc/profile.d/homedir.sh /etc/profile.d/cf.sh /etc/profile.d/go.sh && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    useradd -m -g users -G sudo,rvm -s /bin/bash ${container_login} && \
    echo "${container_login}:${container_password}" | chpasswd && \
    sed -i "s/<username>/${container_login}/g" /usr/local/bin/supervisord && \
    sed -i "s/<username>/${container_login}/g" /usr/local/bin/check_ssh_security && \
    sed -i "s/<username>/${container_login}/g" /usr/local/bin/disable_ssh_password_auth && \
    echo "${container_login} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${container_login} && \
    chage -d 0 ${container_login} && \
    ln -s /tmp /home/${container_login}/tmp && \
    chown -R ${container_login}:users /home/${container_login} && chmod 700 /home/${container_login} && \
    mkdir -p /data && chown ${container_login}:users /data

#--- Install ops tools & cf cli plugins
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile && \
    wget -nv -O /tmp/go.tar.gz https://storage.googleapis.com/golang/go${golang_version}.linux-amd64.tar.gz && tar -xzf /tmp/go.tar.gz -C /usr/local && chmod 755 /etc/profile.d/go.sh && rm -f /tmp/go.tar.gz && \
    wget -nv -O /usr/local/bin/bosh-init "https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${bosh_init_version}-linux-amd64" && chmod 755 /usr/local/bin/bosh-init && \
    wget -nv -O /usr/local/bin/bosh "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${bosh_cli_v2_version}-linux-amd64" && chmod 755 /usr/local/bin/bosh && \
    wget -nv -O /tmp/spiff_linux_amd64.zip "https://github.com/cloudfoundry-incubator/spiff/releases/download/v${spiff_version}/spiff_linux_amd64.zip" && unzip -q /tmp/spiff_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/spiff && rm /tmp/spiff_linux_amd64.zip && \
    wget -nv -O /tmp/spiff_linux_amd64.zip "https://github.com/mandelsoft/spiff/releases/download/v${spiff_reloaded_version}/spiff_linux_amd64.zip" && unzip -q /tmp/spiff_linux_amd64.zip -d /usr/local/bin && chmod 755 /usr/local/bin/spiff++ && rm /tmp/spiff_linux_amd64.zip && \
    wget -nv -O /usr/local/bin/spruce "https://github.com/geofffranks/spruce/releases/download/v${spruce_version}/spruce-linux-amd64" && chmod 755 /usr/local/bin/spruce && \
    wget -nv -O /tmp/cf.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_version}&source=github-rel" && dpkg -i /tmp/cf.deb && rm /tmp/cf.deb && \
    wget -nv -O /usr/local/bin/fly "https://github.com/concourse/concourse/releases/download/v${fly_version}/fly_linux_amd64" && chmod 755 /usr/local/bin/fly && \
    wget -nv -O /tmp/credhub-linux.tgz "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${credhub_version}/credhub-linux-${credhub_version}.tgz" && tar -xzvf /tmp/credhub-linux.tgz -C /usr/local/bin && chmod 755 /usr/local/bin/credhub && rm /tmp/credhub-linux.tgz && \
    wget -nv -O /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${jq_version}/jq-linux64" && chmod 755 /usr/local/bin/jq && \
    wget -nv -O /usr/local/bin/z.sh https://raw.githubusercontent.com/rupa/z/master/z.sh && chmod 755 /usr/local/bin/z.sh && printf "\n# Maintain a jump-list of in use directories\nif [ -f /usr/local/bin/z.sh ] ; then\n  source /usr/local/bin/z.sh\nfi\n" >> /home/${container_login}/.bashrc && \
    wget -nv -O /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip" && unzip -q /tmp/terraform.zip -d /usr/local/bin && chmod 755 /usr/local/bin/terraform && rm /tmp/terraform.zip && \
    export PROVIDER_CLOUDFOUNDRY_VERSION="v${terraform_pcf_version}" && /bin/bash -c "$(wget https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O -)" && \
    export GOPATH=/tmp && export PATH=$PATH:/usr/local/go/bin && \
    go get -v github.com/square/certstrap && mv /tmp/bin/certstrap /usr/local/bin/certstrap && chmod 755 /usr/local/bin/certstrap && rm -fr /tmp/* && \
    go get -v github.com/rlmcpherson/s3gof3r/gof3r && mv /tmp/bin/gof3r /usr/local/bin/gof3r && chmod 755 /usr/local/bin/gof3r && rm -fr /tmp/* && \
    git clone --depth 1 https://github.com/junegunn/fzf.git /home/${container_login}/.fzf && chown -R ${container_login}:users /home/${container_login}/.fzf && su - ${container_login} -c "/home/${container_login}/.fzf/install --all" && \
    sed -i "/source ~\/.fzf.bash/d" /home/${container_login}/.bashrc && \
    printf "# Interactive filter for command-line\nif [ -f /home/${container_login}/.fzf.bash ] ; then\n  source /home/${container_login}/.fzf.bash\nfi\n" >> /home/${container_login}/.bashrc && \
    mkdir -p /home/${container_login}_non_persistent_storage/cf_plugins && chown -R ${container_login}:users /home/${container_login}_non_persistent_storage && chmod 700 /home/${container_login}_non_persistent_storage && \
    su -c "export http_proxy=${http_proxy};export https_proxy=${https_proxy};export IFS=,;for plug in \`echo ${cf_plugins}\`; do cf install-plugin \"\${plug}\" -r CF-Community -f; done" -l ${container_login} -s /bin/bash && \
    pip install --upgrade pip && \
    pip install python-keystoneclient python-novaclient python-swiftclient python-neutronclient python-cinderclient python-glanceclient python-openstackclient && \
    rm -fr /tmp/*

#--- Tools publication on system banner, setup profile & cleanup
ADD scripts/motd /etc/
ADD scripts/profile /home/${container_login}/.profile
RUN chmod 644 /etc/motd && \
    GIT_VERSION=`git --version | awk '{print $3}'` && \
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
    sed -i "s/<credhub_version>/${credhub_version}/g" /etc/motd && \
    sed -i "s/<certstrap_version>/${CERTSTRAP_VERSION}/g" /etc/motd && \
    sed -i "s/<jq_version>/${jq_version}/g" /etc/motd && \
    sed -i "s/<ruby_version>/${ruby_version}/g" /etc/motd && \
    sed -i "s/<golang_version>/${golang_version}/g" /etc/motd && \
    chown -R ${container_login}:users /home/${container_login}/.profile && chmod 644 /home/${container_login}/.profile && \
    sed -i "s/<username>/${container_login}/g" /home/${container_login}/.profile && \
    sed -i "s/<ruby_version>/${ruby_version}/g" /home/${container_login}/.profile && \
    find /var/log -type f -delete && touch /var/log/lastlog && chgrp utmp /var/log/lastlog && chmod 664 /var/log/lastlog

#--- Launch supervisord daemon
EXPOSE 22
CMD /usr/local/bin/supervisord