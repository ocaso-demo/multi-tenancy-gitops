#!/bin/bash

# C_DIR=$(dirname ${BASH_SOURCE})
C_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
echo "This is the current directory: ${C_DIR}"

NEW_CLUSTER=$1
#GTIHUB_ORG=$2
GTIHUB_ORG="ocaso-demo"

if [ -z "${NEW_CLUSTER}" ]; then
  echo "Usage: $0 <new-cluster-name> <github-org>"
  exit 1
fi
if [ -z "${GTIHUB_ORG}" ]; then
  echo "Usage: $0 <new-cluster-name> <github-org>"
  exit 1
fi


cp -Rp $C_DIR ../$NEW_CLUSTER
# pushd $C_DIR/../$NEW_CLUSTER
cd $C_DIR/../$NEW_CLUSTER

find . -name '*.yaml' -print0 |
  while IFS= read -r -d '' File; do
    if grep -q "kind: Application\|kind: AppProject" "$File"; then
      #echo "$File"
      sed -i'.bak' -e "s#\${RHACM_CLUSTER_TEMPLATE}#${NEW_CLUSTER}#" $File
      rm "${File}.bak"
    fi
    sed -i'.bak' -e "s#rhacm-gitops#${GITHUB_ORG}#" $File
    rm "${File}.bak"
  done
rm new-cluster.sh

nl=$'\n'
# Update RHACM ArgoCD Project to allow argo to interact with the namespace for the newly created ROKS cluster
sed -i'.bak' -e 's@  destinations:@  destinations:'"\\${nl}"'  - namespace: '"${NEW_CLUSTER}\\${nl}"'    server: https://kubernetes.default.svc@g' ../../hub/4-rhacm/4-rhacm.yaml
rm "../../hub/4-rhacm/4-rhacm.yaml.bak"
# Update RHACM layer kustomization file to add the new ArgoCD Application that will take care of importing the newly created ROKS cluster
sed -i'.bak' -e 's@# RHACM Imported Clusters@# RHACM Imported Clusters'"\\${nl}"'- argocd/clusters/imported/'"${NEW_CLUSTER}.yaml"'@g' ../../hub/4-rhacm/kustomization.yaml
rm "../../hub/4-rhacm/kustomization.yaml.bak"

echo "git commit and push changes now"