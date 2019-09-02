#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -eu -c

DOCKER := $(shell command -v docker 2>/dev/null)
GIT := $(shell command -v git 2>/dev/null)

DISTDIR := ./dist
VERSION_FILE = ./VERSION
DOCKERFILE := ./Dockerfile

IMAGE_REGISTRY := docker.io
IMAGE_NAMESPACE := hectormolinero
IMAGE_PROJECT := qemu-reactos
IMAGE_NAME := $(IMAGE_REGISTRY)/$(IMAGE_NAMESPACE)/$(IMAGE_PROJECT)

IMAGE_VERSION := v0
ifneq ($(wildcard $(VERSION_FILE)),)
	IMAGE_VERSION := $(shell cat '$(VERSION_FILE)')
endif

IMAGE_TARBALL := $(DISTDIR)/$(IMAGE_PROJECT).txz

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
		--tag '$(IMAGE_NAME):$(IMAGE_VERSION)' \
		--tag '$(IMAGE_NAME):latest' \
		--file '$(DOCKERFILE)' ./

##################################################
## "save-*" targets
##################################################

define save_image
	'$(DOCKER)' save '$(1)' | xz -T0 > '$(2)'
endef

.PHONY: save-image
save-image: $(IMAGE_TARBALL)

$(IMAGE_TARBALL): build-image
	mkdir -p '$(DISTDIR)'
	$(call save_image,$(IMAGE_NAME):$(IMAGE_VERSION),$@)

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
	$(call tag_image,$(IMAGE_NAME):$(IMAGE_VERSION),$(IMAGE_NAME):latest)

##################################################
## "push-*" targets
##################################################

define push_image
	'$(DOCKER)' push '$(1)'
endef

.PHONY: push-image
push-image:
	$(call push_image,$(IMAGE_NAME):$(IMAGE_VERSION))
	$(call push_image,$(IMAGE_NAME):latest)

##################################################
## "version" target
##################################################

.PHONY: version
version:
	@if printf -- '%s' '$(IMAGE_VERSION)' | grep -q '^v[0-9]\{1,\}$$'; then \
		NEW_IMAGE_VERSION=$$(awk -v 'v=$(IMAGE_VERSION)' 'BEGIN {printf "v%.0f", substr(v,2)+1}'); \
		printf -- '%s\n' "$${NEW_IMAGE_VERSION:?}" > '$(VERSION_FILE)'; \
		'$(GIT)' add '$(VERSION_FILE)'; '$(GIT)' commit -m "$${NEW_IMAGE_VERSION:?}"; \
		'$(GIT)' tag -a "$${NEW_IMAGE_VERSION:?}" -m "$${NEW_IMAGE_VERSION:?}"; \
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
	if [ -d '$(DISTDIR)' ] && [ -z "$$(ls -A '$(DISTDIR)')" ]; then rmdir '$(DISTDIR)'; fi
