# Backend Dockerfile
FROM python:3.11-slim

# 添加构建参数支持国内镜像源
ARG PIP_INDEX_URL=https://pypi.org/simple
RUN pip config set global.index-url $PIP_INDEX_URL

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY . .

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]