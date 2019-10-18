#!/bin/bash
#===========================================================================
# Init minio cli configuration
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export STD='\033[0m'
export REVERSE='\033[7m'

#--- Display information
display() {
  case "$1" in
    "INFO")  printf "\n%b%s...%b\n" "${REVERSE}${YELLOW}" "$2" "${STD}" ;;
    "ERROR") printf "\n%bERROR: %s.%b\n\n" "${REVERSE}${RED}" "$2" "${STD}" ; exit 1 ;;
  esac
}

#--- Get a parameter in specified yaml file
getValue() {
  value=$(bosh int $1 --path $2)
  if [ $? != 0 ] ; then
    display "ERROR" "Propertie \"$2\" unknown in \"$1\""
  else
    echo "${value}"
  fi
}

#--- Get a parameter in credhub
getCredhubValue() {
  value=$(credhub g -n $2 | grep 'value:' | awk '{print $2}')
  if [ "${value}" = "" ] ; then
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}" ; flagError=1
  else
    eval "$1=${value}"
  fi
}

#--- Configure host in minio cli
configureHost() {
  alias="$1"
  endpoint="$2"
  accessKey="$3"
  secretKey="$4"

  if [ "${alias}" = "" ] ; then
    display "ERROR"  "Alias \"${alias}\" unknown"
  fi
  if [ "${endpoint}" = "" ] ; then
    display "ERROR"  "Endpoint \"${endpoint}\" unknown"
  fi
  if [ "${accessKey}" = "" ] ; then
    display "ERROR"  "Acces key \"${accessKey}\" unknown"
  fi
  if [ "${secretKey}" = "" ] ; then
    display "ERROR"  "Secret key \"${secretKey}\" unknown"
  fi

  if [[ $# = 5 ]] ; then
    options="--api S3v2"
  else
    options="--api S3v4"
  fi

  #--- Configure mc host
  display "INFO"  "Add \"${alias}\" configuration..."
  mc config host rm ${alias}
  echo "mc config host add ${alias} ${endpoint} ${accessKey} ${secretKey} ${options}"
  mc config host add ${alias} ${endpoint} ${accessKey} ${secretKey} ${options}
  if [ $? != 0 ] ; then
    display "ERROR"  "\"${alias}\" minio config failed"
  fi
}

#--- Check prerequisistes
SHARED_SECRETS=~/bosh/secrets/shared/secrets.yml
if [ ! -s ${SHARED_SECRETS} ] ; then
  display "ERROR" "File \"${SHARED_SECRETS}\" unavailable"
fi

PROMETHEUS_CREDENTIAL_FILE=~/bosh/secrets/master-depls/prometheus/secrets/secrets.yml
if [ ! -s ${PROMETHEUS_CREDENTIAL_FILE} ] ; then
  display "ERROR" "File \"${PROMETHEUS_CREDENTIAL_FILE}\" unavailable"
fi

#--- Log to credhub
log-credhub.sh

#--- Delete unused mc aliases
display "INFO"  "Remove unused aliases..."
mc config host rm gcs
mc config host rm play
mc config host rm s3

#--- Add host config for minio-private-s3
s3_endpoint="http://private-s3.internal.paas:9000"
s3_access_key="private-s3"
getCredhubValue "s3_secret_key" "/micro-bosh/minio-private-s3/s3_secretkey"
configureHost "minio" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}"

#--- Add host config for minio-prometheus (thanos metrics)
s3_endpoint="http://$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_endpoint)"
s3_access_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_access_key)"
s3_secret_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_secret_key)"
configureHost "prometheus" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}"

#--- Add host config for shied backup (minio-shield for vsphere)
getCredhubValue "iaas_type" "/secrets/iaas_type"
if [ "${iaas_type}" = "vsphere" ] ; then
  s3_endpoint="http://storage.orange.com"
  s3_access_key="private-s3"
  getCredhubValue "s3_secret_key" "/secrets/shield_s3_secret_access_key"
else
  s3_endpoint="https://$(getValue ${SHARED_SECRETS} /secrets/shield/s3_host)"
  s3_access_key="$(getValue ${SHARED_SECRETS} /secrets/shield/s3_access_key_id)"
  s3_secret_key="$(getValue ${SHARED_SECRETS} /secrets/shield/s3_secret_access_key)"
fi
configureHost "shield" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}"

#--- Add host config for shield backup
s3_endpoint="https://storage.orange.com"
getCredhubValue "s3_access_key" "/secrets/shield_obos_access_key_id"
getCredhubValue "s3_secret_key" "/secrets/shield_obos_secret_access_key"
configureHost "shield_v2" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v2"

#--- Display configurations
display "INFO"  "mc configuration..."
mc config host ls