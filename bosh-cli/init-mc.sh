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
  value=$(credhub g -n $1 | grep 'value:' | awk '{print $2}')
  if [ $? = 0 ] ; then
    echo "${value}"
  else
    display "ERROR" "Propertie \"$1\" unknown in \"credhub\""
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

echo "$#"
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
PROMETHEUS_CREDENTIAL_FILE=~/bosh/secrets/master-depls/prometheus/secrets/secrets.yml
if [ ! -s $1 ] ; then
  display "ERROR" "File \"${PROMETHEUS_CREDENTIAL_FILE}\" unavailable"
fi

#--- Log to credhub
log-credhub.sh

#--- Delete unused mc aliases
display "INFO"  "Remove unused aliases..."
mc config host rm gcs
mc config host rm play
mc config host rm s3

#--- Add host config for minio-S3
s3_endpoint="http://private-s3.internal.paas:9000"
s3_access_key="private-s3"
s3_secret_key="$(getCredhubValue "/micro-bosh/minio-private-s3/s3_secretkey")"
configureHost "minio" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}"

#--- Add host config for minio-prometheus
s3_endpoint="http://$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_endpoint)"
s3_access_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_access_key)"
s3_secret_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_secret_key)"
configureHost "minio-prometheus" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}"

#--- Add host config for minio-shield (only vsphere)
iaas_type="$(getCredhubValue "/secrets/iaas_type")"
if [ "${iaas_type}" = "vsphere" ] ; then
  s3_endpoint="http://storage.orange.com"
  s3_access_key="private-s3"
  s3_secret_key="$(getCredhubValue "/secrets/shield_s3_secret_access_key")"
  configureHost "minio-shield" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}"
fi

#--- Add host config for obos
s3_endpoint="https://storage.orange.com"
s3_access_key="$(getCredhubValue "/secrets/shield_obos_access_key_id")"
s3_secret_key="$(getCredhubValue "/secrets/shield_obos_secret_access_key")"
configureHost "obos" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v2"

#--- Display configurations
display "INFO"  "mc configuration..."
mc config host ls