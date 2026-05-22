
# RDFox Helm Chart

A Helm chart for deploying RDFox on Kubernetes.

> [!WARNING]  
> Development use only: this Helm chart is not production-ready and must not be used for production workloads.

## Prerequisites

- [Docker/Podman](https://docs.docker.com/get-started/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A Kubernetes cluster, for example AWS EKS, Azure AKS, or Minikube for local testing
- [Helm](https://helm.sh/) 3.x
- A valid RDFox license file

## Quick Start

### Create Required Secrets

Create a secret for your RDFox license file:

```sh
kubectl create secret generic rdfox-license --from-file=RDFox.lic=<PATH_TO_RDFOX_LICENSE>
```

Create a secret for the admin credentials:

```sh
kubectl create secret generic server-admin-credentials --from-literal=rolename=<YOUR_ROLENAME> --from-literal=password=<YOUR_PASSWORD>
```

### Install the Chart

To install with local defaults (for example, on Minikube), run:

```sh
helm repo add ost https://helm.oxfordsemantic.tech
helm install rdfox ost/rdfox --devel --set endpointParameters.channel=unsecure
```

Setting `endpointParameters.channel=unsecure` disables TLS. Use this only for local testing or other non-production environments. For a TLS enabled setup, see [Configure TLS](#configure-tls).

## Uninstall

To remove the deployment:

```sh
helm uninstall rdfox
```

## Deploy RDFox on a Kubernetes Cloud Provider

When running RDFox on a cloud Kubernetes provider, use the provider storage settings. The Helm chart includes example values files for `AWS EKS` and `Azure AKS`, which configure storage classes and related parameters for each provider.

To run the Helm chart with a specific storage configuration, use the `-f` flag to specify the appropriate values file. For example:

```sh
helm install rdfox ost/rdfox --devel -f storage/<storage-configuration-file-name>.yaml --set endpointParameters.channel=unsecure
```

Replace `<storage-configuration-file-name>` with the appropriate file for your storage solution, for example `aws-values.yaml` for `AWS EKS` or `aks-values.yaml` for `Azure AKS`.

## Additional Configuration

### Configure the RDFox server parameters, endpoint parameters and resources

There are two ways to pass configuration data during install:

- `--values` (or `-f`): Specify a YAML file with overrides. This can be specified multiple times and the rightmost file takes precedence.
- `--set`: Specify overrides on the command line.

For local development, a practical approach is to create a copy of the `values.yaml` file named `values.local.yaml` for machine-specific or temporary overrides and keep it out of version control. This is the recommended approach when you want a repeatable local configuration.

Then install with:

```sh
helm install rdfox ost/rdfox --devel -f values.local.yaml --set endpointParameters.channel=unsecure
```

For quick one-off changes, override values with `--set`.

To enable high availability (HA), set the persistence server parameter to `file-sequence`:

```sh
helm install rdfox ost/rdfox --devel \
  --set endpointParameters.channel=unsecure \
  --set serverParameters.persistence=file-sequence
```

In order to use file-sequence persistence, ensure that your RDFox license supports this feature.

For further information on available parameters, see the documentation for the [RDFox server parameters](https://docs.oxfordsemantic.tech/servers.html#server-parameters) and the [RDFox endpoint parameters](https://docs.oxfordsemantic.tech/rdfox-endpoint.html#endpoint-parameters).

To configure resources, use `--set` values such as:

```sh
helm install rdfox ost/rdfox --devel \
  --set endpointParameters.channel=unsecure \
  --set resources.requests.cpu=1 \
  --set resources.requests.memory=1Gi \
  --set resources.limits.cpu=1 \
  --set resources.limits.memory=1Gi
```

To adjust the size of the persistent volume claim, use `--set persistenceProfiles.<mode>.persistentVolumeClaim.size` for provider-specific values.
For hardware requirements, see [RDFox hardware requirements](https://docs.oxfordsemantic.tech/features-and-requirements.html#hardware).

### Configure TLS

To enable TLS, you need a valid credentials file in PEM format. For more information on the credentials file structure and the `channel` endpoint parameter, see the [RDFox endpoint parameters documentation](https://docs.oxfordsemantic.tech/rdfox-endpoint.html#endpoint-parameters).

Create a secret for the TLS credentials:

```sh
kubectl create secret generic rdfox-tls-credentials --from-file=credentials=<PATH_TO_CREDENTIALS_FILE> --from-literal=passphrase=<YOUR_PASSPHRASE>
```

Replace `<PATH_TO_CREDENTIALS_FILE>` with the path to your TLS credential file (for example, `cred.pem`) and replace `<YOUR_PASSPHRASE>` with its passphrase.

Then, to deploy RDFox with TLS enabled, run:

```sh
helm install rdfox ost/rdfox --devel --set endpointParameters.channel=ssl
```

### Configure Encryption Keys

RDFox supports encryption for persistence, session data, and delta queries. To enable encryption, provide encryption keys for the features you want to use. The Helm chart lets you provide these keys as Kubernetes secrets.

Adjust the following command to include only the keys relevant to your configuration. For example, if you are using only persistence encryption, include only the `persistence-encryption-key` parameter and omit the others.

Create a secret for the encryption keys:

```sh
kubectl create secret generic rdfox-encryption-keys \
  --from-literal=persistence-encryption-key=$(openssl rand -base64 32) \
  --from-literal=session-encryption-key=$(openssl rand -base64 32) \
  --from-literal=delta-queries-encryption-key=$(openssl rand -base64 32)
```

After creating the secret, install the chart as usual. RDFox will consume whichever keys are present in the `rdfox-encryption-keys` secret.