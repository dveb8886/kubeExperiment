#!/bin/bash

usage() { echo "Usage: $0 [-c <helm_command>] [-e <helm_env>] [-b <bitnami_branch>]" 1>&2; exit 1; }

while getopts c:e:b: flag
do
  case "${flag}" in
    c)  helm_cmd=${OPTARG};;
    e)  helm_env=${OPTARG};;
    b)  branch=${OPTARG};;
    *)
      usage
      exit ;;
  esac
done

STARTING_DIR=$(pwd)
PRJ_DIR=${0%/*}
HELM_CMD=${helm_cmd:-nothing}
HELM_ENV=${helm_env:-prd}

if kubectl config view | grep -q "clusters: null"; then
  echo "kubectl is not connected to a cluster, this is required to proceed."
  exit
fi

# we handle minikube differently
if kubectl config current-context | grep -q "minikube"; then
  HELM_ENV=minikube
  echo "Using minikube settings for mysql"
fi

BITNAMI_BRANCH=${branch:-main}
HELM_PATH="repos/bitnami-charts/$BITNAMI_BRANCH"

echo "c=$HELM_CMD, e=$HELM_ENV, b=$BITNAMI_BRANCH"

echo "using branch $BITNAMI_BRANCH for bitnami repo"
echo "using env $HELM_ENV"

cd $PRJ_DIR || exit
if [ ! -d "$HELM_PATH" ]; then
  git clone git@github.com:bitnami/charts.git --single-branch --branch $BITNAMI_BRANCH $HELM_PATH
else
  cd $HELM_PATH || exit
  git config pull.rebase false
  git pull
fi
cd $STARTING_DIR || exit

HELM_RELEASE="s${HELM_ENV:0:1}"

if [[ "$HELM_CMD" == "nothing" ]]; then
  exit
fi
if [[ "$HELM_CMD" == "uninstall" ]]; then
  helm $HELM_CMD $HELM_RELEASE \
    -n ${KUBE_NAMESPACE:-default}
else
  helm dependency build $PRJ_DIR/$HELM_PATH/bitnami/mysql
  helm $HELM_CMD $HELM_RELEASE \
    $PRJ_DIR/$HELM_PATH/bitnami/mysql \
    -f $PRJ_DIR/helm/bitnami-mysql/environments/$HELM_ENV/values.yaml \
    -n ${KUBE_NAMESPACE:-default}
fi

