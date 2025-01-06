#!/bin/bash
#===========================================================================
# Push git commits to origin repository (check if commits count exceed 5)
#===========================================================================

#--- Synchronise remote and local reporitories
printf "\n%bSynchronize with \"origin\" repository...%b\n" "${REVERSE}${GREEN}" "${STD}"
git pull --rebase
git fetch --prune

#--- Check if commits exceed 5
git_curent_branch="$(git symbolic-ref HEAD --short 2> /dev/null)"
nb_commits_to_push=$(git rev-list origin/${git_curent_branch}..${git_curent_branch} --count)
if [ ${nb_commits_to_push} -gt 5 ] ; then
  printf "\n%bDo you really want to push ${nb_commits_to_push} commits to \"origin/${git_curent_branch}\" (y/[n]) ? :%b " "${REVERSE}${GREEN}" "${STD}"
  read choice ; printf "\n"
  if [ "${choice}" != "y" ] ; then
    exit
  fi
fi

printf "\n%bPush ${nb_commits_to_push} commits to \"origin/${git_curent_branch}\"...%b\n" "${REVERSE}${GREEN}" "${STD}"
git push