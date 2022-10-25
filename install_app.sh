#!/bin/bash

usage() { echo "Usage: $0 [-c <helm_command>] [-e <helm_env>] [-t <tag>]" 1>&2; exit 1; }

while getopts c:e:t: flag
do
  case "${flag}" in
    c)  helm_cmd=${OPTARG};;
    e)  helm_env=${OPTARG};;
    t)  tag=${OPTARG};;
    *)
      usage
      exit ;;
  esac
done

PRJ_DIR=${0%/*}
HELM_CMD=${helm_cmd:-nothing}
HELM_ENV=${helm_env:-prd}
TAG=${tag:-0.0.1}

if kubectl config view | grep -q "clusters: null"; then
  echo "kubectl is not connected to a cluster, this is required to proceed."
  exit
fi

# we handle minikube differently
if kubectl config current-context | grep -q "minikube"; then
  echo "Minikube detected, setting environment accordingly"
  HELM_ENV=minikube
fi

HELM_PATH="helm/kubex"
HELM_RELEASE="k${HELM_ENV:0:1}"

if [[ "$HELM_CMD" == "nothing" ]]; then
  exit
fi
if [[ "$HELM_CMD" == "uninstall" ]]; then
  helm $HELM_CMD $HELM_RELEASE \
    -n ${KUBE_NAMESPACE:-default}
else
  helm $HELM_CMD $HELM_RELEASE \
    $PRJ_DIR/$HELM_PATH \
    -f $PRJ_DIR/helm/kubex/environments/$HELM_ENV/values.yaml \
    -n ${KUBE_NAMESPACE:-default} \
    --set image.tag=$TAG
fi

