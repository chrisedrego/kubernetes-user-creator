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

create_config(){
    mkdir -p ./kubeconfigs/${SERVICE_ACCOUNT_NAME}
    echo -e "\nBinding Cluster Role"
    echo -e "\nCreating a New Cluster Role ${SERVICE_ACCOUNT_NAME}_${CLUSTER_ROLE} from Parent Cluster Role: ${CLUSTER_ROLE}"
    PARENT_CLUSTER_ROLE="./cluster-roles/${CLUSTER_ROLE}.yaml"
    echo $PARENT_CLUSTER_ROLE
    sed 's|NAME|'$SERVICE_ACCOUNT_NAME'|g' $PARENT_CLUSTER_ROLE > ./kubeconfigs/${SERVICE_ACCOUNT_NAME}/${SERVICE_ACCOUNT_NAME}_${CLUSTER_ROLE}_cluster-role.yaml
    kubectl apply -f ./kubeconfigs/${SERVICE_ACCOUNT_NAME}/${SERVICE_ACCOUNT_NAME}_${CLUSTER_ROLE}_cluster-role.yaml || echo "Failure"
    rm -rf ./kubeconfigs/${SERVICE_ACCOUNT_NAME}/${SERVICE_ACCOUNT_NAME}_${CLUSTER_ROLE}_cluster-role.yaml || echo "Unable to remove the cluster role."

    # Binding the Cluster Role Bindings
    kubectl create clusterrolebinding ${SERVICE_ACCOUNT_NAME} --clusterrole=${SERVICE_ACCOUNT_NAME}_${CLUSTER_ROLE} --serviceaccount=$NAMESPACE:$SERVICE_ACCOUNT_NAME -n $NAMESPACE

    KUBECFG_PATH=./kubeconfigs/$SERVICE_ACCOUNT_NAME/config-$CLUSTERNAME

    echo "apiVersion: v1" >> $KUBECFG_PATH
    echo "kind: Config" >> $KUBECFG_PATH
    echo "users:" >> $KUBECFG_PATH
    echo "- name: $SERVICE_ACCOUNT_NAME" >> $KUBECFG_PATH
    echo "  user:" >> $KUBECFG_PATH
    echo "    token: $TOKEN" >> $KUBECFG_PATH
    echo "clusters:" >> $KUBECFG_PATH
    echo "- cluster:" >> $KUBECFG_PATH
    echo "    certificate-authority-data: $CERTIFICATE" >> $KUBECFG_PATH
    echo "    server: $SERVER" >> $KUBECFG_PATH
    echo "  name: $CLUSTERNAME" >> $KUBECFG_PATH
    echo "contexts:" >> $KUBECFG_PATH
    echo "- context:" >> $KUBECFG_PATH
    echo "    cluster: $CLUSTERNAME" >> $KUBECFG_PATH
    echo "    user: $SERVICE_ACCOUNT_NAME" >> $KUBECFG_PATH
    echo "  name: $CLUSTERNAME" >> $KUBECFG_PATH
    echo "current-context: $CLUSTERNAME" >> $KUBECFG_PATH
    cat $KUBECFG_PATH
    # "apiVersion: v1
    
    # users:
    # - name: $SERVICE_ACCOUNT_NAME
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
    #     user: $SERVICE_ACCOUNT_NAME
    #   name: $CLUSTERNAME
    # current-context: $CLUSTERNAME" > 
}

if [ -z "$1" ] && [ -z "$2" ] 
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
  create_config
fi