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