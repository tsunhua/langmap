# LangMap Backend

This is the backend API for LangMap, built with FastAPI.

## Features

- RESTful API for language data
- SQLite database for local development
- Easily deployable with Docker

## Setup

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the development server:
   ```bash
   uvicorn app.main:app --reload
   ```

## Database Configuration

The application supports multiple database backends through environment variables:

### SQLite (default for local development)
```bash
export DATABASE_URL="sqlite:///./backend_dev.db"
```

### Other databases
```bash
# PostgreSQL
export DATABASE_URL="postgresql://user:password@localhost:5432/mydatabase"

# MySQL
export DATABASE_URL="mysql://user:password@localhost:3306/mydatabase"
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Docker

See [README.DOCKER.md](README.DOCKER.md) for Docker deployment instructions.