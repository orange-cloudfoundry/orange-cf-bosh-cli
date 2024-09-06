#!/bin/bash
#=====================================================================================
# Switch k8s context with "switcher" tool (allow multi-context management for k9s)
#=====================================================================================

function switch_k8s_ctx() {
  prefix="__ "
  available_contexts="$(switcher list-contexts)"
  current_context="$(switcher current-context 2>&1 | grep -vE "is not set|no such file")"
  if [ $? != 0 ] ; then
    available_contexts_display="${available_contexts}"
  else
    available_contexts_display="$(echo "${available_contexts}" | sed -e "s+^${current_context}$+%b${current_context}%b+")"
  fi

  if [ $# = 0 ] ; then
    printf "${available_contexts_display}\n" "${GREEN}" "${STD}"
  else
    case "$1" in
      "-h"|"--help") printf "USAGE:"
        printf "\n  kctx                       : list the contexts"
        printf "\n  kctx <NAME>                : switch to context <NAME>"
        printf "\n  kctx clean                 : clean cached kubeconfig files (may trouble active k9s sessions)"
        printf "\n  kctx -c, --current         : show the current context name"
        printf "\n  kctx -v, --version         : show version\n" ;;
      "-c"|"--current") printf "${current_context}\n" ;;
      "clean") switcher clean ;;
      "-v"|"--version") switcher -v ;;
      *) selected_context="$1"
        check_context="$(echo "${available_contexts}" | grep "^${selected_context}$")"
        if [ "${check_context}" = "" ] ; then
          printf "%bERROR: Context \"${selected_context}\" unknown.%b\n" "${RED}" "${STD}"
        else
          result="$(switcher set-context ${selected_context})"
          check_prefix="$(echo "${result}" | grep "^${prefix}")"
          if [ "${check_prefix}" = "" ] ; then
            printf "\n%bERROR:\n\"switcher\" returns no prefix\n${result}%b\n" "${RED}" "${STD}"
          else
            kubeconfig_path="$(echo "${result}" | sed -e "s+^${prefix}++" -e "s+,.*++")"
            export KUBECONFIG="${kubeconfig_path}"
            printf "Switched to context \"%b${selected_context}%b\"\n" "${GREEN}" "${STD}"
          fi
        fi ;;
    esac
  fi
}

function kctx() {
  switch_k8s_ctx $@
}

function kubectx() {
  switch_k8s_ctx $@
}

#--- Export function to sub-shells
export -f switch_k8s_ctx kctx kubectx