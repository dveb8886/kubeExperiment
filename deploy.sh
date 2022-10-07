# shellcheck disable=SC2046

PRJ_DIR=${0%/*}
target=$1
apply=""

# Determine if apply parameter was provided
if [ -z "$2" ]; then
  :
else
  if [[ "$2" == "apply" ]]; then
    apply=true
  fi
fi

# if we are base, then assume we are using minikube
if [[ -n $apply ]]; then
  if [[ $target == *base ]]; then
    eval $(minikube docker-env)
  fi
fi

# Create the aggregated configuration
# replaces ${vars} from config.ini in the final configuration
output=$(
    kubectl kustomize "${PRJ_DIR}/${target}" | \
    sed $(awk -F '=' '{print "-e s=${"$1"}="$2"=g"}' "${PRJ_DIR}/${target}/config.ini")
  )

# Push to kubectl apply if apply is selected
if [[ -n $apply ]]; then
  echo "$output" | kubectl apply -f -
else
  echo "$output"
fi


