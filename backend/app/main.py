from fastapi import FastAPI
from app.api.v1 import endpoints
from app.db import models
from app.db.session import engine

app = FastAPI(title="langmap-backend")

# create tables on startup for quick local dev
models.Base.metadata.create_all(bind=engine)

app.include_router(endpoints.router)

@app.get("/health")
def health():
    return {"status": "ok"}
