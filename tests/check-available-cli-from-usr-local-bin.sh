#!/bin/bash

echo "Running $0"

set -e
echo "Ensure expected cli are available (from /usr/local/bin)"
set -x
bbr --version
bosh --version
cf --version
cf7 --version
chardetect --version
credhub --version
fly --version
go3fr --version
helm version
jq --version
k9s version --short
kapp version
klbd --version
kubectl version --client --short
kustomize version --short
mc --version
pip --version
pip2 --version
pip2.7 --version
pynsxv --help >/dev/null
shield --version
spruce --version
svcat --help >/dev/null
tabulate --help >/dev/null
terraform --version
velero version --client-only
ytt --version
set +x

echo "Check complete"
