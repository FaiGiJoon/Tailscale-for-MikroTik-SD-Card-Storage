FROM golang:1.24-alpine AS build-env

WORKDIR /go/src/tailscale

# Cache dependencies
COPY tailscale/go.mod tailscale/go.sum ./
RUN go mod download

RUN apk add --no-cache upx

COPY tailscale/. .

ARG VERSION_LONG=""
ENV VERSION_LONG=$VERSION_LONG
ARG VERSION_SHORT=""
ENV VERSION_SHORT=$VERSION_SHORT
ARG VERSION_GIT_HASH=""
ENV VERSION_GIT_HASH=$VERSION_GIT_HASH
ARG TARGETARCH

RUN GOARCH=$TARGETARCH go install -ldflags="-w -s \
      -X tailscale.com/version.Long=$VERSION_LONG \
      -X tailscale.com/version.Short=$VERSION_SHORT \
      -X tailscale.com/version.GitCommit=$VERSION_GIT_HASH" \
      -v ./cmd/tailscale ./cmd/tailscaled

RUN upx /go/bin/tailscale && upx /go/bin/tailscaled

FROM alpine:latest

RUN apk add --no-cache ca-certificates iptables iptables-legacy iproute2 bash openssh curl jq

RUN ln -s /usr/sbin/iptables-legacy /usr/local/bin/iptables
RUN ln -s /usr/sbin/ip6tables-legacy /usr/local/bin/ip6tables

RUN ssh-keygen -A

COPY --from=build-env /go/bin/* /usr/local/bin/
COPY sshd_config /etc/ssh/
COPY tailscale.sh /usr/local/bin/

EXPOSE 22
CMD ["/usr/local/bin/tailscale.sh"]
