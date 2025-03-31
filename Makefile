IMAGE_VERSION ?= latest
BUILDER_NAME ?= my-image-builder
DOCKERFILE_NAME ?= Dockerfile
IMAGE_NAME ?= ""
PLATFORMS ?= linux/amd64,linux/arm64
REGISTRY_ADDR ?= ghcr.io
REGISTRY_USER ?= ""

all: build-builder
	@$(MAKE) build-image && $(MAKE) clean || ($(MAKE) clean && exit 1)

.PHONY: all help build-builder build-image clean

help:
	@echo 'Commands Usage:'
	@echo
	@echo '    make build-image              use buildx build image and push to registry'
	@echo '    make build-builder             create a buildx multiplatform builder'
	@echo '    make clean                     stop and remove buildx builder'
	@echo '    make IMAGE_VERSION=aaa BUILDER_NAME=xxx REGISTRY_URI=yyy IMAGE_NAME=zzz DOCKERFILE_NAME=ccc'
	@echo

build-builder:
	@if docker buildx inspect ${BUILDER_NAME} >/dev/null 2>&1; then \
		docker buildx use ${BUILDER_NAME} \
		docker buildx inspect ${BUILDER_NAME} --bootstrap >/dev/null 2>&1 \
		echo "Builder ${BUILDER_NAME} already exists"; \
	else \
		docker buildx create --name ${BUILDER_NAME} --driver docker-container \
			--use --bootstrap --platform ${PLATFORMS}; \
	fi
      
build-image:
	@if [ -z "${REGISTRY_USER}" ] || [ -z "${IMAGE_NAME}" ]; then \
        echo "error: must set the image store registry use variable REGISTRY_USER and IMAGE_NAME"; \
        exit 1; \
    fi
	docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --build-arg IMAGE_VERSION=${IMAGE_VERSION} \
        --tag ${REGISTRY_ADDR}/${REGISTRY_USER}/${IMAGE_NAME}:${IMAGE_VERSION} \
        --file ${DOCKERFILE_NAME} \
        --push .

registry-login:
	docker login ${REGISTRY_ADDR}

clean:
	@if docker buildx inspect ${BUILDER_NAME} >/dev/null 2>&1; then \
		docker buildx stop ${BUILDER_NAME}; \
		docker buildx rm ${BUILDER_NAME}; \
	else \
		echo "Builder ${BUILDER_NAME} does not exist, skipping clean"; \
	fi