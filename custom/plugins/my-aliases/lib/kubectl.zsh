alias kc="kubectl config use-context"
alias kd="kubectl describe"
alias kg="kubectl get"
alias kgp="kubectl get pods"
alias kgpw="watch 'kubectl get pods'"
alias kgpcl="kubectl get pods | grep CrashLoopBackOff"
alias kgs="kubectl get services"
alias kgn="kubectl get nodes"
alias kgm="kubectl get namespaces"
alias kl="kubectl logs -p"
alias kdp="kubectl delete pod"

function get_pod() {
    local keyword=$1
    local namespace=$2

    if [[ $keyword == "" ]]; then
        echo "No pod name provided"
        return 1
    fi

    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi

    echo $(kgp -n $namespace | grep "^$keyword" | awk '{print $1}')
}

function kgl() {
    local pod=$(get_pod $@)
    local namespace=$2

    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi

    kubectl logs $pod -n $namespace
}

function kdpa() {
    local namespace=$1

    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi

    local pod=$(kgp -n $namespace | grep "CrashLoopBackOff" | awk '{print $1}')
    kubectl delete pod $pod -n $namespace
}

function kdps() {
    local pod=$(get_pod $@)
    local namespace=$2

    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi

    kdp $pod -n $namespace
}

function kgenv() {
    local pod=$(get_pod $@)
    local namespace=$2

    echo $pod

    if [[ $namespace == "" ]]; then
        namespace="eldar"
    fi

    kubectl exec -it $pod -n $namespace -- env
}
