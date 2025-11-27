from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import endpoints
from app.api.v1 import languages
from app.db import models
from app.db.session import engine

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
app.include_router(languages.router)
app.include_router(endpoints.router)

@app.get("/health")
def health():
    return {"status": "ok"}