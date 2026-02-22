VERSION		?= v2.0.0
VERSION_MAJOR	:= $(shell echo $(VERSION) | cut -f1 -d.)
VERSION_MINOR	:= $(shell echo $(VERSION) | cut -f2 -d.)
BINARY_NAME	:= prometheus-docker-labels-discovery

GIT_COMMIT	:= $(shell git rev-parse HEAD)
GIT_DIRTY	:= $(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)
BUILD_DATE	:= $(shell date '+%Y-%m-%d-%H:%M:%S')

GOOS		?= $(shell go env GOOS)
GOARCH		?= $(shell go env GOARCH)
GO_BUILDTAGS	?= osusergo netgo
GO_ENV		+= GOOS=$(GOOS) GOARCH=$(GOARCH)
GO_LDFLAGS	+= -X 'github.com/sqooba/go-common/version.GitCommit=$(GIT_COMMIT)$(GIT_DIRTY)' \
		   -X 'github.com/sqooba/go-common/version.BuildDate=$(BUILD_DATE)' \
		   -X 'github.com/sqooba/go-common/version.Version=$(VERSION)'
GO_BUILDTAGS	+= $(GO_BUILDTAGS_EXTRA)
GO_BUILDFLAGS	+= -tags "$(GO_BUILDTAGS)" \
		   -ldflags "$(GO_LDFLAGS)" \
		   $(GO_BUILDFLAGS_EXTRA)

DOCKER_REGISTRY	?= ghcr.io/
DOCKER_IMAGE	?= 0rax/prometheus-docker-labels-discovery

build:
	$(GO_ENV) go build $(GO_BUILDFLAGS) -o $(BINARY_NAME) .

static: GO_ENV       += CGO_ENABLED=0
static: GO_LDFLAGS   += -extldflags -static
static: GO_BUILDTAGS += static_build
static: build

test:
	go test ./...

lint:
	golangci-lint run ...

clean:
	go clean

package:
	docker buildx build -f Dockerfile \
		--build-arg VERSION=$(VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):latest \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(VERSION) \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(VERSION_MAJOR).$(VERSION_MINOR) \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(VERSION_MAJOR) \
		--load --no-cache \
		.

release:
	docker buildx build -f Dockerfile \
		--platform linux/amd64,linux/arm64,linux/arm/v7 \
		--build-arg VERSION=$(VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):latest \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(VERSION) \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(VERSION_MAJOR).$(VERSION_MINOR) \
		-t $(DOCKER_REGISTRY)$(DOCKER_IMAGE):$(VERSION_MAJOR) \
		--push \
		.
