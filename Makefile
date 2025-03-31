IMAGE_VERSION ?= latest
# 确保 BUILDER_NAME 在解析阶段就确定值
BUILDER_NAME ?= my-image-builder
REGISTRY_URI ?= ""
DOCKERFILE_NAME ?= Dockerfile
IMAGE_NAME ?= ""

all: build-builder
	@$(MAKE) build-image && $(MAKE) clean || ($(MAKE) clean)

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
	docker buildx create --name ${BUILDER_NAME} --driver docker-container \
		--use --bootstrap --platform linux/amd64,linux/arm64
      
build-image:
	@if [ "${REGISTRY_URI}" = "" ] || [ "${IMAGE_NAME}" = "" ]; then \
        echo "error: must set the image store registry use variable REGISTRY_URI and IMAGE_NAME"; \
        exit 1; \
    fi
	docker buildx build --builder ${BUILDER_NAME} \
        --platform linux/amd64,linux/arm64 \
        --build-arg IMAGE_VERSION=${IMAGE_VERSION} \
        --tag ${REGISTRY_URI}/${IMAGE_NAME}:${IMAGE_VERSION} \
        --file ${DOCKERFILE_NAME} \
        --push .

clean:
	docker buildx stop ${BUILDER_NAME}
	docker buildx rm ${BUILDER_NAME}