import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 加载环境变量
load_dotenv()

# 获取数据库URL配置
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./backend_dev.db")

# 根据数据库类型创建引擎
if DATABASE_URL.startswith("sqlite"):
    # SQLite配置
    engine = create_engine(
        DATABASE_URL, connect_args={"check_same_thread": False}
    )
elif DATABASE_URL.startswith("d1"): 
    # Cloudflare D1配置 (示例，实际配置可能不同)
    # D1使用特殊的连接方式，这里只是示意
    engine = create_engine(
        DATABASE_URL, 
        connect_args={"charset": "utf8mb4"},
        pool_pre_ping=True
    )
else:
    # 其他数据库配置 (PostgreSQL, MySQL等)
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()