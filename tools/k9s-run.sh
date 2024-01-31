#!/bin/bash
#===========================================================================
# Run k9s with custom configuration
#===========================================================================

K9S_CONFIG_FILE="${K9S_CONFIG_DIR}/config.yaml"

#--- Delete obsolete logs
rm /tmp/k9s.* > /dev/null 2>&1

#--- Delete obsolete configuration files (yaml files replace yml in k9s breaking changes)
if [ -f ${K9S_CONFIG_DIR}/config.yml ] ; then
  rm -f ${K9S_CONFIG_DIR}/config.yml > /dev/null 2>&1
fi
if [ -f ${K9S_CONFIG_DIR}/plugin.yml ] ; then
  rm -f ${K9S_CONFIG_DIR}/plugin.yml > /dev/null 2>&1
fi

#--- Customize k9s configuration
if [ -f ${K9S_CONFIG_FILE} ] ; then
  #--- Change path to screenshot
  sed -i "s+screenDumpDir:.*+screenDumpDir: /tmp/bosh/k9s/screen-dumps+" ${K9S_CONFIG_FILE}

  #--- Disable K9S logo to display options
  sed -i "s+logoless:.*+logoless: true+" ${K9S_CONFIG_FILE}

  #--- Disable k9s lastrev check
  sed -i "s+skipLatestRevCheck:.*+skipLatestRevCheck: true+" ${K9S_CONFIG_FILE}

  #--- Set k9s skin environment color
  sed -i '/skin: .*/d' ${K9S_CONFIG_FILE}
  sed -i '/ noIcons: /a\    skin: skin' ${K9S_CONFIG_FILE}
  sed -i "s+environment:.*+environment: \&environment ${K9S_SKIN_COLOR}+" ${K9S_CONFIG_DIR}/skins/skin.yaml

  #--- Enable "nodeShell" feature for every known clusters
  sed -i "s+image:.*+image: nicolaka/netshoot:v0.11+" ${K9S_CONFIG_FILE}
  clusters_config_files="$(find ${K9S_CONFIG_DIR} -name config.yaml | grep "/clusters/")"
  for cluster_config_file in ${clusters_config_files} ; do
    sed -i "s+nodeShell:.*+nodeShell: true+" ${cluster_config_file}
  done
fi

#--- Run k9s binary (defaut is read-only mode)
k9s ${K9S_RUN_MODE}