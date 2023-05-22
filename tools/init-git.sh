#!/bin/bash
#===========================================================================
# Init git cli configuration and clone repositories
#===========================================================================

configureGit() {
  flag=$(echo "${GIT_OPTIONS}" | grep " $1 ")
  if [ "${flag}" = "" ] ; then
    printf "\n%b- Set \"$1\" propertie...%b" "${YELLOW}" "${STD}"
    git config --global $1 "$2"
  fi
}

#--- Config git options
GIT_OPTIONS=$(git config --name-only -l | sed -e "s+^+ +g" | sed -e "s+$+ +g")
USER_NAME="$(hostname | sed -e "s+\-cli.*$++")"
configureGit "user.name" "${USER_NAME}"
configureGit "user.email" "${USER_NAME}@orange.com"

configureGit "alias.co" "checkout"
configureGit "alias.br" "branch"
configureGit "alias.lol" "log --graph --decorate --pretty=oneline --abbrev-commit"
configureGit "alias.lola" "log --graph --decorate --pretty=oneline --abbrev-commit --all"
configureGit "alias.st" "status"
configureGit "alias.uncommit" "reset --soft HEAD~1"

configureGit "color.ui" "auto"

configureGit "core.editor" "vi"
configureGit "core.eol" "lf"
configureGit "core.autocrlf" "input"
configureGit "core.preloadindex" "true"

configureGit "credential.helper" "cache --timeout=86400"
configureGit "http.postbuffer" "524288000"
configureGit "http.sslverify" "false"
configureGit "grep.linenumber" "true"
configureGit "push.default" "tracking"

#--- Display configurations
printf "\n\n%bSet git configuration%b\n" "${REVERSE}${YELLOW}" "${STD}"
git config -l

#--- Log to credhub
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "\n%bLDAP user and password :%b\n" "${REVERSE}${GREEN}" "${STD}"
  printf "username: " ; read LDAP_USER
  credhub login --server=https://credhub.internal.paas:8844 -u ${LDAP_USER}
  if [ $? != 0 ] ; then
    printf "\n%bERROR : LDAP authentication failed with \"${LDAP_USER}\" account.%b\n" "${RED}" "${STD}" ; flagError=1
  fi
fi

#--- Fix clone/pull errors with ubuntu 22.04
export GNUTLS_CPUID_OVERRIDE=0x1

#--- Set git credentials cache
GIT_CREDS_DIR="${HOME}/.cache/git/credential"
if [ ! -d ${GIT_CREDS_DIR} ] ; then
  mkdir -p ${GIT_CREDS_DIR}
fi
chmod 0700 ${GIT_CREDS_DIR} > /dev/null 2>&1

#--- Clone repositories
if [ ! -d ${HOME}/bosh ] ; then
  mkdir ${HOME}/bosh > /dev/null 2>&1
fi

cd ${HOME}/bosh
unset http_proxy https_proxy no_proxy

#--- Clone secrets repo
if [ -d ${HOME}/bosh/secrets ] ; then
  printf "\n%bGit secrets repository already exists (delete it before if you want to reinitialize repository).%b\n" "${REVERSE}${YELLOW}" "${STD}"
else
  printf "\n%bClone git secrets repository%b\n" "${REVERSE}${YELLOW}" "${STD}"
  SECRETS_URL="$(credhub g -n /secrets/concourse_git_secrets_uri -j 2> /dev/null | jq -r '.value')"
  git clone ${SECRETS_URL} secrets 2>&1
  if [ ! -d secrets ] ; then
    printf "\nERROR: Git clone secrets repository failed.\n" ; exit 1
  fi
fi

#--- Clone template repo
if [ -d ${HOME}/bosh/template ] ; then
  printf "\n%bGit template repository already exists (delete it before if you want to reinitialize repository).%b\n" "${REVERSE}${YELLOW}" "${STD}"
else
  printf "\n%bClone git template repository%b\n" "${REVERSE}${YELLOW}" "${STD}"
  TEMPLATE_URL="$(credhub g -n /secrets/git_template_uri -j 2> /dev/null | jq -r '.value')"
  checkGithub="$(echo "${TEMPLATE_URL}" | grep "github")"
  if [ "${checkGithub}" != "" ] ; then
    export http_proxy="http://system-internet-http-proxy.internal.paas:3128"
    export https_proxy=${http_proxy}
    export no_proxy="127.0.0.1,localhost,169.254.0.0/16,172.17.11.0/24,192.168.0.0/16,.internal.paas,${INTRANET_DOMAINS}"
  fi

  git clone ${TEMPLATE_URL} template 2>&1
  if [ ! -d template ] ; then
    printf "\nERROR: Git clone template repository failed.\n" ; exit 1
  fi
fi

#--- Clone gitops repo
if [ -d ${HOME}/bosh/gitops ] ; then
  printf "\n%bGit ops repository already exists (delete it before if you want to reinitialize repository).%b\n" "${REVERSE}${YELLOW}" "${STD}"
else
  printf "\n%bClone gitops repository%b\n" "${REVERSE}${YELLOW}" "${STD}"
  GITOPS_URL="$(echo "${SECRETS_URL}" | sed -e "s+paas-templates-secrets+cf-ops-automation+g")"
  git clone ${GITOPS_URL} gitops 2>&1
  if [ ! -d gitops ] ; then
    printf "\nERROR: Git clone gitops repository failed.\n" ; exit 1
  fi
fi