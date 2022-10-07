STARTING_DIR=$(pwd)
PRJ_DIR=${0%/*}
HELM_CMD=${1:-install}
HELM_BRANCH=${2:-release-1.12}

if kubectl config view | grep -q "clusters: null"; then
  echo "kubectl is not connected to a cluster, this is required to proceed."
  exit
fi

cd ${PRJ_DIR} || exit
if [ ! -d "kube-ingress" ]; then
  git clone https://github.com/nginxinc/kubernetes-ingress.git --single-branch --branch ${HELM_BRANCH} kube-ingress
else
  cd kube-ingress || exit
  git pull
  cd ../
fi
cd ${STARTING_DIR} || exit

if [[ "${HELM_CMD}" == "uninstall" ]]; then
  helm ${HELM_CMD} nic
else
  helm ${HELM_CMD} --values ${PRJ_DIR}/helm/ingress-nginx/values.yaml nic ${PRJ_DIR}/kube-ingress/deployments/helm-chart
fi

