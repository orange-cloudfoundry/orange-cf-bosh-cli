FROM ubuntu:latest
MAINTAINER François Bonelle <francois.bonelle@orange.com>

USER root

ENV container_login="bosh" \
    container_password="welcome" \
    bosh_cli_version="1.3262.4.0" \
    bosh_init_version="0.0.96" \
    bosh_gen_version="0.22.0" \
    spiff_version="1.0.7" \
    spiff_reloaded_version="1.0.8-ms.5" \
    spruce_version="1.8.1" \
    cf_cli_version="6.21.1" \
    cf_uaac_version="3.4.0" \
    bundler_version="1.13.1" \
    cf_plugins="CLI-Recorder,Diego-Enabler,doctor,manifest-generator,Statistics,targets,Usage Report"

# Add wget package, update the image and install missing packages
RUN apt-get update && \
    apt-get install -y wget && \
    apt-get install -y sudo && \
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
      supervisor \
      vim \
      nano \
      build-essential \
      libxml2-dev \
      libsqlite3-dev \
      libxslt1-dev \
      libpq-dev \
      libmysqlclient-dev \
      libssl-dev \
      zlib1g-dev && \
    apt-get upgrade -y && \
    apt-get clean
ADD scripts/go.sh /etc/profile.d/
RUN chmod 755 /etc/profile.d/go.sh

# We setup SSH access & secure root login
# SSH login fix. Otherwise user is kicked off after login
ADD scripts/supervisord scripts/check_ssh_security /usr/local/bin/
ADD supervisord/sshd.conf /etc/supervisor/conf.d/
RUN mkdir -p /var/run/sshd /var/log/supervisor && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config && \
    echo "export VISIBLE=now" >> /etc/profile && \
    echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd && \
    sed -i "s/<username>/$container_login/g" /usr/local/bin/check_ssh_security && \
    chmod 755 /usr/local/bin/check_ssh_security && \
    chmod 755 /usr/local/bin/supervisord
ENV NOTVISIBLE "in users profile"

# Install RVM, bundler, bosh, bosh-gen & uaa client (uaac)
RUN command curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -L https://get.rvm.io | bash && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy rvm requirements" && \
    apt-get clean && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy rvm install 2.3" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy rvm use 2.3" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install bundler --no-ri --no-rdoc -v ${bundler_version}" && \ 
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install bosh_cli --no-ri --no-rdoc -v ${bosh_cli_version}" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install bosh-gen --no-ri --no-rdoc -v ${bosh_gen_version}" && \
    /bin/bash -l -c "http_proxy=$http_proxy https_proxy=$https_proxy gem install cf-uaac --no-ri --no-rdoc -v ${cf_uaac_version}" && \
    /bin/bash -l -c "rvm cleanup all"

# Create bosh user & setup profile
ADD scripts/homedir.sh scripts/cf.sh /etc/profile.d/
RUN chmod 755 /etc/profile.d/homedir.sh && \
    chmod 755 /etc/profile.d/cf.sh && \
    useradd -m -g users -G sudo,rvm -s /bin/bash ${container_login} && \
    echo "${container_login} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${container_login} && \
    echo "${container_login}:${container_password}" | chpasswd && \
    chage -d 0 ${container_login} && \
    /bin/bash -c 'mkdir -p /home/${container_login}/{deployments,releases,git,.ssh}' && \
    chmod 700 /home/${container_login}/.ssh && \
    touch /home/${container_login}/.ssh/authorized_keys && \
    chmod 600 /home/${container_login}/.ssh/authorized_keys && \
    ln -s /tmp /home/${container_login}/tmp && \
    chown -R ${container_login}:users /home/${container_login} && \
    mkdir -p /data && \
    chmod 700 /home/${container_login} && \
    chown ${container_login}:users /data

# Install bosh-init, spiff, spiff reloaded, cf-cli, certstrap & several cf cli plugins
RUN wget -O /usr/local/bin/bosh-init "https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${bosh_init_version}-linux-amd64" && \
    chmod 755 /usr/local/bin/bosh-init && \
    wget -O /tmp/spiff_linux_amd64.zip "https://github.com/cloudfoundry-incubator/spiff/releases/download/v${spiff_version}/spiff_linux_amd64.zip" && \
    unzip /tmp/spiff_linux_amd64.zip -d /usr/local/bin && \
    chmod 755 /usr/local/bin/spiff && \
    rm /tmp/spiff_linux_amd64.zip && \
    wget -O /tmp/spiff_linux_amd64.zip "https://github.com/mandelsoft/spiff/releases/download/v${spiff_reloaded_version}/spiff_linux_amd64.zip" && \
    unzip /tmp/spiff_linux_amd64.zip -d /usr/local/bin && \
    chmod 755 /usr/local/bin/spiff++ && \
    rm /tmp/spiff_linux_amd64.zip && \
    wget -O /usr/local/bin/spruce "https://github.com/geofffranks/spruce/releases/download/v${spruce_version}/spruce-linux-amd64" && \
    chmod 755 /usr/local/bin/spruce && \
    wget -O /tmp/cf.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_version}&source=github-rel" && \
    dpkg -i /tmp/cf.deb && \
    rm /tmp/cf.deb && \
    su -c "http_proxy=$http_proxy https_proxy=$https_proxy go get -v github.com/square/certstrap" --login ${container_login} && \
    mkdir -p /home/${container_login}_non_persistent_storage/cf_plugins && \
    chown -R ${container_login}:users /home/${container_login}_non_persistent_storage && \
    chmod 700 /home/${container_login}_non_persistent_storage && \
    su -c "export http_proxy=$http_proxy;export https_proxy=$https_proxy;export IFS=,;for plug in \`echo $cf_plugins\`; do cf install-plugin \"\$plug\" -r CF-Community -f; done" --login ${container_login} --shell /bin/bash && \
    rm -Rf /tmp/*

# Final settings & Cleanup
ADD scripts/motd /etc/
RUN GIT_VERSION=`git --version | awk '{print $3}'` && \
    CERTSTRAP_VERSION=`su -c "certstrap --version | awk '{print \\$3}'" --login bosh` && \
    sed -i "s/<bosh-version>/$bosh_cli_version/g" /etc/motd && \
    sed -i "s/<cf-version>/$cf_cli_version/g" /etc/motd && \
    sed -i "s/<cf-uaac-version>/$cf_uaac_version/g" /etc/motd && \
    sed -i "s/<spiff-version>/$spiff_version/g" /etc/motd && \
    sed -i "s/<spiff-reloaded-version>/$spiff_reloaded_version/g" /etc/motd && \	
    sed -i "s/<spruce-version>/$spruce_version/g" /etc/motd && \
    sed -i "s/<bosh-gen-version>/$bosh_gen_version/g" /etc/motd && \
    sed -i "s/<bosh-init-version>/$bosh_init_version/g" /etc/motd && \
    sed -i "s/<certstrap-version>/$CERTSTRAP_VERSION/g" /etc/motd && \
    sed -i "s/<git-version>/$GIT_VERSION/g" /etc/motd && \
    chmod 644 /etc/motd && \
    apt-get clean && \
    apt-get autoremove -y && \
    apt-get purge && \
    find /var/log -type f -delete && \
    rm -Rf /tmp/* && \
    touch /var/log/lastlog && \
    chgrp utmp /var/log/lastlog && \
    chmod 664 /var/log/lastlog

# Launch supervisord daemon
EXPOSE 22
CMD /usr/local/bin/supervisord
