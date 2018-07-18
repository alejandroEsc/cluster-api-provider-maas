# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: gendeepcopy

all: generate build images

depend:
	dep version || go get -u github.com/golang/dep/cmd/dep
	dep ensure

depend-update: work
	dep ensure -update

generate: gendeepcopy

gendeepcopy: ## generate deepcopy code
	go build -o $$GOPATH/bin/deepcopy-gen github.com/alejandroEsc/cluster-api-provider-maas/vendor/k8s.io/code-generator/cmd/deepcopy-gen
	deepcopy-gen \
	  -i ./cloud/maas/providerconfig,./cloud/maas/providerconfig/v1alpha1 \
	  -O zz_generated.deepcopy \
	  -h boilerplate.go.txt

build: depend ## install cluster-controller and machine-controller
	CGO_ENABLED=0 go install -a -ldflags '-extldflags "-static"' github.com/alejandroEsc/cluster-api-provider-maas/cmd/cluster-controller
	CGO_ENABLED=0 go install -a -ldflags '-extldflags "-static"' github.com/alejandroEsc/cluster-api-provider-maas/cmd/machine-controller

images: depend ## create images for cluster-controller and machine-controller
	$(MAKE) -C cmd/cluster-controller image
	$(MAKE) -C cmd/machine-controller image

push: depend ## push images
	$(MAKE) -C cmd/cluster-controller push
	$(MAKE) -C cmd/machine-controller push

check: depend fmt vet

test: ## run tests
	go test -race -cover ./cmd/... ./cloud/...


go-verify: ## run scripts to verify code
	./hack/verify.sh

go-lint: ## quick run of linting
	golint -set_exit_status $(shell git ls-files "**/*.go" "*.go" | grep -v -e "vendor" | xargs echo)

.PHONY: help
help:  ## Show help messages for make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

