#!/bin/bash
#===========================================================================
# Run k9s with custom configuration
#===========================================================================

#--- Get k9s parameters
if [ $# = 0 ] ; then
  #--- Default is read-only run mode (managed by "kube-mode")
  K9S_PARAMS="${K9S_RUN_MODE}"
else
  check_parameters="$(echo "$@" | grep -E "completion|help|info|version")"
  if [ "${check_parameters}" = "" ] ; then
    K9S_PARAMS="$@ ${K9S_RUN_MODE}"
  else
    K9S_PARAMS="$@"
  fi
fi

#--- Delete obsolete configuration files (yaml files replace yml in k9s breaking changes)
find ${K9S_CONFIG_DIR} -type f -wholename "*.yml" -exec rm -f {} \; > /dev/null 2>&1

#--- Delete obsolete logs
rm ${K9S_LOGS_DIR}/k9s* > /dev/null 2>&1

#--- k9s config file
K9S_CONFIG_FILE="${K9S_CONFIG_DIR}/config.yaml"

#--- Check if new k9s version
K9S_VERSION="$(/usr/local/bin/k9s version | grep "Version:" | awk '{print $2}')"
if [ ! -f ${K9S_CONFIG_DIR}/k9s.${K9S_VERSION} ] ; then
  rm -f ${K9S_CONFIG_FILE} ${K9S_CONFIG_DIR}/k9s.v* > /dev/null 2>&1
  > ${K9S_CONFIG_DIR}/k9s.${K9S_VERSION}
fi

#--- Customize k9s configuration
if [ -f ${K9S_CONFIG_FILE} ] ; then
  #--- Disable K9S logo to display options
  sed -i "s+logoless:.*+logoless: true+" ${K9S_CONFIG_FILE}

  #--- Disable k9s lastrev check
  sed -i "s+skipLatestRevCheck:.*+skipLatestRevCheck: true+" ${K9S_CONFIG_FILE}

  #--- Disable k9s exit on CTRL/C
  sed -i "s+noExitOnCtrlC:.*+noExitOnCtrlC: true+" ${K9S_CONFIG_FILE}

  #--- Set k9s skin environment color
  sed -i '/skin: .*/d' ${K9S_CONFIG_FILE}
  sed -i '/ noIcons: /a\    skin: skin' ${K9S_CONFIG_FILE}
  sed -i "s+environment:.*+environment: \&environment ${K9S_SKIN_COLOR}+" ${K9S_CONFIG_DIR}/skins/skin.yaml

  #--- Enable "nodeShell" feature for every known clusters
  sed -i "s+image:.*+image: nicolaka/netshoot:v0.12+" ${K9S_CONFIG_FILE}
  clusters_config_files="$(find ${K9S_CONFIG_DIR} -name config.yaml | grep "/clusters/")"
  for cluster_config_file in ${clusters_config_files} ; do
    sed -i "s+nodeShell:.*+nodeShell: true+" ${cluster_config_file}
  done
fi

#--- Select current context to use for k9s session
current_ctx="$(kubectx -c)"
if [ "${current_ctx}" = "" ] ; then
  printf "\n%bERROR : k8s context \"${current_ctx}\" unknown.%b\n" "${RED}" "${STD}"
else
  k9s ${K9S_PARAMS}
fi
