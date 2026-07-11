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
    @doc "Find a pod name by keyword prefix" "<keyword> [namespace]"
    @needs 1 "$@" || return

    local keyword=$1
    local namespace=$2

    if [[ -z "$namespace" ]]; then
        @var "KUBECTL_NAMESPACE" "$KUBECTL_NAMESPACE" || return
        namespace=$KUBECTL_NAMESPACE
    fi

    echo $(kgp -n $namespace | grep "^$keyword" | awk '{print $1}')
}

function kgl() {
    @doc "Tail logs for a pod matched by keyword" "<keyword> [namespace]"
    @needs 1 "$@" || return

    local pod=$(get_pod $@)
    local namespace=$2

    if [[ -z "$namespace" ]]; then
        @var "KUBECTL_NAMESPACE" "$KUBECTL_NAMESPACE" || return
        namespace=$KUBECTL_NAMESPACE
    fi

    kubectl logs $pod -n $namespace
}

function kdpa() {
    @doc "Delete all pods in CrashLoopBackOff state" "[namespace]"
    @needs 0 "$@" || return

    local namespace=$1

    if [[ -z "$namespace" ]]; then
        @var "KUBECTL_NAMESPACE" "$KUBECTL_NAMESPACE" || return
        namespace=$KUBECTL_NAMESPACE
    fi

    local pod=$(kgp -n $namespace | grep "CrashLoopBackOff" | awk '{print $1}')
    kubectl delete pod $pod -n $namespace
}

function kdps() {
    @doc "Delete a specific pod matched by keyword" "<keyword> [namespace]"
    @needs 1 "$@" || return

    local pod=$(get_pod $@)
    local namespace=$2

    if [[ -z "$namespace" ]]; then
        @var "KUBECTL_NAMESPACE" "$KUBECTL_NAMESPACE" || return
        namespace=$KUBECTL_NAMESPACE
    fi

    kdp $pod -n $namespace
}

function kgenv() {
    @doc "Print environment variables for a pod matched by keyword" "<keyword> [namespace]"
    @needs 1 "$@" || return

    local pod=$(get_pod $@)
    local namespace=$2

    echo $pod

    if [[ -z "$namespace" ]]; then
        @var "KUBECTL_NAMESPACE" "$KUBECTL_NAMESPACE" || return
        namespace=$KUBECTL_NAMESPACE
    fi

    kubectl exec -it $pod -n $namespace -- env
}
