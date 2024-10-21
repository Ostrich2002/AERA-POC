# Crossplane GCP Infra

A repository for managing Google Cloud Platform (GCP) resources using Crossplane. This repository provides configurations and setups to deploy and manage GCP infrastructure declaratively through Crossplane, enabling infrastructure as code and seamless integration with Kubernetes.

## Prerequisites
- a Kubernetes cluster with at least 2 GB of RAM
- permissions to create pods and secrets in the Kubernetes cluster
- [Helm](https://helm.sh/) version v3.2.0 or later
- a GCP account with permissions to create a storage bucket
- GCP [account keys](https://cloud.google.com/iam/docs/keys-create-delete)
- GCP [Project ID](https://support.google.com/googleapi/answer/7014113?hl=en)

## Install Crossplane
Crossplane installs into an existing Kubernetes cluster.

- Add the Crossplane Helm Chart repository:

```sh
helm repo add \
crossplane-stable https://charts.crossplane.io/stable
helm repo update
```

- Install the Crossplane components using helm install.

```sh
helm install crossplane \
crossplane-stable/crossplane \
--namespace crossplane-system \
--create-namespace
```

- Verify Crossplane installed with kubectl get pods.

```sh
kubectl get pods -n crossplane-system

NAME                                                READY   STATUS    RESTARTS   AGE
crossplane-6d44887cb-2x9sm                          1/1     Running   0          4d15h
crossplane-rbac-manager-846c7b5d46-4tthr            1/1     Running   0          4d15h
```

## Install the Providers

- Install Family GCP provider

```sh
kubectl apply -f providers/family_gcp.yaml
```

- Install Terraform provider

```sh
kubectl apply -f providers/terraform.yaml
```

- Verify the provider installed with `kubectl get providers`.

```sh
kubectl get providers

NAME                  INSTALLED   HEALTHY   PACKAGE                                              AGE
provider-family-gcp   True        True      xpkg.upbound.io/upbound/provider-family-gcp:v1.8.1   4d15h
provider-terraform    True        True      xpkg.upbound.io/upbound/provider-terraform:v0.18.0   4d15h
```

## Create a Kubernetes secret for GCP and Github
The provider requires credentials to create and manage GCP resources. Providers use a Kubernetes Secret to connect the credentials to the provider.

- First generate a Kubernetes Secret from a [Google Cloud service account JSON file](https://cloud.google.com/iam/docs/keys-create-delete) and then configure the Provider to use it.
- Save this JSON file as `gcp-credentials.json`
- Create a Kubernetes secret with the GCP credentials

```
kubectl create secret \
generic gcp-secret \
-n crossplane-system \
--from-file=creds=./gcp-credentials.json
```

- To securely propagate git credentials create a `git-credentials` secret in [[git credentials store]](https://git-scm.com/docs/git-credential-store#_storage_format) format.

```
cat .git-credentials
https://<user>:<token>@github.com

kubectl create secret generic git-credentials --from-file=.git-credentials -n crossplane-system
```

## Create provider config

- Update the `projectID` in `config/gcp-provider-config.yaml` file and create provider config for GCP.

```sh
kubectl apply -f config/gcp-provider-config.yaml
```

- Update the `projectID` in `config/terraform-provider-config.yaml` file and create provider config for Terraform.

```sh
kubectl apply -f config/terraform-provider-config.yaml
```


## Example usage

Remote TF module - https://github.com/aera-jawed/tf-gcp-infra

- Create GCP folders with Terraform Provider using Crossplane
- Create a secret to store required terraform vars

```sh
kubectl create secret \
generic gcp-folders-map \
-n crossplane-system \
--from-file=terraform.tfvars=./terraform.tfvars
```

- Update vars reference in the resource file - `resources/gcp_folders.yaml`
- Run `kubectl apply -f resources/gcp_folders.yaml`

```sh
❯ kubectl get workspaces

NAME           SYNCED   READY   AGE
test-folders   True     True   95s

```
