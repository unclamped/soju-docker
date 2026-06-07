FROM golang:1.24-alpine AS builder

ARG SOJU_REPO=https://codeberg.org/emersion/soju.git
ARG SOJU_REF=master

RUN apk add --no-cache git gcc musl-dev

RUN git clone --depth 1 --branch "${SOJU_REF}" "${SOJU_REPO}" /src

WORKDIR /src

RUN go build \
    -ldflags="-X 'codeberg.org/emersion/soju/config.DefaultPath=/etc/soju/config' \
              -X 'codeberg.org/emersion/soju/config.DefaultUnixAdminPath=/run/soju/admin'" \
    -o /out/ \
    ./cmd/soju ./cmd/sojudb ./cmd/sojuctl

RUN cp config.in /out/config.example


FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -S soju && \
    adduser -S -G soju -H -s /sbin/nologin soju && \
    mkdir -p /etc/soju /var/lib/soju /run/soju && \
    chown soju:soju /etc/soju /var/lib/soju /run/soju

COPY --from=builder /out/soju /out/sojudb /out/sojuctl /usr/local/bin/
COPY --from=builder /out/config.example /etc/soju/config.example

USER soju

VOLUME ["/etc/soju", "/var/lib/soju"]

EXPOSE 6667 6697

ENTRYPOINT ["/usr/local/bin/soju"]
