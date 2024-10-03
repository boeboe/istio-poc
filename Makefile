# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

#################
##### Setup #####
#################

.PHONY: info clean

info: ## Print kind cluster information and kubectl info
	./info.sh

clean: ## Clean all temporary artifacts
	rm -rf ./output/*

######################
##### Scenarios ######
######################

.PHONY: deploy-http undeploy-http deploy-https-mtls undeploy-https-mtls

deploy-http: ## Deploy Nginx as plain HTTP with Istio Gateway
	./http.sh deploy

undeploy-http: ## Undeploy Nginx as plain HTTP with Istio Gateway
	./http.sh undeploy

deploy-https-mtls: ## Deploy Nginx as mutual TLS HTTPS with Istio Gateway
	./https-mtls.sh deploy

undeploy-https-mtls: ## Undeploy Nginx as mutual TLS HTTPS with Istio Gateway
	./https-mtls.sh undeploy
