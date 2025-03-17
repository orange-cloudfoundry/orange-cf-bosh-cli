FROM ubuntu:22.04 AS orange_cli
USER root
ARG DEBIAN_FRONTEND=noninteractive

#--- Clis versions
ENV ARGO_VERSION="3.6.5" \
    BBR_VERSION="1.9.74" \
    BOSH_VERSION="7.9.4" \
    BOSH_COMPLETION_VERSION="1.2.0" \
    BOSH_GEN_VERSION="0.101.2" \
    CERT_MANAGER_VERSION="2.1.1" \
    CF_VERSION="8.10.0" \
    CF_UAAC_VERSION="4.28.0" \
    CILIUM_VERSION="0.16.24" \
    CNPG_VERSION="1.25.1" \
    CREDHUB_VERSION="2.9.43" \
    CROSSPLANE_CLI="1.18.2" \
    FLUX_VERSION="2.3.0" \
    FLY_VERSION="7.11.2" \
    GITLAB_VERSION="1.53.0" \
    GITHUB_VERSION="2.68.1" \
    GOSS_VERSION="0.4.9" \
    GOVC_VERSION="0.49.0" \
    HELM_VERSION="3.17.1" \
    HUBBLE_VERSION="1.17.1" \
    JQ_VERSION="1.7.1" \
    JWT_VERSION="6.2.0" \
    KCTRL_VERSION="0.55.1" \
    KLBD_VERSION="0.45.0" \
    KREW_VERSION="0.4.4" \
    KUBECTL_VERSION="1.30.8" \
    KUBECTL_WHOAMI_VERSION="0.0.46" \
    KUBENS_VERSION="0.9.5" \
    KUBESWITCH_VERSION="0.9.3" \
    KYVERNO_VERSION="1.9.5" \
    K9S_VERSION="0.40.10" \
    MONGO_BOSH_VERSION="4.0.25" \
    MONGO_SHELL_VERSION="2.4.2" \
    MYSQL_SHELL_VERSION="8.0.33-1" \
    NU_SHELL_VERSION="0.102.0" \
    OC_VERSION="4.10.25" \
    OCM_VERSION="0.1.72" \
    POPEYE_VERSION="0.22.1" \
    PROMETHEUS_VERSION="3.2.1" \
    RBAC_TOOL_VERSION="1.20.0" \
    REDIS_VERSION="6.2.4" \
    RUBY_BUNDLER_VERSION="2.3.18" \
    RUBY_VERSION="3.1.2" \
    SHIELD_VERSION="8.8.7" \
    SPRUCE_VERSION="1.31.1" \
    TASK_VERSION="3.42.1" \
    TERRAFORM_PLUGIN_CF_VERSION="0.11.2" \
    TERRAFORM_VERSION="0.11.14" \
    TFCTL_VERSION="0.15.1" \
    VAULT_VERSION="1.19.0" \
    VCLUSTER_VERSION="0.23.0" \
    VENDIR_VERSION="0.43.0" \
    YAML_PATH_VERSION="0.4" \
    YQ_VERSION="4.45.1" \
    YTT_VERSION="0.51.1"

#--- Packages list, ruby env and plugins
ENV INIT_PACKAGES="apt-transport-https ca-certificates curl openssh-server openssl sudo unzip wget" \
    TOOLS_PACKAGES="apg bash-completion colordiff gettext-base git-core gawk gnupg htop ldapscripts ldap-utils libldap-common less locales psmisc python3-tabulate s3cmd silversearcher-ag supervisor tinyproxy tmux yarnpkg vim whois" \
    NET_PACKAGES="dnsutils iproute2 iputils-ping iputils-tracepath traceroute tcptraceroute mtr-tiny netbase netcat net-tools tcpdump iperf3" \
    DEV_PACKAGES="build-essential libc6-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libpq-dev libsqlite3-dev libmysqlclient-dev zlib1g-dev libcurl4-openssl-dev" \
    RUBY_PACKAGES="g++ gcc autoconf automake bison libtool libgdbm-dev libncurses5-dev libyaml-dev pkg-config sqlite3 libgmp-dev libreadline6-dev" \
    PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}/bin:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global/bin:/usr/local/rvm/rubies/ruby-${RUBY_VERSION}/bin:${PATH}" \
    GEM_HOME="/usr/local/rvm/gems/ruby-${RUBY_VERSION}" \
    GEM_PATH="/usr/local/rvm/gems/ruby-${RUBY_VERSION}:/usr/local/rvm/gems/ruby-${RUBY_VERSION}@global" \
    CF_PLUGINS="CLI-Recorder,doctor,manifest-generator,Statistics,Targets,Usage Report" \
    KUBECTL_PLUGINS="blame,cnpg,ctx,foreach,gadget,get-all,lineage,ns,kuttl,who-can" \
    OS_ARCH_AMD="amd64" \
    OS_ARCH_X86_64="x86_64"

COPY tools/ /tmp/tools/

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
    printf '\n=====================================================\n Setup accounts\n=====================================================\n' && \
    echo "root:$(date +%s | sha256sum | base64 | head -c 32 ; echo)" | chpasswd && \
    useradd -m -g users -G sudo,rvm -s /bin/bash bosh && echo "bosh ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/bosh && \
    echo "bosh:$(date +%s | sha256sum | base64 | head -c 32 ; echo)" | chpasswd && \
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd && \
    sed -i 's/^PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config && sed -i 's/^ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config && \
    sed -i 's/^PubkeyAuthentication .*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config && sed -i 's/^.*PasswordAuthentication yes.*/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
    sed -i 's/.*\[supervisord\].*/&\nnodaemon=true\nloglevel=debug/' /etc/supervisor/supervisord.conf && \
    sed -i 's/^#Upstream http some.*/upstream http system-internet-http-proxy.internal.paas:3128 ".openshiftapps.com"/' /etc/tinyproxy/tinyproxy.conf && sed -i 's/^ConnectPort /#ConnectPort /' /etc/tinyproxy/tinyproxy.conf && \
    mkdir -p /var/run/sshd /var/log/supervisor /data/shared /home/bosh/.ssh && chmod 700 /home/bosh /home/bosh/.ssh && \
    printf '\n=====================================================\n Install clis and tools\n=====================================================\n' && \
    installBinary() { printf "\n=> Add $1 CLI\n" ; curl -sSLo /usr/local/bin/$2 "$3" ; } && \
    installGz() { printf "\n=> Add $1 CLI\n" ; curl -sSL "$3" | gunzip > /usr/local/bin/$2 ; } && \
    installTar() { printf "\n=> Add $1 CLI\n" ; curl -sSL "$3" | tar -x -C /tmp && mv /tmp/$4 /usr/local/bin/$2 ; } && \
    installTargz() { printf "\n=> Add $1 CLI\n" ; curl -sSL "$3" | tar -xz -C /tmp && mv /tmp/$4 /usr/local/bin/$2 ; } && \
    installZip() { printf "\n=> Add $1 CLI\n" ; curl -sSLo "/tmp/$(basename $3)" "$3" ; unzip -o /tmp/$(basename $3) -d /tmp ; mv /tmp/$2 /usr/local/bin/$2 ; chmod 755 /usr/local/bin/$2 ; } && \
    addCompletion() { printf "\n=> Add $1 CLI completion\n" ; chmod 755 /usr/local/bin/$2 ; /usr/local/bin/$2 $3 > /etc/bash_completion.d/$2 | true ; } && \
    installGz     "ARGO" "argo" "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-${OS_ARCH_AMD}.gz" && \
    addCompletion "ARGO" "argo" "completion bash" && \
    installTar    "BBR" "bbr" "https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v${BBR_VERSION}/bbr-${BBR_VERSION}.tar" "releases/bbr" && \
    installBinary "BOSH" "bosh" "https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_VERSION}/bosh-cli-${BOSH_VERSION}-linux-${OS_ARCH_AMD}" && \
    printf '\n=> Add BOSH CLI completion\n' && curl -sSLo /home/bosh/bosh-complete-linux "https://github.com/thomasmmitchell/bosh-complete/releases/download/v${BOSH_COMPLETION_VERSION}/bosh-complete-linux" && chmod 755 /home/bosh/bosh-complete-linux && \
    installBinary "CERT-MANAGER" "cmctl" "https://github.com/cert-manager/cmctl/releases/download/v${CERT_MANAGER_VERSION}/cmctl_linux_${OS_ARCH_AMD}" && \
    addCompletion "CERT-MANAGER" "cmctl" "completion bash" && \
    installTargz  "CF" "cf" "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${CF_VERSION}&source=github-rel" "cf8" && \
    printf '\n=> Add CF CLI completion\n' && curl -sSLo /etc/bash_completion.d/cf "https://raw.githubusercontent.com/cloudfoundry/cli-ci/master/ci/installers/completion/cf8" && \
    printf '\n=> Add CF-PLUGINS\n' && su -l bosh -s /bin/bash -c "export IFS=, ; for plugin in \$(echo \"${CF_PLUGINS}\") ; do cf install-plugin \"\${plugin}\" -r CF-Community -f ; done" && \
    printf '\n=> Add CMDB-CLI-FUNCTIONS\n' && git clone --depth 1 https://github.com/orange-cloudfoundry/cf-cli-cmdb-scripts.git /tmp/cf-cli-cmdb-scripts && mv /tmp/cf-cli-cmdb-scripts/cf-cli-cmdb-functions.bash /usr/local/bin/cf-cli-cmdb-functions.bash && \
    installTargz  "CILIUM" "cilium" "https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_VERSION}/cilium-linux-${OS_ARCH_AMD}.tar.gz" "cilium" && \
    addCompletion "CILIUM" "cilium" "completion bash" && \
    installTargz  "CNPG" "cnpg" "https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v${CNPG_VERSION}/kubectl-cnpg_${CNPG_VERSION}_linux_${OS_ARCH_X86_64}.tar.gz" "kubectl-cnpg" && \
    addCompletion "CNPG" "cnpg" "completion bash" && \
    installTargz  "CREDHUB" "credhub" "https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/${CREDHUB_VERSION}/credhub-linux-${OS_ARCH_AMD}-${CREDHUB_VERSION}.tgz" "credhub" && \
    installBinary "CROSSPLANE" "crossplane" "https://releases.crossplane.io/stable/v${CROSSPLANE_CLI}/bin/linux_${OS_ARCH_AMD}/crank" && \
    installTargz  "FLUX" "flux" "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${OS_ARCH_AMD}.tar.gz" "flux" && \
    addCompletion "FLUX" "flux" "completion bash" && \
    installTargz  "FLY" "fly" "https://github.com/concourse/concourse/releases/download/v${FLY_VERSION}/fly-${FLY_VERSION}-linux-${OS_ARCH_AMD}.tgz" "fly" && \
    printf '\n=> Add GCLOUD CLI\n' && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list && chmod 1777 /tmp && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && apt-get update && apt-get install -y --no-install-recommends google-cloud-cli && \
    installBinary "GIT-FILTER-REPO" "git-filter-repo" "https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo" && \
    printf '\n=> Add GITLAB CLI\n' && curl -sSLo /tmp/glab_${GITLAB_VERSION}_Linux_${OS_ARCH_X86_64}.deb "https://gitlab.com/gitlab-org/cli/-/releases/v${GITLAB_VERSION}/downloads/glab_${GITLAB_VERSION}_linux_${OS_ARCH_AMD}.deb" && dpkg -i /tmp/glab_${GITLAB_VERSION}_Linux_${OS_ARCH_X86_64}.deb && \
    printf "\n=> Add GITLAB CLI completion\n" ; /usr/bin/glab completion bash > /etc/bash_completion.d/glab && \
    installTargz  "GITHUB CLI" "gh" "https://github.com/cli/cli/releases/download/v${GITHUB_VERSION}/gh_${GITHUB_VERSION}_linux_${OS_ARCH_AMD}.tar.gz" "gh_${GITHUB_VERSION}_linux_${OS_ARCH_AMD}/bin/gh" && \
    addCompletion "GITHUB CLI" "gh" "completion bash" && \
    installBinary "GOSS" "goss" "https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-${OS_ARCH_AMD}" && \
    installBinary "KGOSS" "kgoss" "https://raw.githubusercontent.com/orange-cloudfoundry/goss/kgoss-kubectl-opts/extras/kgoss/kgoss" && \
    installTargz  "GOVC" "govc" "https://github.com/vmware/govmomi/releases/download/v${GOVC_VERSION}/govc_Linux_${OS_ARCH_X86_64}.tar.gz" "govc" && \
    installTargz  "HELM" "helm" "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${OS_ARCH_AMD}.tar.gz" "linux-${OS_ARCH_AMD}/helm" && \
    addCompletion "HELM" "helm" "completion bash" && \
    installTargz  "HUBBLE" "hubble" "https://github.com/cilium/hubble/releases/download/v${HUBBLE_VERSION}/hubble-linux-${OS_ARCH_AMD}.tar.gz" "hubble" && \
    addCompletion "HUBBLE" "hubble" "completion bash" && \
    installBinary "JQ" "jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" && \
    installTargz  "JWT" "jwt" "https://github.com/mike-engel/jwt-cli/releases/download/${JWT_VERSION}/jwt-linux.tar.gz" "jwt" && \
    installBinary "KCTRL" "kctrl" "https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v${KCTRL_VERSION}/kctrl-linux-${OS_ARCH_AMD}" && \
    addCompletion "KCTRL" "kctrl" "completion bash" && \
    installBinary "KLBD" "klbd" "https://github.com/k14s/kbld/releases/download/v${KLBD_VERSION}/kbld-linux-${OS_ARCH_AMD}" && \
    installBinary "KUBECTL" "kubectl" "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${OS_ARCH_AMD}/kubectl" && \
    addCompletion "KUBECTL" "kubectl" "completion bash" && sed -i "s+__start_kubectl kubectl+__start_kubectl kubectl k+g" /etc/bash_completion.d/kubectl && \
    printf '\n=> Add KUBECTL-PLUGINS\n' && curl -sSL "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/krew-linux_${OS_ARCH_AMD}.tar.gz" | tar -xz -C /tmp && chmod 1777 /tmp && su -l bosh -s /bin/bash -c "export KREW_ROOT=/home/bosh/.krew ; export PATH=/home/bosh/.krew/bin:${PATH} ; /tmp/krew-linux_${OS_ARCH_AMD} install krew ; export IFS=, ; for plugin in \$(echo \"${KUBECTL_PLUGINS}\") ; do kubectl krew install \${plugin} ; done" && \
    installTargz  "KUBECTL-WHOAMI" "kubectl-whoami" "https://github.com/rajatjindal/kubectl-whoami/releases/download/v${KUBECTL_WHOAMI_VERSION}/kubectl-whoami_v${KUBECTL_WHOAMI_VERSION}_linux_${OS_ARCH_AMD}.tar.gz" "kubectl-whoami" && \
    installBinary "KUBECTX" "switcher" "https://github.com/danielfoehrKn/kubeswitch/releases/download/${KUBESWITCH_VERSION}/switcher_linux_${OS_ARCH_AMD}" && \
    addCompletion "KUBECTX" "switcher" "completion bash" && \
    installTargz  "KUBENS" "kubens" "https://github.com/ahmetb/kubectx/releases/download/v${KUBENS_VERSION}/kubens_v${KUBENS_VERSION}_linux_${OS_ARCH_X86_64}.tar.gz" "kubens" && \
    installTargz  "KYVERNO" "kyverno" "https://github.com/kyverno/kyverno/releases/download/v${KYVERNO_VERSION}/kyverno-cli_v${KYVERNO_VERSION}_linux_${OS_ARCH_X86_64}.tar.gz" "kyverno" && \
    addCompletion "KYVERNO" "kyverno" "completion bash" && \
    installTargz  "K9S" "k9s" "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${OS_ARCH_AMD}.tar.gz" "k9s" && \
    installBinary "MINIO" "mc" "https://dl.minio.io/client/mc/release/linux-${OS_ARCH_AMD}/mc" && \
    installTargz  "MONGO-BOSH" "mongo" "https://fastdl.mongodb.org/linux/mongodb-linux-${OS_ARCH_X86_64}-${MONGO_BOSH_VERSION}.tgz" "mongodb-linux-${OS_ARCH_X86_64}-${MONGO_BOSH_VERSION}/bin/mongo" && cd /tmp/mongodb-linux-${OS_ARCH_X86_64}-${MONGO_BOSH_VERSION}/bin && mv mongostat /usr/local/bin && mv mongotop /usr/local/bin && \
    installTargz  "MONGO-SHELL" "mongosh" "https://github.com/mongodb-js/mongosh/releases/download/v${MONGO_SHELL_VERSION}/mongosh-${MONGO_SHELL_VERSION}-linux-x64.tgz" "mongosh-${MONGO_SHELL_VERSION}-linux-x64/bin/mongosh" && \
    printf '\n=> Add MYSQL-SHELL CLI\n' && curl -sSLo /tmp/mysql-shell.deb "https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell_${MYSQL_SHELL_VERSION}ubuntu22.04_${OS_ARCH_AMD}.deb" && dpkg -i /tmp/mysql-shell.deb && \
    installTargz  "NU-SHELL" "nu" "https://github.com/nushell/nushell/releases/download/${NU_SHELL_VERSION}/nu-${NU_SHELL_VERSION}-${OS_ARCH_X86_64}-unknown-linux-gnu.tar.gz" "nu-${NU_SHELL_VERSION}-${OS_ARCH_X86_64}-unknown-linux-gnu/nu" && \
    installTargz  "OC" "oc" "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz" "oc" && \
    addCompletion "OC" "oc" "completion bash" && \
    installBinary "OCM" "ocm" "https://github.com/openshift-online/ocm-cli/releases/download/v${OCM_VERSION}/ocm-linux-${OS_ARCH_AMD}" && \
    addCompletion "OCM" "ocm" "completion bash" && \
    installTargz  "POPEYE" "popeye" "https://github.com/derailed/popeye/releases/download/v${POPEYE_VERSION}/popeye_Linux_${OS_ARCH_AMD}.tar.gz" "popeye" && \
    addCompletion "POPEYE" "popeye" "completion bash" && \
    installTargz  "RBAC-TOOL" "rbac-tool" "https://github.com/alcideio/rbac-tool/releases/download/v${RBAC_TOOL_VERSION}/rbac-tool_v${RBAC_TOOL_VERSION}_linux_${OS_ARCH_AMD}.tar.gz" "rbac-tool" && \
    addCompletion "RBAC-TOOL" "rbac-tool" "bash-completion" && \
    printf '\n=> Add REDIS CLI\n' && curl -sSL "https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz" | tar -xz -C /tmp && cd /tmp/redis-${REDIS_VERSION} && make > /dev/null 2>&1 && mv /tmp/redis-${REDIS_VERSION}/src/redis-cli /usr/local/bin/redis && chmod 755 /usr/local/bin/redis && \
    installBinary "SHIELD" "shield" "https://github.com/shieldproject/shield/releases/download/v${SHIELD_VERSION}/shield-linux-${OS_ARCH_AMD}" && \
    installBinary "SPRUCE" "spruce" "https://github.com/geofffranks/spruce/releases/download/v${SPRUCE_VERSION}/spruce-linux-${OS_ARCH_AMD}" && \
    installTargz  "TASK" "task" "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${OS_ARCH_AMD}.tar.gz" "task" && \
    addCompletion "TASK" "task" "completion bash" && \
    installZip    "TERRAFORM" "terraform" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${OS_ARCH_AMD}.zip" && \
    printf '\n=> Add TERRAFORM-CF-PROVIDER\n' && wget -nv https://raw.github.com/orange-cloudfoundry/terraform-provider-cloudfoundry/master/bin/install.sh -O /tmp/install.sh && chmod 755 /tmp/install.sh /usr/local/bin/terraform && export PROVIDER_CLOUDFOUNDRY_VERSION="v${TERRAFORM_PLUGIN_CF_VERSION}" && /tmp/install.sh && \
    installTargz  "TFCTL" "tfctl" "https://github.com/weaveworks/tf-controller/releases/download/v${TFCTL_VERSION}/tfctl_Linux_${OS_ARCH_AMD}.tar.gz" "tfctl" && \
    installZip    "VAULT" "vault" "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${OS_ARCH_AMD}.zip" && \
    printf '\n=> Add VAULT CLI completion\n' && /usr/local/bin/vault -autocomplete-install && \
    installBinary "VCLUSTER" "vcluster" "https://github.com/loft-sh/vcluster/releases/download/v${VCLUSTER_VERSION}/vcluster-linux-${OS_ARCH_AMD}" && \
    addCompletion "VCLUSTER" "vcluster" "completion bash" && \
    installBinary "VENDIR" "vendir" "https://github.com/vmware-tanzu/carvel-vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-${OS_ARCH_AMD}" && \
    installTargz  "YAML-PATH" "yaml-path" "https://github.com/psycofdj/yaml-path/releases/download/v${YAML_PATH_VERSION}/yaml-path-${YAML_PATH_VERSION}.linux-${OS_ARCH_AMD}.tar.gz" "yaml-path-${YAML_PATH_VERSION}.linux-${OS_ARCH_AMD}/yaml-path" && \
    installBinary "YQ" "yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${OS_ARCH_AMD}" && \
    addCompletion "YQ" "yq" "shell-completion bash" && \
    installBinary "YTT" "ytt" "https://github.com/k14s/ytt/releases/download/v${YTT_VERSION}/ytt-linux-${OS_ARCH_AMD}" && \
    addCompletion "YTT" "ytt" "completion bash" && \
    printf '\n=> Add XDG-TOOL\n' && printf '#!/bin/bash\necho "Simulating browser invocation from xdg-open call with params: $@"\nsleep 1\nexit 0\n' > /usr/bin/xdg-open && chmod 755 /usr/bin/xdg-open && \
    printf '\n=====================================================\n Configure user account\n=====================================================\n' && \
    mv /tmp/tools/profiles/motd /etc/motd && chmod 644 /etc/motd && rm -f /etc/update-motd.d/60-unminimize && \
    mv /tmp/tools/profiles/profile /home/bosh/.profile && chmod 664 /home/bosh/.profile && mv /tmp/tools/profiles/bash_profile /home/bosh/bash_profile && \
    mv /tmp/tools/profiles/bash_aliases /home/bosh/.bash_aliases && mv /tmp/tools/profiles/sshd.conf /etc/supervisor/conf.d/ && \
    mkdir -p /home/bosh/.k9s/skins && mv /tmp/tools/k9s/skin.yaml /home/bosh/.k9s/skins/skin.yaml && mv /tmp/tools/k9s/*.yaml /home/bosh/.k9s/ && \
    mv /tmp/tools/completion/* /etc/bash_completion.d/ && chmod 755 /etc/bash_completion.d/* && mv /tmp/tools/scripts/*.sh /usr/local/bin/ && \
    printf '\n=====================================================\n Cleanup image\n=====================================================\n' && \
    apt-get autoremove -y && apt-get clean && apt-get purge && rm -fr /var/lib/apt/lists/* && \
    chmod 1777 /tmp && chmod 755 /usr/local/bin/* /etc/profile.d/* && \
    rm -fr /tmp/* /var/tmp/* && find /var/log -type f -delete && rm -f /usr/local/bin/*.md /usr/local/bin/LICENSE && \
    find /usr/local/bin -print0 | xargs -0 chown root:root && find /home/bosh /data -print0 | xargs -0 chown bosh:users && \
    touch /var/log/lastlog && chmod 664 /var/log/lastlog && chgrp utmp /var/log/lastlog

#--- Run supervisord daemon
CMD /usr/local/bin/supervisord.sh
EXPOSE 22

#--- Check clis/tools availability
FROM orange_cli AS tests
RUN /usr/local/bin/check-available-clis.sh

#--- Export image
FROM orange_cli