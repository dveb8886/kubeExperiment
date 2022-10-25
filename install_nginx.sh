#!/bin/bash

usage() { echo "Usage: $0 [-c <helm_command>] [-b <ingress-repo-branch>]" 1>&2; exit 1; }

while getopts c:b: flag
do
  case "${flag}" in
    c)  helm_cmd=${OPTARG};;
    b)  branch=${OPTARG};;
    *)
      usage
      exit ;;
  esac
done

STARTING_DIR=$(pwd)
PRJ_DIR=${0%/*}
HELM_CMD=${helm_cmd:-nothing}


if kubectl config view | grep -q "clusters: null"; then
  echo "kubectl is not connected to a cluster, this is required to proceed."
  exit
fi

# we handle minikube differently
if kubectl config current-context | grep -q "minikube"; then
  minikube addons enable ingress
  echo "Using minikube ingress addon, you will need to run minikube tunnel in a separate shell to access"
  exit
fi

# https://docs.nginx.com/nginx-ingress-controller/technical-specifications/
# k versions offset by 1 due to "less than" logic
k_versions=(v1.26 v1.25 v1.24 v1.23 v1.22 v1.21 v1.20 v1.19 v1.18)
n_versions=( 2.4   2.3   2.2   2.1   1.12  1.11  1.10  1.9   1.8 )

KUBE_VERSION=$(kubectl version --short | grep "Server Version" | awk '{print $3}')
INGRESS_DEFAULT_BRANCH=release-2.4

for i in "${!k_versions[@]}"; do
  if [ "$(printf '%s\n' "${k_versions[$i]}" "$KUBE_VERSION" | sort -V | head -n1)" = "$KUBE_VERSION" ]; then
    INGRESS_DEFAULT_BRANCH=release-${n_versions[$i]}
  fi
done

INGRESS_BRANCH=${branch:-$INGRESS_DEFAULT_BRANCH}
HELM_PATH="repos/kube-ingress/$INGRESS_BRANCH"

echo "kube is version $KUBE_VERSION, default branch of ingress repo is $INGRESS_DEFAULT_BRANCH, using $INGRESS_BRANCH"

cd $PRJ_DIR || exit
if [ ! -d "$HELM_PATH" ]; then
  git clone https://github.com/nginxinc/kubernetes-ingress.git --single-branch --branch $INGRESS_BRANCH $HELM_PATH
else
  cd $HELM_PATH || exit
  git pull
fi
cd $STARTING_DIR || exit


if [[ "$HELM_CMD" == "nothing" ]]; then
  exit
fi
if [[ "$HELM_CMD" == "uninstall" ]]; then
  helm $HELM_CMD nic \
    -n ${KUBE_NAMESPACE:-default}
else
  helm $HELM_CMD nic \
    $PRJ_DIR/$HELM_PATH/deployments/helm-chart \
    -f $PRJ_DIR/helm/ingress-nginx/environments/prd/values.yaml \
    -n ${KUBE_NAMESPACE:-default}
fi

