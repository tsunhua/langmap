# Backend Dockerfile
FROM python:3.11-slim

# 添加构建参数支持国内镜像源
ARG PIP_INDEX_URL=https://pypi.org/simple
ENV PIP_INDEX_URL=$PIP_INDEX_URL

# 配置pip使用国内镜像源
RUN if [ "$PIP_INDEX_URL" != "https://pypi.org/simple" ]; then \
        pip config set global.index-url $PIP_INDEX_URL && \
        pip config set install.trusted-host $(echo $PIP_INDEX_URL | sed -e 's|https://||' -e 's|http://||' | cut -d'/' -f1); \
    fi

# # 更新包索引并安装系统依赖和网络诊断工具
# RUN apt-get update && apt-get install -y \
#     gcc \
#     dnsutils \
#     iputils-ping \
#     curl \
#     && rm -rf /var/lib/apt/lists/*

# 配置DNS解析
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf \
    && echo "nameserver 8.8.4.4" >> /etc/resolv.conf

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY . .

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]