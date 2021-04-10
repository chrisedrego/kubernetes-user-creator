# Kubernetes User Creator
An easy use to script to user along with kubeconfig.
```
**Problem Goal**
As we already know that the problem goals is that Kubernetes by default doesnt have any object type User to create user.
```
- This script allows to create a service account (which represents a user) which is then binded to any three of the Clusters Role (View/Edit/Admin) using Cluster Role Binding.


## Cluster Roles

### List of Cluster Verb
```
- get
- list
- create
- update
- patch
- watch
- delete
- deletecollection
```


# Usage

There are three standards Cluster Role created under the cluster-roles folder 

1. view ( View/Read Only Access )
2. edit ( View/Read Only + Update/Edit Access )
3. admin ( Admin/Full Access )

```
# This will create a user with view/read-only access
./script.sh <USER_NAME> <view> 
```

Once the user is created, the kubeconfig file is created under folder named along with the username.
Test the access for the user using the kubeconfig


```
PATH="./kubeconfig/<USER_NAME>/config"
kubectl config --kubeconfig=$PATH get pods
```