VERSION ?= 1.22.1.4228
CACHE ?= --no-cache=1
FULLVERSION ?= 1.22.1.4228
archs ?= amd64 armhf arm64v8 aarch64
PMS_URL ?=

.PHONY: all build publish latest
all: build publish latest
qemu-aarch64-static:
	cp /usr/bin/qemu-aarch64-static .
build: qemu-aarch64-static
	docker images | grep  "pipehnz\/plex\s.*" | awk '{print $$1":"$$2}' | xargs docker rmi || true
	$(foreach arch,$(archs), \
		cat Dockerfile.builder > Dockerfile; \
		cat docker/$(arch)/Dockerfile.template >> Dockerfile; \
		cat Dockerfile.common >> Dockerfile; \
		docker build -t pipehnz/plex:${VERSION}-$(arch) --build-arg PMS_URL=${PMS_URL} --build-arg ARCH=$(arch) --build-arg VERSION=${VERSION}-$(arch) ${CACHE} .;\
		docker run --rm --privileged multiarch/qemu-user-static:register --reset; \
	)
publish:
	docker push pipehnz/plex -a
	cat manifest.yml | sed "s/\$$VERSION/${VERSION}/g" > manifest.yaml
	cat manifest.yaml | sed "s/\$$FULLVERSION/${FULLVERSION}/g" > manifest2.yaml
	mv manifest2.yaml manifest.yaml
	manifest-tool push from-spec manifest.yaml
latest:
	FULLVERSION=latest VERSION=${VERSION} make publish