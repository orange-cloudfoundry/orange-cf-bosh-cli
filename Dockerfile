ROM ubuntu:22.04 AS orange_cli
USER root
ARG DEBIAN_FRONTEND=noninteractive

#--- Clis versions
ENV ARGO_CLI_VERSION="3.4.7" \
    BBR_VERSION="1.9.38" \
    BOSH_CLI_VERSION="7.2.3" \
    BOSH_CLI_COMPLETION_VERSION="1.2.0" \
    BOSH_GEN_VERSION="0.101.2" \
    CF_CLI_VERSION="8.6.1" \
    CF_UAAC_VERSION="4.14.0" \
    CILIUM_VERSION="0.14.3" \
    CREDHUB_VERSION="2.9.15" \
    FLUX_VERSION="0.41.2" \
    FLY_VERSION="7.9.1" \
    GITHUB_VERSION="2.29.0" \
    GOVC_VERSION="0.30.4" \
    GO3FR_VERSION="0.5.0" \
    HELM_VERSION="3.9.4" \
    JQ_VERSION="1.6" \
    KAPP_VERSION="0.56.0" \
    KCTRL_VERSION="0.45.1" \
    KLBD_VERSION="0.37.1" \
    KREW_VERSION="0.4.3" \
    KUBECTL_VERSION="1.24.9" \
    KUBECTL_WHOAMI_VERSION="0.0.46" \
    KUBECTX_VERSION="0.9.4" \
    KUSTOMIZE_VERSION="4.5.7" \
    K9S_VERSION="0.27.4" \
    MONGO_SHELL_VERSION="4.0.25" \
    MYSQL_SHELL_VERSION="8.0.33-1" \
    OC_CLI_VERSION="4.10.25" \
    OCM_CLI_VERSION="0.1.65" \
    RBAC_TOOL_VERSION="1.14.1" \
    REDIS_CLI_VERSION="6.2.4" \
    RUBY_BUNDLER_VERSION="2.3.18" \
    RUBY_VERSION="3.1.2" \
    SHIELD_VERSION="8.8.5" \
    SPRUCE_VERSION="1.30.2" \
    TERRAFORM_PLUGIN_CF_VERSION="0.11.2" \
    TERRAFORM_VERSION="0.11.14" \
    TEST_KUBE_VERSION="1.11.22" \
    TFCTL_CLI_VERSION="0.14.2" \
    VCLUSTER_VERSION="0.15.0" \
    VENDIR_VERSION="0.33.2" \
    YAML_PATH_VERSION="0.4" \
    YQ_VERSION="4.33.3" \
    YTT_VERSION="0.45.1"

#--- Packages list, ruby env and plugins
ENV INIT_PACKAGES="apt-transport-https ca-certificates curl openssh-server openssl sudo unzip wget" \
    TOOLS_PACKAGES="apg bash-completion colordiff git-core gnupg htop less locales nano python3-tabulate python3-openstackclient s3cmd silversearcher-ag supervisor tinyproxy tmux byobu yarnpkg vim" \
    NET_PACKAGES="dnsutils iproute2 iputils-ping iputils-tracepath traceroute tcptraceroute ldap-utils mtr-tiny netbase netcat net-tools tcpdump whois iperf3" \
    DEV_PACKAGES="build-essential libc6-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev zlib1g-dev libcurl4-openssl-dev" \
    RUBY_PACKAGES="gawk g++ gcc autoconf automake bison libgdbm-dev libncurses5-dev libtool libyaml-dev pkg-config sqlite3 libgmp-dev libreadline6-dev" \
    PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}/bin:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:${PATH}" \
    GEM_HOME="/usr/local/rvm/gems/ruby-${RUBY_VERSION}" \
    GEM_PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global" \
    CF_PLUGINS="CLI-Recorder,doctor,manifest-generator,Statistics,Targets,Usage Report" \
    KUBECTL_PLUGINS="ctx,get-all,ns,kuttl" \
    OS_ARCH_1="x86_64" \
    OS_ARCH_2="amd64"

ADD tools/* /tmp/tools/
ADD tools/completion/* /tmp/tools/completion/

RUN printf '\n=====================================================\n Install system packages\n=====================================================\n' && \
    apt-get update && apt-get install -y --no-install-recommends apt-utils dialog && \
    apt-get install -y --no-install-recommends ${INIT_PACKAGES} ${TOOLS_PACKAGES} ${NET_PACKAGES} ${DEV_PACKAGES} ${RUBY_PACKAGES} && \
    locale-gen en_US.UTF-8 && \
    printf '\n=====================================================\n Install ruby tools\n=====================================================\n' && \
    curl -sSL https://rvm.io/mpapis.asc | gpg --import - && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -l -c "source /etc/profile.d/rvm.sh ; rvm install ${RUBY_VERSION}" && \
    /bin/bash -l -c "gem install bundler -v ${RUBY_BUNDLER_VERSION} --no-document" && \
    /bin/bash -l -c "gem install bosh-gen -v ${BOSH_GEN_VERSION} --no-document" && \
    /bin/bash -l -c "gem install cf-uaac -v ${CF_UAAC_VERSION} --no-document" && \
    /bin/bash -l -c "gem install mdless --no-document" && \
    /bin/bash -l -c "rvm cleanup all" && \
    printf '\n=====================================================\n Setup account, ssh, supervisor and system banner\n=====================================================\n' && \
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
    sed -i 's/^#Upstream http some.*/upstream http system-internet-http-proxy.internal.paas:3128 ".openshiftapps.com"/' /etc/tinyproxy/tinyproxy.conf && \
    sed -i 's/^ConnectPort 443/#ConnectPort 443/' /etc/tinyproxy/tinyproxy.conf && \
    sed -i 's/^ConnectPort 563/#ConnectPort 563/' /etc/tinyproxy/tinyproxy.conf && \
    printf '\nYour are logged into an ubuntu docker tools container :' > /etc/motd && \
    printf '\n- "tools" command display available tools.' >> /etc/motd && \
    printf '\n- "/data" is the only persistant volume (do not save data on other fs).\n\n' >> /etc/motd && chmod 644 /etc/motd && \
    printf '\n=====================================================\n Install clis and tools\n=====================================================\n' && \
    printf '\n=> Add ARGO-CLI\n' && curl -sSLo /tmp/argo.gz "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_CLI_VERSION}/argo-linux-${OS_ARCH_2}.gz" && gunzip /tmp/argo.gz && mv /tmp/argo /usr/local/bin/argo && \
    printf '\n=> Add ARGO-CLI completion\n' && chmod 755 /usr/local/bin/argo && argo completion bash > /etc/bash_completion.d/argo && \
    printf '\n=> Add BBR-CLI\n' && curl -sSL "https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v${BBR_VERSION}/bbr-${BBR_VERSION}.tar" | tar -x -C /tmp && mv /tmp/releases/bbr /usr/local/bin/bbr && \
    printf '\n=> Add BOSH-CLI\n' && curl -sSLo /usr/local/bin/bosh "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${BOSH_CLI_VERSION}-linux-${OS_ARCH_2}" && \
    printf '\n=> Add BOSH-CLI completion\n' && curl -sSLo /home/bosh/bosh-complete-linux "https://github.com/thomasmmitchell/bosh-complete/releases/download/v${BOSH_CLI_COMPLETION_VERSION}/bosh-complete-linux" && chmod 755 /home/bosh/bosh-complete-linux && \
    printf '\n=> Add CF-CLI\n' && curl -sSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_CLI_VERSION}&source=github-rel" | tar -xz -C /tmp && mv /tmp/cf8 /usr/local/bin/cf && \
    printf '\n=> Add CF-CLI completion\n' && curl -sSLo /etc/bash_completion.d/cf "https://raw.githubusercontent.com/cloudfoundry/cli-ci/master/ci/installers/completion/cf7" && \
    printf '\n=> Add CF-PLUGINS\n' && su -l bosh -s /bin/bash -c "export IFS=, ; for plugin in \$(echo \"${CF_PLUGINS}\") ; do cf install-plugin \"\${plugin}\" -r CF-Community -f ; done" && \
    printf '\n=> Add CMDB-CLI-FUNCTIONS\n' && git clone --depth 1 https://github.com/orange-cloudfoundry/cf-cli-cmdb-scripts.git /tmp/cf-cli-cmdb-scripts && mv /tmp/cf-cli-cmdb-scripts/cf-cli-cmdb-functions.bash /usr/local/bin/cf-cli-cmdb-functions.bash && \
    printf '\n=> Add CILIUM-CLI\n' && curl -sSL "https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_VERSION}/cilium-linux-${OS_ARCH_2}.tar.gz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add CILIUM-CLI completion\n' && chmod 755 /usr/local/bin/cilium && cilium completion bash > /etc/bash_completion.d/cilium && \
    printf '\n=> Add CREDHUB-CLI\n' && curl -sSL "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-${CREDHUB_VERSION}.tgz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add FLUX-CLI\n' && curl -sSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add FLUX-CLI completion\n' && chmod 755 /usr/local/bin/flux && flux completion bash > /etc/bash_completion.d/flux && \
    printf '\n=> Add FLY-CLI\n' && curl -sSL "https://github.com/concourse/concourse/releases/download/v${FLY_VERSION}/fly-${FLY_VERSION}-linux-${OS_ARCH_2}.tgz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add GCLOUD-CLI\n' && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list && chmod 1777 /tmp && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && apt-get update && apt-get install -y --no-install-recommends google-cloud-cli && \
    printf '\n=> Add GIT-FILTER-REPO\n' && curl -sSLo /usr/local/bin/git-filter-repo "https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo" && \
    printf '\n=> Add GITHUB-CLI\n' && curl -sSL "https://github.com/cli/cli/releases/download/v${GITHUB_VERSION}/gh_${GITHUB_VERSION}_linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/gh_${GITHUB_VERSION}_linux_${OS_ARCH_2}/bin/gh /usr/local/bin/gh && \
    printf '\n=> Add GITHUB-CLI completion\n' && chmod 755 /usr/local/bin/gh && /usr/local/bin/gh completion -s bash > /etc/bash_completion.d/gh && \
    printf '\n=> Add GOVC-CLI\n' && curl -sSL "https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/govc_Linux_${OS_ARCH_1}.tar.gz" | tar -xz -C /tmp && mv /tmp/govc /usr/local/bin/govc && \
    printf '\n=> Add GO3FR-CLI\n' && curl -sSL "https://github.com/rlmcpherson/s3gof3r/releases/download/v${GO3FR_VERSION}/gof3r_${GO3FR_VERSION}_linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/gof3r_${GO3FR_VERSION}_linux_${OS_ARCH_2}/gof3r /usr/local/bin/go3fr && \
    printf '\n=> Add HELM-CLI\n' && curl -sSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/linux-${OS_ARCH_2}/helm /usr/local/bin/helm && \
    printf '\n=> Add HELM-CLI completion\n' && chmod 755 /usr/local/bin/helm && /usr/local/bin/helm completion bash > /etc/bash_completion.d/helm && \
    printf '\n=> Add JQ-CLI\n' && curl -sSLo /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" && \
    printf '\n=> Add KAPP-CLI\n' && curl -sSLo /usr/local/bin/kapp "https://github.com/k14s/kapp/releases/download/v${KAPP_VERSION}/kapp-linux-${OS_ARCH_2}" && \
    printf '\n=> Add KAPP-CLI completion\n' && chmod 755 /usr/local/bin/kapp && kapp completion bash | grep -v Succeeded > /etc/bash_completion.d/kapp && \
    printf '\n=> Add KCTRL-CLI\n' && curl -sSLo /usr/local/bin/kctrl "https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v${KCTRL_VERSION}/kctrl-linux-${OS_ARCH_2}" && \
    printf '\n=> Add KCTRL-CLI completion\n' && chmod 755 /usr/local/bin/kctrl && kctrl completion bash | grep -v Succeeded > /etc/bash_completion.d/kctrl && \
    printf '\n=> Add KLBD-CLI\n' && curl -sSLo /usr/local/bin/klbd "https://github.com/k14s/kbld/releases/download/v${KLBD_VERSION}/kbld-linux-${OS_ARCH_2}" && \
    printf '\n=> Add KREW-CLI\n' && curl -sSL "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/krew-linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && chmod 1777 /tmp && \
    printf '\n=> Add KUBECTL-CLI\n' && curl -sSLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${OS_ARCH_2}/kubectl" && \
    printf '\n=> Add KUBECTL-CLI completion\n' && chmod 755 /usr/local/bin/kubectl && /usr/local/bin/kubectl completion bash > /etc/bash_completion.d/kubectl && sed -i "s+__start_kubectl kubectl+__start_kubectl kubectl k+g" /etc/bash_completion.d/kubectl && \
    printf '\n=> Add KUBECTL_PLUGINS\n' && su -l bosh -s /bin/bash -c "export KREW_ROOT=/home/bosh/.krew ; export PATH=/home/bosh/.krew/bin:${PATH} ; /tmp/krew-linux_${OS_ARCH_2} install krew ; export IFS=, ; for plugin in \$(echo \"${KUBECTL_PLUGINS}\") ; do kubectl krew install \${plugin} ; done" && \
    printf '\n=> Add KUBECTL_WHOAMI\n' && curl -sSL "https://github.com/rajatjindal/kubectl-whoami/releases/download/v${KUBECTL_WHOAMI_VERSION}/kubectl-whoami_v${KUBECTL_WHOAMI_VERSION}_linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/kubectl-whoami /usr/local/bin/ && \
    printf '\n=> Add KUBECTX-CLI\n' && curl -sSL "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_${OS_ARCH_1}.tar.gz" | tar -xz -C /tmp && mv /tmp/kubectx /usr/local/bin/kubectx && \
    printf '\n=> Add KUBENS-CLI\n' && curl -sSL "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_${OS_ARCH_1}.tar.gz" | tar -xz -C /tmp && mv /tmp/kubens /usr/local/bin/kubens && \
    printf '\n=> Add KUSTOMIZE-CLI\n' && curl -sSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/kustomize /usr/local/bin/kustomize && \
    printf '\n=> Add KUSTOMIZE-CLI completion\n' && chmod 755 /usr/local/bin/kustomize && /usr/local/bin/kustomize completion bash > /etc/bash_completion.d/kustomize && \
    printf '\n=> Add K9S-CLI\n' && curl -sSL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/k9s /usr/local/bin/k9s && \
    printf '\n=> Add MINIO-CLI\n' && curl -sSLo /usr/local/bin/mc "https://dl.minio.io/client/mc/release/linux-${OS_ARCH_2}/mc" && \
    printf '\n=> Add MONGO-SHELL-CLI\n' && curl -sSL "https://fastdl.mongodb.org/linux/mongodb-linux-${OS_ARCH_1}-${MONGO_SHELL_VERSION}.tgz" | tar -xz -C /tmp && cd /tmp/mongodb-linux-${OS_ARCH_1}-${MONGO_SHELL_VERSION}/bin && mv mongo mongostat mongotop /usr/local/bin && \
    printf '\n=> Add MYSQL-SHELL-CLI\n' && curl -sSLo /tmp/mysql-shell.deb "https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${MYSQL_SHELL_VERSION}ubuntu22.04_${OS_ARCH_2}.deb" && dpkg -i /tmp/mysql-shell.deb && \
    printf '\n=> Add OC-CLI\n' && curl -sSL "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_CLI_VERSION}/openshift-client-linux-${OC_CLI_VERSION}.tar.gz" | tar -xz -C /tmp && mv /tmp/oc /usr/local/bin/oc && \
    printf '\n=> Add OC-CLI completion\n' && chmod 755 /usr/local/bin/oc && /usr/local/bin/oc completion bash > /etc/bash_completion.d/oc && \
    printf '\n=> Add OCM-CLI\n' && curl -sSLo /usr/local/bin/ocm "https://github.com/openshift-online/ocm-cli/releases/download/v${OCM_CLI_VERSION}/ocm-linux-${OS_ARCH_2}" && \
    printf '\n=> Add OCM-CLI completion\n' && chmod 755 /usr/local/bin/ocm && /usr/local/bin/ocm completion bash > /etc/bash_completion.d/ocm && \
    printf '\n=> Add RBAC-TOOL-CLI\n' && curl -sSL "https://github.com/alcideio/rbac-tool/releases/download/v${RBAC_TOOL_VERSION}/rbac-tool_v${RBAC_TOOL_VERSION}_linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/rbac-tool /usr/local/bin/rbac-tool && \
    printf '\n=> Add RBAC-TOOL-CLI completion\n' && chmod 755 /usr/local/bin/rbac-tool && /usr/local/bin/rbac-tool bash-completion > /etc/bash_completion.d/rbac-tool && \
    printf '\n=> Add REDIS-CLI\n' && curl -sSL "https://download.redis.io/releases/redis-${REDIS_CLI_VERSION}.tar.gz" | tar -xz -C /tmp && cd /tmp/redis-${REDIS_CLI_VERSION} && make > /dev/null 2>&1 && mv /tmp/redis-${REDIS_CLI_VERSION}/src/redis-cli /usr/local/bin/redis && chmod 755 /usr/local/bin/redis && \
    printf '\n=> Add SHIELD-CLI\n' && curl -sSLo /usr/local/bin/shield "https://github.com/shieldproject/shield/releases/download/v${SHIELD_VERSION}/shield-linux-${OS_ARCH_2}" && \
    printf '\n=> Add SPRUCE-CLI\n' && curl -sSLo /usr/local/bin/spruce "https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-${OS_ARCH_2}" && \
    printf '\n=> Add TERRAFORM-CLI\n' && curl -sSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${OS_ARCH_2}.zip" && unzip -q /tmp/terraform.zip -d /usr/local/bin && \
    printf '\n=> Add TERRAFORM-CF-PROVIDER\n' && export PROVIDER_CLOUDFOUNDRY_VERSION="v${TERRAFORM_PLUGIN_CF_VERSION}" && /bin/bash -c "$(wget https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O -)" && \
    printf '\n=> Add TEST_KUBE_CLI\n' && curl -sSL "https://github.com/kubeshop/testkube/releases/download/v${TEST_KUBE_VERSION}/testkube_${TEST_KUBE_VERSION}_Linux_${OS_ARCH_1}.tar.gz" | tar -xz -C /tmp && mv /tmp/kubectl-testkube /usr/local/bin/kubectl-testkube && ln -s /usr/local/bin/kubectl-testkube /usr/local/bin/testkube && ln -s /usr/local/bin/kubectl-testkube /usr/local/bin/tk && \
    printf '\n=> Add TEST_KUBE_CLI completion\n' && chmod 755 /usr/local/bin/testkube && /usr/local/bin/testkube completion bash > /etc/bash_completion.d/testkube && sed -i "s+__start_testkube testkube+__start_testkube testkube tk+g" /etc/bash_completion.d/testkube && \
    printf '\n=> Add TFCTL-CLI\n' && curl -sSL "https://github.com/weaveworks/tf-controller/releases/download/v${TFCTL_CLI_VERSION}/tfctl_Linux_${OS_ARCH_2}.tar.gz" | tar -xz -C /usr/local/bin && \
    printf '\n=> Add VCLUSTER-CLI\n' && curl -sSLo /usr/local/bin/vcluster "https://github.com/loft-sh/vcluster/releases/download/v${VCLUSTER_VERSION}/vcluster-linux-${OS_ARCH_2}" && \
    printf '\n=> Add VCLUSTER-CLI completion\n' && chmod 755 /usr/local/bin/vcluster && /usr/local/bin/vcluster completion bash > /etc/bash_completion.d/vcluster && \
    printf '\n=> Add VENDIR-CLI\n' && curl -sSLo /usr/local/bin/vendir "https://github.com/vmware-tanzu/carvel-vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-${OS_ARCH_2}" && \
    printf '\n=> Add YAML-PATH-CLI\n' && curl -sSL "https://github.com/psycofdj/yaml-path/releases/download/v${YAML_PATH_VERSION}/yaml-path-${YAML_PATH_VERSION}.linux-${OS_ARCH_2}.tar.gz" | tar -xz -C /tmp && mv /tmp/yaml-path-${YAML_PATH_VERSION}.linux-${OS_ARCH_2}/yaml-path /usr/local/bin && \
    printf '\n=> Add YQ-CLI\n' && curl -sSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${OS_ARCH_2}" && \
    printf '\n=> Add YQ-CLI completion\n' && chmod 755 /usr/local/bin/yq && yq shell-completion bash | grep -v Succeeded > /etc/bash_completion.d/yq && \
    printf '\n=> Add YTT-CLI\n' && curl -sSLo /usr/local/bin/ytt "https://github.com/k14s/ytt/releases/download/v${YTT_VERSION}/ytt-linux-${OS_ARCH_2}" && \
    printf '\n=> Add YTT-CLI completion\n' && chmod 755 /usr/local/bin/ytt && ytt completion bash | grep -v Succeeded > /etc/bash_completion.d/ytt && \
    printf '\n=> Add XDG-TOOL\n' && printf '#!/bin/bash\necho "Simulating browser invocation from xdg-open call with params: $@"\nsleep 1\nexit 0\n' > /usr/bin/xdg-open && chmod 755 /usr/bin/xdg-open && \
    printf '\n=====================================================\n Configure user account\n=====================================================\n' && \
    mv /tmp/tools/profile /home/bosh/.profile && chmod 664 /home/bosh/.profile && \
    mv /tmp/tools/bash_profile /home/bosh/bash_profile && \
    mv /tmp/tools/bash_aliases /home/bosh/.bash_aliases && \
    mkdir -p /home/bosh/.ssh && chmod 700 /home/bosh /home/bosh/.ssh && \
    mkdir -p /home/bosh/.k9s && mv /tmp/tools/k9s-plugins.yml /home/bosh/.k9s/plugin.yml && \
    mv /tmp/tools/completion/* /etc/bash_completion.d/ && chmod 755 /etc/bash_completion.d/* && \
    mv /tmp/tools/*.sh /usr/local/bin/ && mv /tmp/tools/sshd.conf /etc/supervisor/conf.d/ && \
    printf '\n=====================================================\n Cleanup system\n=====================================================\n' && \
    apt-get autoremove -y && apt-get clean && apt-get purge && \
    rm -fr /tmp/* /var/lib/apt/lists/* /var/tmp/* && find /var/log -type f -delete && \
    touch /var/log/lastlog && chgrp utmp /var/log/lastlog && chmod 664 /var/log/lastlog && \
    chmod 1777 /tmp && chmod 755 /usr/local/bin/* /etc/profile.d/* && \
    rm -f /usr/local/bin/*.md /usr/local/bin/LICENSE && \
    find /usr/local/bin -print0 | xargs -0 chown root:root && find /home/bosh /data -print0 | xargs -0 chown bosh:users

#--- Run supervisord daemon
CMD /usr/local/bin/supervisord.sh
EXPOSE 22

#--- Check clis/tools availability
FROM orange_cli AS tests
RUN /usr/local/bin/check-available-clis.sh

#--- Export image
FROM orange_cli