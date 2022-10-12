#!/bin/bash

C_DIR=$(dirname ${BASH_SOURCE})
NEW_CLUSTER=$1
if [ -z "${NEW_CLUSTER}" ]; then
  echo "Usage: $0 <new-cluster-name>"
  exit 1
fi
cp -Rp $C_DIR ../$NEW_CLUSTER
pushd $C_DIR/../$NEW_CLUSTER

find . -name '*.yaml' -print0 |
  while IFS= read -r -d '' File; do
    if grep -q "kind: Application\|kind: AppProject" "$File"; then
      #echo "$File"
      sed -i'.bak' -e "s#\${RHACM_CLUSTER_TEMPLATE}#${NEW_CLUSTER}#" $File
      rm "${File}.bak"
    fi
  done
rm new-cluster.sh

nl=$'\n'
sed -i -r 's@  destinations:@  destinations:'"\\${nl}"'  - namespace: '"\\${NEW_CLUSTER}\\${nl}"'    server: https://kubernetes.default.svc@g' ../../hub/4-rhacm/4-rhacm.yaml

echo "git commit and push changes now"