FROM golang:1.23.1 AS builder

ENV GO111MODULE=on

RUN apk update && apk add --no-cache git

WORKDIR /app

# 复制 go.mod 和 go.sum 并下载依赖
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 编译 Go 应用，使用静态链接以减少二进制文件大小
RUN go build -o main .

# 第二阶段：运行阶段
FROM alpine:latest

# 设置环境变量，防止时区相关问题
ENV TZ=UTC

# 安装必要的包（如果需要）
RUN apk --no-cache add ca-certificates

# 创建用户和组以非 root 身份运行应用（增强安全性）
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 设置工作目录
WORKDIR /app

# 从构建阶段复制编译好的二进制文件
COPY --from=builder /app/main .

# 更改所有权以确保安全
RUN chown appuser:appgroup main

# 暴露应用运行的端口（与 Gin 服务器的端口保持一致）
EXPOSE 8080

# 切换到非 root 用户
USER appuser

# 启动应用
ENTRYPOINT ["./main"]
