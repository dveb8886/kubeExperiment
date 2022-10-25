PRJ_DIR=${0%/*}
HELM_CMD=${1:-nothing}

if kubectl config view | grep -q "clusters: null"; then
  echo "kubectl is not connected to a cluster, this is required to proceed."
  exit
fi

# we handle minikube differently
if kubectl config current-context | grep -q "minikube"; then
  echo "Minikube does not support cinder backend, quitting"
  exit
fi

HELM_PATH="helm/cinder"

if [[ "${HELM_CMD}" == "nothing" ]]; then
  exit
fi
if [[ "${HELM_CMD}" == "uninstall" ]]; then
  helm ${HELM_CMD} cinder \
    -n ${KUBE_NAMESPACE:-default}
else
  helm ${HELM_CMD} cinder \
    $PRJ_DIR/$HELM_PATH \
    -n ${KUBE_NAMESPACE:-default}
fi

