SHELL=/bin/bash

export LC_ALL=C
export UID = $(shell id -u)
export GID = $(shell id -g)

DOCKER_RUN=docker run -t -u $(UID):$(GID) -v $(PWD):/v -w /v --rm crystallang/crystal:0.33.0

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.SHELLFLAGS = -o pipefail -c

.PHONY: all compile release test difftsv difftsv-dev

compile: difftsv-dev

all: test compile

difftsv-dev:
	shards build difftsv-dev $(O)

release:
	$(DOCKER_RUN) shards build difftsv --link-flags "-static" --release

test: check_version_mismatch spec

.PHONY: spec
spec:
	crystal spec -v --fail-fast

.PHONY: check_version_mismatch
check_version_mismatch: shard.yml README.cr.md
	diff -w -c <(grep version: README.cr.md) <(grep ^version: shard.yml)

.PHONY: version
version:
	@if [ "$(VERSION)" = "" ]; then \
	  echo "ERROR: specify VERSION as bellow. (current: $(CURRENT_VERSION))";\
	  echo "  make version VERSION=$(GUESSED_VERSION)";\
	else \
	  sed -i -e 's/^version: .*/version: $(VERSION)/' shard.yml ;\
	  sed -i -e 's/^    version: [0-9]\+\.[0-9]\+\.[0-9]\+/    version: $(VERSION)/' README.cr.md ;\
	  echo git commit -a -m "'$(COMMIT_MESSAGE)'" ;\
	  git commit -a -m 'version: $(VERSION)' ;\
	  git tag "v$(VERSION)" ;\
	fi

.PHONY: bump
bump:
	make version VERSION=$(GUESSED_VERSION) -s
