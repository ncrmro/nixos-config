export NAMESPACE=default
export K8S_USER="github-actions"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${K8S_USER}
  namespace: ${NAMESPACE}
EOF

cat <<EOF | kubectl apply -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: admin
  namespace: ${NAMESPACE}
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["*"]
- apiGroups: ["networking.k8s.io"]
  resources:
  - ingresses
  verbs: ["get", "list", "watch", "patch"]
EOF

cat <<EOF | kubectl apply -f -
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${K8S_USER}-admin
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ${K8S_USER}
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: admin
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
type: kubernetes.io/service-account-token
kind: Secret
metadata:
  name: ${NAMESPACE}-${K8S_USER}-token
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${K8S_USER}
EOF

TOKEN=$(kubectl --namespace ${NAMESPACE} describe secret $(kubectl -n ${NAMESPACE} get secret | (grep ${K8S_USER} || echo "$_") | awk '{print $1}') | grep token: | awk '{print $2}'\n)
CLUSTER_CA=$(kubectl --namespace ${NAMESPACE} get secret `kubectl -n ${NAMESPACE} get secret | (grep ${K8S_USER} || echo "$_") | awk '{print $1}'` -o "jsonpath={.data['ca\.crt']}")

cat <<EOF > ${NAMESPACE}-${K8S_USER}-kube-config.yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: https://my-cluster:6443
  name: cluster
contexts:
- context:
    cluster: cluster
    namespace: ${NAMESPACE}
    user: ${K8S_USER}
  name: cluster
current-context: cluster
kind: Config
preferences: {}
users:
- name: ${K8S_USER}
  user:
    token: ${TOKEN}
EOF

echo "This command should pass"
KUBECONFIG=${NAMESPACE}-${K8S_USER}-kube-config.yaml kubectl --namespace ${NAMESPACE} get pods
echo "This command should fail"
KUBECONFIG=${NAMESPACE}-${K8S_USER}-kube-config.yaml kubectl --namespace kube-system get pods