#!/bin/bash
#===========================================================================
# Run k9s with custom configuration
#===========================================================================

K9S_CONFIG_FILE="${K9S_CONFIG_DIR}/config.yaml"

#--- Delete obsolete configuration files (yaml files replace yml)
if [ -f ${K9S_CONFIG_DIR}/config.yml ] ; then
  rm -f ${K9S_CONFIG_DIR}/config.yml > /dev/null 2>&1
fi
if [ -f ${K9S_CONFIG_DIR}/plugin.yml ] ; then
  rm -f ${K9S_CONFIG_DIR}/plugin.yml > /dev/null 2>&1
fi

#--- Customize k9s configuration
if [ -f ${K9S_CONFIG_FILE} ] ; then
  #--- Disable K9S logo to display options
  sed -i "s+logoless:.*+logoless: true+" ${K9S_CONFIG_FILE}

  #--- Change path to screenshot
  sed -i "s+screenDumpDir:.*+screenDumpDir: /tmp/bosh/k9s/screen-dumps+" ${K9S_CONFIG_FILE}

  #--- Disable k9s lastrev check
  sed -i "s+skipLatestRevCheck:.*+skipLatestRevCheck: true+" ${K9S_CONFIG_FILE}

  #--- Set k9s skin environment color
  sed -i '/skin: .*/d' ${K9S_CONFIG_FILE}
  sed -i '/ noIcons: /a\    skin: skin' ${K9S_CONFIG_FILE}
  sed -i "s+environment: .*+environment: \&environment ${K9S_SKIN_COLOR}+" ${K9S_CONFIG_DIR}/skins/skin.yaml
fi

#--- Delete obsolete logs
rm /tmp/k9s.* > /dev/null 2>&1

#--- Run k9s binary (defaut is read-only mode)
k9s ${K9S_RUN_MODE}