# Passing Product License As A Secret

## Overview

This example will walkthrough the steps to pass a Ping Identity product license as a Kubernetes Secret.

## File Contents

* configmap.yaml
  * Server profile variables
* kustomization.yaml
  * Delcare deployment yaml resources
  * Generate license secret
* pingfederate.yaml
  * Kubernetes deployment yaml
  * Delcaration and use of container volume mount

## Add License File

To use this example, you will need to provide your PingFederate license file.

* Copy your license file to your working directory
* Rename file to `pingfederate.lic`

## Kustomize Secret Generator

Kustomize provides built in generators for creating secrets. In this example, the secret will be generated using the pingfederate.lic file

## PingFederate Deployment Yaml

### Declare Volume

Declare the volume within the volumes block. The name attribute is the value it will be referenced from the container. The secretName needs to match the secret name delcared in kustomization.yaml

### Reference Volume

Within the PingFederate container declaration, a definition is added to the volumeMounts section.

* name: Must match the name given to the volume in the above section
* mountPath: path to where product will look for license
* subPath: name of the file to be created
* readOnly: optional attribute

## Deploying

1. From within the deployments directory:

 ```bash
   kustomize build . | kubectl apply -f -
   ```

2. To clean up when you're finished, enter:

```bash
   kustomize build . | kubectl delete -f -
   ```