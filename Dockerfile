FROM ubuntu:14.04
USER root

ENV container_login bosh
ENV container_password welcome
ENV bosh_init_version 0.0.80
ENV cf_cli_version 6.14.0
ENV spiff_version 1.0.7
ENV bundler_version 1.11.2
ENV bosh_cli_version 1.3167.0
ENV bosh_gen_version 0.22.0
ENV cf_uaac_version 3.1.5

# ENV http_proxy 'http://192.168.10.254:3128'
# ENV https_proxy 'http://192.168.10.254:3128'

# Add wget package
RUN apt-get update && \
	apt-get install -y wget

# Update of image and install missing packages
RUN echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu trusty main" > /etc/apt/sources.list.d/git-core-ppa-trusty.list && \
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
	  wget \
	  build-essential \
	  libxml2-dev \
	  libsqlite3-dev \
	  libxslt1-dev \
	  libpq-dev \
	  libmysqlclient-dev \
	  libssl-dev \
	  zlib1g-dev && \
	apt-get upgrade -y

# We setup SSH access
RUN mkdir -p /var/run/sshd
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Install RVM
RUN command curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
	curl -L https://get.rvm.io | bash -s stable && \
	/bin/bash -l -c "rvm requirements" && \
	/bin/bash -l -c "rvm install 2.2" && \
	/bin/bash -l -c "rvm use 2.2"

# Install bundler, bosh, bosh-gen & uaa client (uaac)
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc -v ${bundler_version}" && \ 
	/bin/bash -l -c "gem install bosh_cli --no-ri --no-rdoc -v ${bosh_cli_version}" && \
	/bin/bash -l -c "gem install bosh-gen --no-ri --no-rdoc -v ${bosh_gen_version}" && \
	/bin/bash -l -c "gem install cf-uaac --no-ri --no-rdoc -v ${cf_uaac_version}"
	
# Create /usr/local/bin
RUN mkdir -p /usr/local/bin && \
	chmod 755 /usr/local/bin

# Install bosh-init
RUN wget -O /usr/local/bin/bosh-init "https://s3.amazonaws.com/bosh-init-artifacts/bosh-init-${bosh_init_version}-linux-amd64" && \
	chmod 755 /usr/local/bin/bosh-init

# Install spiff
RUN wget -O /tmp/spiff_linux_amd64.zip "https://github.com/cloudfoundry-incubator/spiff/releases/download/v${spiff_version}/spiff_linux_amd64.zip" && \
	unzip /tmp/spiff_linux_amd64.zip -d /usr/local/bin && \
	chmod 755 /usr/local/bin/spiff && \
	rm /tmp/spiff_linux_amd64.zip

# Install cf cli
RUN wget -O /tmp/cf.deb "https://cli.run.pivotal.io/stable?release=debian64&version=${cf_cli_version}&source=github-rel" && \
	dpkg -i /tmp/cf.deb && \
	rm /tmp/cf.deb

# Create bosh user
RUN useradd -m -g users -G sudo,rvm -s /bin/bash ${container_login} && \
	echo "${container_login} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${container_login} && \
	echo "${container_login}:${container_password}" | chpasswd && \
	chage -d 0 ${container_login}

# Install certstrap
RUN /bin/bash -c "echo \"export GOPATH=*HOME/go\" | tr \"*\" \"$\" > /etc/profile.d/go.sh" && \
	/bin/bash -c "echo \"export PATH=*PATH:*GOPATH/bin\" | tr \"*\" \"$\" >> /etc/profile.d/go.sh" && \
	chmod 755 /etc/profile.d/go.sh
USER ${container_login}
WORKDIR /home/${container_login}
RUN export GOPATH=/home/${container_login}/go && \
	go get -v github.com/square/certstrap

# Create standard directories & files
USER ${container_login}
WORKDIR /home/${container_login}
RUN mkdir deployments releases git .ssh && \
	ln -s /tmp tmp && \
	touch .ssh/authorized_keys && \
	chmod 600 .ssh/authorized_keys
USER root
RUN chmod 700 /home/${container_login}/.ssh
WORKDIR /home
RUN tar -cvf ${container_login}.tar \
			 ${container_login}/deployments \
			 ${container_login}/releases \
			 ${container_login}/git \
			 ${container_login}/.ssh \
			 ${container_login}/.bash_logout \
			 ${container_login}/.bashrc \
			 ${container_login}/.profile \
			 ${container_login}/go && \
	rm -Rf ${container_login} && \
	mkdir ${container_login} && \
	chown ${container_login}:users ${container_login}
ADD	scripts/bootstrap.sh /etc/profile.d/
RUN sed -i /etc/profile.d/bootstrap.sh -e "s/<container_login>/${container_login}/" && \
    chmod 755 /etc/profile.d/bootstrap.sh

# Secure root login
RUN echo "root:`date +%s | sha256sum | base64 | head -c 32 ; echo`" | chpasswd

# Final cleanup
RUN apt-get clean

# Launch sshd daemon
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]