#!/bin/bash
#===========================================================================
# Show kubernetes clusters token (for k8s portals use)
#===========================================================================

#--- Get k8s admin token
admin_token_name="$(kubectl -n kube-system get secret | grep admin | awk '{print $1}')"
if [ "${admin_token_name}" = "" ] ; then
  printf "\n%bk8s token:%b\nNo \"admin\" token available.\n\n" "${YELLOW}${REVERSE}" "${STD}"
else
  token="$(kubectl -n kube-system describe secret ${admin_token_name} | grep "token:" | sed -e "s+token: *++g")"
  printf "\n%bk8s token:%b\n${token}\n\n" "${YELLOW}${REVERSE}" "${STD}"
fi