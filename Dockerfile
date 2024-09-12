##编译
FROM golang:1.23 AS builder
WORKDIR /app
ARG TARGETARCH
ENV GO111MODULE=on
# ENV GOPROXY="https://goproxy.cn,direct"
COPY go.mod go.sum ./
RUN go mod download
COPY . .
#go-sqlite3需要cgo编译; 且使用完全静态编译, 否则需依赖外部安装的glibc
RUN CGO_ENABLED=1 GOOS=linux GOARCH=$TARGETARCH go build -ldflags "-s -w --extldflags '-static -fpic'" -o server . && \
    mv config.example.yaml server /app/static


##打包镜像
FROM alpine:latest
LABEL org.opencontainers.image.vendor="忐忑"
LABEL org.opencontainers.image.authors="1174865138@qq.com"
LABEL org.opencontainers.image.description="小程序我们何时约"
LABEL org.opencontainers.image.source="https://github.com/twbworld/dating"
WORKDIR /app
COPY --from=builder /app/static/ static/
RUN set -xe && \
    mv static/config.example.yaml config.yaml && \
    mv static/server server && \
    chmod +x server && \
    # sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk update && \
    apk add -U --no-cache tzdata ca-certificates && \
    apk cache clean && \
    rm -rf /var/cache/apk/*
# EXPOSE 80
ENTRYPOINT ["./server"]
