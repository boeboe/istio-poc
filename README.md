# Istio POC

## Overview

This project provides a Proof of Concept (PoC) for deploying and configuring istio exposed applications. The deployment can be controlled using the provided Makefile targets and bash scripts, which offer a convenient way to manage the cluster and Istio components.

## Prerequisites

Ensure you have the following tools installed before proceeding:

	•	kubectl
	•	istioctl (for debugging only)

## Usage

The following targets are defined in the [Makefile](./Makefile):

```console
$ make

help                           This help
info                           Print kind cluster information and kubectl info
clean                          Clean all temporary artifacts
deploy-http                    Deploy Nginx as plain HTTP with Istio Gateway
undeploy-http                  Undeploy Nginx as plain HTTP with Istio Gateway
deploy-https-mtls              Deploy Nginx as mutual TLS HTTPS with Istio Gateway
undeploy-https-mtls            Undeploy Nginx as mutual TLS HTTPS with Istio Gateway
```

## Environment Variables

The environment variables used in this project are defined in [env.sh](./env.sh). These variables control the cluster name, the Kubernetes context, and the Istio version. Below are the variables that can be configured:

1. **ENVIRONMENT**

	-	Description: The name of the AKS Platform Environment.
	-	Default Value: plfstg
	-	Usage: Set export ENVIRONMENT="plfstg" to use another AKS Platform Environment.
