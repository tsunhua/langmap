# Backend Docker Deployment

This guide explains how to build and run the backend service using Docker.

## Building the Backend Docker Image

From the `backend` directory, run:

```bash
docker build -t langmap-backend .
```

## 如果遇到网络问题

如果在构建过程中遇到网络连接问题（特别是访问 PyPI 源时），可以使用国内镜像源：

```bash
docker build \
  --build-arg PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
  -t langmap-backend .
```

其他可选的国内镜像源：
- 阿里云: http://mirrors.aliyun.com/pypi/simple
- 中科大: https://pypi.mirrors.ustc.edu.cn/simple
- 华为云: https://repo.huaweicloud.com/repository/pypi/simple

### DNS 解析问题

如果遇到 "Temporary failure in name resolution" 错误，可以尝试以下解决方案：

1. 确保您的网络连接正常
2. 重启 Docker 服务
3. 在构建时添加网络参数：
   ```bash
   docker build --network=host -t langmap-backend .
   ```
4. 配置 Docker Daemon 使用 DNS 服务器，在 Docker Desktop 中：
   ```json
   {
     "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
   }
   ```
5. 使用完整版 Python 镜像（已默认使用）：
   我们已经将镜像从 `python:3.11-slim` 更改为 `python:3.11`，因为 slim 版本可能会缺少一些 DNS 解析所需的组件。

### 网络诊断

如果问题仍然存在，您可以构建一个带有诊断工具的镜像来排查问题：

```bash
# 构建后进入容器进行网络诊断
docker run -it --rm langmap-backend bash

# 在容器内运行以下命令进行诊断
nslookup pypi.org
ping pypi.org
curl -v https://pypi.org/simple/fastapi/
```

## Running the Container

To run the backend container:

```bash
docker run -p 8000:8000 langmap-backend
```

The backend API will be available at http://localhost:8000

## Using a Custom Database

By default, the container will use the SQLite database included in the image. For persistent data storage, you can mount a volume:

```bash
docker run -p 8000:8000 -v /path/on/host:/app/data langmap-backend
```

Make sure to adjust the application code to use the database file in the mounted directory.

## Environment Variables

The backend application supports the following environment variables:

- `DATABASE_URL`: Database connection string (default: SQLite database)

Example with custom database:

```bash
docker run -p 8000:8000 -e DATABASE_URL=sqlite:///data/custom.db langmap-backend
```