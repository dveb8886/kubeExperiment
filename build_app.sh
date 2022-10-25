#!/bin/bash

usage() { echo "Usage: $0 [-r <docker-repo>] [-t <tag>]" 1>&2; exit 1; }

while getopts r:t: flag
do
  case "${flag}" in
    r)  repo=${OPTARG};;
    t)  tag=${OPTARG};;
    *)
      usage
      exit ;;
  esac
done

STARTING_DIR=$(pwd)
PRJ_DIR=${0%/*}
TAG=${tag:-0.0.1}
DOCKER_REPO=${repo:-nimbusnexus}

#if kubectl config view | grep -q "clusters: null"; then
#  echo "kubectl is not connected to a cluster, this is required to proceed."
##  exit
#fi

# we handle minikube differently
if kubectl config current-context | grep -q "minikube"; then
  minikube addons enable registry
  eval $(minikube docker-env)
  DOCKER_REPO=localhost:5000
  echo "Minikube detected, linked docker to minikube registry"
fi

# Build Docker Image and upload it to repository
cd ${PRJ_DIR} || exit
docker build -f docker/flask/Dockerfile -t $DOCKER_REPO/kubex:$TAG .
docker push $DOCKER_REPO/kubex:$TAG
cd ${STARTING_DIR} || exit