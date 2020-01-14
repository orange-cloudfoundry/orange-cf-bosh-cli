#!/bin/bash
#===========================================================================
# Init minio cli configuration
#===========================================================================

#--- Get a parameter in specified yaml file
getValue() {
  value=$(bosh int $1 --path $2)
  if [ $? != 0 ] ; then
    printf "\n\n%bERROR : Propertie \"$2\" unknown in \"$1\".%b\n\n" "${RED}" "${STD}" ; flagError=1
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
  if [ ${flagError} = 0 ] ; then
    alias="$1"
    endpoint="$2"
    accessKey="$3"
    secretKey="$4"
    api="-api S3$5"

    #--- Configure mc host
    printf "\n%bAdd \"${alias}\" configuration...%b\n" "${REVERSE}${YELLOW}" "${STD}"
    mc config host rm ${alias}
    echo "mc config host add ${alias} ${endpoint} ${accessKey} ${secretKey} ${api}"
    mc config host add ${alias} ${endpoint} ${accessKey} ${secretKey} ${api}
    if [ $? != 0 ] ; then
      printf "\n\n%bERROR : \"${alias}\" config failed.%b\n\n" "${RED}" "${STD}"
    fi
  fi
}

#--- Check prerequisistes
flagError=0
PROMETHEUS_CREDENTIAL_FILE=~/bosh/secrets/master-depls/prometheus/secrets/secrets.yml
if [ ! -s ${PROMETHEUS_CREDENTIAL_FILE} ] ; then
  printf "\n\n%bERROR : File \"${PROMETHEUS_CREDENTIAL_FILE}\" unavailable.%b\n\n" "${RED}" "${STD}" ; flagError=1
fi

if [ ${flagError} = 0 ] ; then
  #--- Log to credhub
  log-credhub.sh

  #--- Delete unused mc aliases
  printf "\n%bRemove unused aliases...%b\n" "${REVERSE}${YELLOW}" "${STD}"
  mc config host rm local
  mc config host rm gcs
  mc config host rm play
  mc config host rm s3

  #--- Add host config for minio-private-s3 (bosh releases / buildpacks / packages)
  s3_endpoint="http://private-s3.internal.paas:9000"
  s3_access_key="private-s3"
  getCredhubValue "s3_secret_key" "/micro-bosh/minio-private-s3/s3_secretkey"
  configureHost "minio" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v2"

  #--- Add host config for minio-prometheus (thanos metrics)
  s3_endpoint="http://$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_endpoint)"
  s3_access_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_access_key)"
  s3_secret_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_secret_key)"
  configureHost "prometheus" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v2"

  #--- Add host config for cloudfoundry minio-blobstore (cloudfoundry buildpacks)
  s3_endpoint="http://cf-datastores.internal.paas:80"
  s3_access_key="$(getValue ${PROMETHEUS_CREDENTIAL_FILE} /secrets/thanos_s3_access_key)"
  getCredhubValue "s3_access_key" "/bosh-master/cloudfoundry-datastores/cf_blobstore_s3_accesskey"
  getCredhubValue "s3_secret_key" "/bosh-master/cloudfoundry-datastores/cf_blobstore_s3_secretkey"
  configureHost "cf_blobstore" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v2"

  #--- Add host config for shield local backup
  s3_endpoint="https://shield-s3.internal.paas"
  s3_access_key="shield-s3"
  getCredhubValue "s3_secret_key" "/bosh-master/shieldv8/s3_secretkey"
  configureHost "shield_local" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v4"

  #--- Add host config for shield remote backup
  getCredhubValue "s3_endpoint" "/secrets/backup_remote_s3_host"
  s3_endpoint="https://${s3_endpoint}"
  getCredhubValue "s3_access_key" "/secrets/backup_remote_s3_access_key_id"
  getCredhubValue "s3_secret_key" "/secrets/backup_remote_s3_secret_access_key"
  configureHost "shield_remote" "${s3_endpoint}" "${s3_access_key}" "${s3_secret_key}" "v4"

  #--- Display configurations
  printf "\n%bmc configuration...%b\n" "${REVERSE}${YELLOW}" "${STD}"
  mc config host ls
fi