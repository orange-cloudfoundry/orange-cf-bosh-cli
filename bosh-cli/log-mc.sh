#!/bin/bash
#===========================================================================
# Log with mc (S3) cli
#===========================================================================

#--- Colors and styles
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export GREEN='\033[1;32m'
export STD='\033[0m'
export BOLD='\033[1m'
export REVERSE='\033[7m'

#--- Get a propertie value in credhub
getCredhubValue() {
  value=$(credhub g -n $1 | grep 'value: ' | awk '{print $2}')
  if [ $? = 0 ] ; then
    echo "${value}"
  else
    printf "\n\n%bERROR : \"$2\" credhub value unknown.%b\n\n" "${RED}" "${STD}"
    flagError=1
  fi
}

#--- Log to credhub
flagError=0
flag=$(credhub f > /dev/null 2>&1)
if [ $? != 0 ] ; then
  printf "%bEnter LDAP user and password :%b\n" "${REVERSE}${YELLOW}" "${STD}"
  credhub api --server=https://credhub.internal.paas:8844 > /dev/null 2>&1
  credhub login
  if [ $? != 0 ] ; then
    printf "\n%bERROR : Bad LDAP authentication.%b\n\n" "${RED}" "${STD}"
    flagError=1
  fi
fi

#--- Log to S3
if [ "${flagError}" = "0" ] ; then
  S3_SECRET_KEY="$(getCredhubValue "/micro-bosh/minio-private-s3/s3_secretkey")"
  if [ ${flagError} = 0 ] ; then
    mc config host add minio http://private-s3.internal.paas:9000 private-s3 ${S3_SECRET_KEY} > /dev/null 2>&1
    if [ $? = 1 ] ; then
      printf "\n%bERROR : Connexion failed.%b\n\n" "${RED}" "${STD}"
    fi
  fi
fi
printf "\n"