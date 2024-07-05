FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder

RUN apk add --no-cache make git

ARG TARGETOS
ARG TARGETARCH
ARG VERSION
ARG BUILD_DATE

WORKDIR /src

COPY go.mod go.sum /src
RUN env GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go mod download

COPY . /src
RUN make static GOOS=${TARGETOS} GOARCH=${TARGETARCH} VERSION=${VERSION} BUILD_DATE=${BUILD_DATE}

FROM alpine

RUN apk add --no-cache ca-certificates

COPY --from=builder /src/prometheus-docker-labels-discovery /prometheus-docker-labels-discovery

# Because of access to docker.sock, it's easier to run it as root...
#USER nobody

ENTRYPOINT ["/prometheus-docker-labels-discovery"]
EXPOSE 8080

HEALTHCHECK \
    --interval=60s \
    --timeout=10s \
    --retries=1 \
    --start-period=30s \
    CMD ["wget", "-qO/dev/null", "localhost:8080/metrics"]
