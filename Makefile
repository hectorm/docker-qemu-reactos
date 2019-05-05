#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -eu -c

DOCKER := $(shell command -v docker 2>/dev/null)
GIT := $(shell command -v git 2>/dev/null)

DISTDIR := ./dist

IMAGE_NAMESPACE := hectormolinero
IMAGE_NAME := qemu-reactos
IMAGE_VERSION := v0

# If git is available and the directory is a repository, use the latest tag as IMAGE_VERSION.
ifeq ([$(notdir $(GIT))][$(wildcard .git/.)],[git][.git/.])
	IMAGE_VERSION := $(shell '$(GIT)' describe --abbrev=0 --tags 2>/dev/null || printf '%s' '$(IMAGE_VERSION)')
endif

IMAGE_LATEST_TAG := $(IMAGE_NAMESPACE)/$(IMAGE_NAME):latest
IMAGE_VERSION_TAG := $(IMAGE_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_VERSION)

IMAGE_TARBALL := $(DISTDIR)/$(IMAGE_NAME).tgz

DOCKERFILE := ./Dockerfile

##################################################
## "all" target
##################################################

.PHONY: all
all: save-image

##################################################
## "build-*" targets
##################################################

.PHONY: build-image
build-image:
	'$(DOCKER)' build \
		--tag '$(IMAGE_VERSION_TAG)' \
		--tag '$(IMAGE_LATEST_TAG)' \
		--file '$(DOCKERFILE)' ./

##################################################
## "save-*" targets
##################################################

define save_image
	'$(DOCKER)' save '$(1)' | gzip -n > '$(2)'
endef

.PHONY: save-image
save-image: $(IMAGE_TARBALL)

$(IMAGE_TARBALL): build-image
	mkdir -p '$(DISTDIR)'
	$(call save_image,$(IMAGE_VERSION_TAG),$@)

##################################################
## "load-*" targets
##################################################

define load_image
	'$(DOCKER)' load -i '$(1)'
endef

define tag_image
	'$(DOCKER)' tag '$(1)' '$(2)'
endef

.PHONY: load-image
load-image:
	$(call load_image,$(IMAGE_TARBALL))
	$(call tag_image,$(IMAGE_VERSION_TAG),$(IMAGE_LATEST_TAG))

##################################################
## "push-*" targets
##################################################

define push_image
	'$(DOCKER)' push '$(1)'
endef

.PHONY: push-image
push-image:
	$(call push_image,$(IMAGE_VERSION_TAG))
	$(call push_image,$(IMAGE_LATEST_TAG))

##################################################
## "version" target
##################################################

.PHONY: version
version:
	@if printf -- '%s' '$(IMAGE_VERSION)' | grep -q '^v[0-9]\{1,\}$$'; then \
		NEW_IMAGE_VERSION=$$(awk -v 'v=$(IMAGE_VERSION)' 'BEGIN {printf "v%.0f", substr(v,2)+1}'); \
		printf -- '%s\n' "$${NEW_IMAGE_VERSION}" > ./VERSION; \
		'$(GIT)' add ./VERSION; '$(GIT)' commit -m "$${NEW_IMAGE_VERSION}"; \
		'$(GIT)' tag -a "$${NEW_IMAGE_VERSION}" -m "$${NEW_IMAGE_VERSION}"; \
	else \
		>&2 printf -- 'Malformed version string: %s\n' '$(IMAGE_VERSION)'; \
		exit 1; \
	fi

##################################################
## "clean" target
##################################################

.PHONY: clean
clean:
	rm -f '$(IMAGE_TARBALL)'
	if [ -d '$(DISTDIR)' ]; then rmdir '$(DISTDIR)'; fi
