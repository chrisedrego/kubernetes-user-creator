#!/bin/sh
echo "Kubernetes User Creator"

SERVICE_ACCOUNT_NAME=$1
CLUSTER_ROLE=$2
NAMESPACE='default'

create_service_account() {
    echo -e "\n Creating a service account in ${NAMESPACE} namespace: ${SERVICE_ACCOUNT_NAME}"
    kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}" -o yaml 
}

get_token_name() {
    echo -e "\n Get token name for ${SERVICE_ACCOUNT_NAME}"
    TOKENNAME=`kubectl -n ${NAMESPACE} get serviceaccount/${SERVICE_ACCOUNT_NAME} -o jsonpath='{.secrets[0].name}'`
    echo -e "\n Token Name: ${TOKENNAME}"
}

get_token() {
    echo -e "\\Getting token ${TOKENNAME}"
    TOKEN=`kubectl -n ${NAMESPACE} get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode`
    echo "Token: ${TOKEN}"
}

get_cluster_name(){
    echo -e "\nGetting Cluster Name"
    CLUSTERNAME=`kubectl config view --flatten --minify=true -o jsonpath='{.clusters[0].name}'`
    echo -e "\n Cluster Name: ${CLUSTERNAME}"
}

get_cert(){
    echo -e "\nGetting Cluster Certificate Details"
    CERTIFICATE=`kubectl config view --flatten --minify=true -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'`
    echo -e "\n Certificate: ${CERTIFICATE}"
}

get_server(){
    echo -e "\nGetting Cluster Certificate Details"
    SERVER=`kubectl config view --flatten --minify=true -o jsonpath='{.clusters[0].cluster.server}'`
    echo -e "\n Server: ${SERVER}"
}

create_cluster_role(){
    mkdir -p ${SERVICE_ACCOUNT_NAME}
    echo -e "\nBinding Cluster Role"
    echo -e "\nCreating a New Cluster Role ${SERVICE_ACCOUNT_NAME}_${CLUSTER_ROLE} from Parent Cluster Role: ${CLUSTER_ROLE}"
    PARENT_CLUSTER_ROLE="./cluster-roles/${CLUSTER_ROLE}.yaml"
    echo $PARENT_CLUSTER_ROLE
    sed 's|NAME|'$SERVICE_ACCOUNT_NAME'|g' $PARENT_CLUSTER_ROLE > ./${SERVICE_ACCOUNT_NAME}/${SERVICE_ACCOUNT_NAME}_cluster-role.yaml
    kubectl apply -f ./${SERVICE_ACCOUNT_NAME}/${SERVICE_ACCOUNT_NAME}_cluster-role.yaml || echo "Failure"
    rm -rf ./${SERVICE_ACCOUNT_NAME}/${SERVICE_ACCOUNT_NAME}_cluster-role.yaml
}

bind_crb(){
    echo -e "\nBinding Cluster Role"
    kubectl create clusterrolebinding cluster-viewer --clusterrole='view' --serviceaccount=$NAMESPACE:$SERVICE_ACCOUNT_NAME -n $NAMESPACE
}

create_kubecfg(){
    echo -e "\nCreating Kubernetes Config File"
    kubectl create clusterrolebinding cluster-viewer --clusterrole='view' --serviceaccount=$NAMESPACE:$SERVICE_ACCOUNT_NAME -n $NAMESPACE
}


if [ -z "$SERVICE_ACCOUNT_NAME" ]
then
  echo "Please Enter valid details."
  echo "./script.sh <USER_NAME> <CLUSTER_ROLE_NAME>"
  echo 'Cluster Role:'
  echo '1. view'
  echo '2. edit'
  echo '3. admin'
  exit 0;
else
  create_service_account
  get_token_name
  get_token
  get_cluster_name
  get_cert
  get_server
  create_cluster_role
fi

mkdir -p $SERVICE_ACCOUNT_NAME

# echo "apiVersion: v1
# kind: Config
# users:
# - name: $USER
#   user:
#     token: $TOKEN
# clusters:
# - cluster:
#     certificate-authority-data: $CERTIFICATE
#     server: $SERVER
#   name: $CLUSTERNAME
# contexts:
# - context:
#     cluster: $CLUSTERNAME
#     user: $USER
#   name: $CLUSTERNAME-context
#   current-context: $CLUSTERNAME-context" > $NAME/kubeconfig_"$counter".txt

# 
# kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:kubeconfig-sa
# CREATE SERVICE ACCOUNT FROM NAME


# GET THE SECRET OF THE SERVICE ACCOUNT

# GET THE TOKEN FROM THE SECRET

# GET THE CERTIFICATE certificate-authority-data FROM KUBECONFIG FILE

# GET THE SERVER DETAILS

# PLACE IN PLACEHOLDER
# apiVersion: v1
# kind: Config
# users:
# - name: svcs-acct-dply
#   user:
#     token: <replace this with token info>
# clusters:
# - cluster:
#     certificate-authority-data: <replace this with certificate-authority-data info>
#     server: <replace this with server info>
#   name: self-hosted-cluster
# contexts:
# - context:
#     cluster: self-hosted-cluster
#     user: svcs-acct-dply
#   name: svcs-acct-context
# current-context: svcs-acct-context

# TOKENNAME=`kubectl -n kube-system get serviceaccount/test -o jsonpath='{.secrets[0].name}'`