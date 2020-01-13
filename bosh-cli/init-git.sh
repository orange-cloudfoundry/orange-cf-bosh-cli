#!/bin/bash
#===========================================================================
# Init git cli configuration
#===========================================================================

configureGit() {
  flag=$(echo "${GIT_OPTIONS}" | grep " $1 ")
  if [ "${flag}" = "" ] ; then
    printf "\n%b- Set \"$1\" propertie...%b" "${YELLOW}" "${STD}"
    git config --global $1 "$2"
  fi
}

#--- List options
printf "\n%bSet git configuration%b\n" "${REVERSE}${YELLOW}" "${STD}"
GIT_OPTIONS=$(git config --name-only -l | sed -e "s+^+ +g" | sed -e "s+$+ +g")

#--- Config git options
configureGit "user.name" "$(hostname)"
configureGit "user.email" "$(hostname)@orange.com"

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

configureGit "grep.linenumber" "true"

configureGit "push.default" "tracking"

#--- Display configurations
printf "\n\n%bGit configuration%b\n" "${REVERSE}${YELLOW}" "${STD}"
git config -l