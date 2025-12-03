from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import endpoints
from app.db import models
from app.db.database import engine
import os

app = FastAPI(title="langmap-backend")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# create tables on startup for quick local dev
models.Base.metadata.create_all(bind=engine)

# Include routers - order matters!
app.include_router(endpoints.router)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/db-status")
def db_status():
    db_url = os.getenv("DATABASE_URL", "sqlite:///./backend_dev.db")
    return {
        "database_url": db_url,
        "database_type": get_database_type(db_url)
    }

def get_database_type(url):
    if url.startswith("sqlite"):
        return "SQLite"
    elif url.startswith("d1"): 
        return "Cloudflare D1"
    elif url.startswith("postgresql"):
        return "PostgreSQL"
    elif url.startswith("mysql"):
        return "MySQL"
    else:
        return "Unknown"

# For Cloudflare Workers compatibility
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    # Return JSON for API routes, but HTML for frontend routes
    if request.url.path.startswith("/api/"):
        return JSONResponse(
            status_code=404,
            content={"detail": "Not Found"}
        )
    # For frontend routes, we would serve the index.html
    # But in Cloudflare Workers, we'll handle this differently
    return JSONResponse(
        status_code=404,
        content={"detail": "Not Found"}
    )
