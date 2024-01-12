#!/bin/bash
#===========================================================================
# Run k9s with custom configuration
#===========================================================================

K9S_CONFIG_FILE="${K9S_CONFIG_DIR}/config.yaml"

#--- Clean obsolete configuration files
if [ -f ${K9S_CONFIG_DIR}/config.yml ] ; then
  rm -f {K9S_CONFIG_DIR}/config.yml > /dev/null 2>&1
fi
if [ -f ${K9S_CONFIG_DIR}/plugin.yml ] ; then
  rm -f {K9S_CONFIG_DIR}/plugin.yml > /dev/null 2>&1
fi

#--- Customize k9s configuration
if [ -f ${K9S_CONFIG_FILE} ] ; then
  #--- Disable K9S logo to display options
  sed -i "s+logoless:.*+logoless: true+" ${K9S_CONFIG_FILE}

  #--- Change path to screenshot
  sed -i "s+screenDumpDir:.*+screenDumpDir: /tmp/bosh/k9s/screen-dumps+" ${K9S_CONFIG_FILE}

  #--- Disable k9s lastrev check
  sed -i "s+skipLatestRevCheck:.*+skipLatestRevCheck: true+" ${K9S_CONFIG_FILE}
fi

#--- Run k9s binary
k9s