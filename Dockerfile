FROM ubuntu:latest
USER root

ENV container_login bosh
ENV container_password welcome

ENV bosh_cli_version 1.3167.0
ENV bosh_init_version 0.0.81
ENV bosh_gen_version 0.22.0
ENV spiff_version 1.0.7
ENV cf_cli_version 6.14.1
ENV cf_uaac_version 3.1.5
ENV bundler_version 1.11.2

# Add wget package, update the image and install missing packages
RUN apt-get update && \
    apt-get install -y wget && \
    echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" > /etc/apt/sources.list.d/git-core-ppa-trusty.list && \
    wget --quiet -O- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xA1715D88E1DF1F24" | sudo apt-key add - && \
    echo "deb http://ppa.launchpad.net/ubuntu-lxc/lxd-stable/ubuntu trusty main" > /etc/apt/sources.list.d/lxd-stable.list && \
    wget --quiet -O- "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD5495F657635B973" | sudo apt-key add - && \
    apt-get update && \
    apt-get install -y openssh-server \
      curl \
      git-core \
      golang \
      unzip \
      openssl \
      s3cmd \
      screen \
      sudo \
      vim \
      wget \
      build-essential \
      libxml2-dev \
      libsqlite3-dev \
      libxslt1-dev \
      libpq-dev \
      libmysqlclient-dev \
      libssl-dev \
      zlib1g-dev && \
    apt-get upgrade -y && \
    apt-get clean && \
    /bin/bash -c "echo \"export GOPATH=*HOME/go\" | tr \"*\" \"$\" > /etc/profile.d/go.sh" && \
    /bin/bash -c "echo \"export PATH=*PATH:*GOPATH/bin\" | tr \"*\" \"$\" >> /etc/profile.d/go.sh" && \
    chmod 755 /etc/profile.d/go.sh

# We setup SSH access & secure root login
# SSH login fix. Otherwise user is kicked off after login
RUN mkdir -p /var/run/sshd && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile && \
    echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd
ENV NOTVISIBLE "in users profile"

# Install RVM, bundler, bosh, bosh-gen & uaa client (uaac)
RUN command curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -L https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy rvm requirements" && \
    apt-get clean && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy rvm install 2.2" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy rvm use 2.2" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install bundler --no-ri --no-rdoc -v ${bundler_version}" && \ 
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install bosh_cli --no-ri --no-rdoc -v ${bosh_cli_version}" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install bosh-gen --no-ri --no-rdoc -v ${bosh_gen_version}" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install cf-uaac --no-ri --no-rdoc -v ${cf_uaac_version}"

# Create bosh user
RUN useradd -m -g users -G sudo,rvm -s /bin/bash ${container_login} && \
    echo "${container_login} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${container_login} && \
    echo "${container_login}:${container_password}" | chpasswd && \
    chage -d 0 ${container_login}

# Install bosh-init, spiff, cf-cli, certstrap & several cf cli plugins
RUN wget -O /usr/local/bin/bosh-init "https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${bosh_init_version}-linux-amd64" && \
    chmod 755 /usr/local/bin/bosh-init && \
    wget -O /tmp/spiff_linux_amd64.zip "https://github.com/cloudfoundry-incubator/spiff/releases/download/v${spiff_version}/spiff_linux_amd64.zip" && \
    unzip /tmp/spiff_linux_amd64.zip -d /usr/local/bin && \
    chmod 755 /usr/local/bin/spiff && \
    rm /tmp/spiff_linux_amd64.zip && \
    wget -O /tmp/cf.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_version}&source=github-rel" && \
    dpkg -i /tmp/cf.deb && \
    rm /tmp/cf.deb && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy go get -v github.com/square/certstrap" --login ${container_login} && \
    mkdir -p /home/${container_login}_non_persistent_storage/cf_plugins && \
    chown -R ${container_login}:users /home/${container_login}_non_persistent_storage && \
    chmod 700 /home/${container_login}_non_persistent_storage && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'CLI-Recorder' -r CF-Community -f" --login ${container_login} && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'Diego-Enabler' -r CF-Community -f" --login ${container_login} && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'doctor' -r CF-Community -f" --login ${container_login} && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'manifest-generator' -r CF-Community -f" --login ${container_login} && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'Statistics' -r CF-Community -f" --login ${container_login} && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'targets' -r CF-Community -f" --login ${container_login} && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy cf install-plugin 'Usage Report' -r CF-Community -f" --login ${container_login}

# Setup profile
ADD scripts/homedir.sh scripts/cf.sh /etc/profile.d/
RUN chmod 755 /etc/profile.d/homedir.sh && \
    /bin/bash -c 'mkdir -p /home/${container_login}/{deployments,releases,git,.ssh}' && \
    ln -s /tmp /home/${container_login}/tmp && \
    touch /home/${container_login}/.ssh/authorized_keys && \
    chmod 700 /home/${container_login}/.ssh && \
    chmod 600 /home/${container_login}/.ssh/authorized_keys && \
    mkdir -p /data && \
    chown -R ${container_login}:users /home/${container_login} && \
    chown ${container_login}:users /data && \
    chmod 700 /home/${container_login}

# Cleanup
RUN apt-get clean && \
    apt-get autoremove -y && \
    apt-get purge && \
    find /var/log -type f -delete && \
    rm -Rf /tmp/*

# Launch sshd daemon
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]