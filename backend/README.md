# langmap — backend (minimal FastAPI skeleton)

This folder contains a minimal FastAPI backend skeleton for local development.

Quick start (macOS / zsh):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# create sqlite db and tables
python -c "from app.db.session import engine; from app.db import models; models.Base.metadata.create_all(bind=engine)"
# run server
uvicorn app.main:app --reload --port 8000
```

Notes:
- The default DB is SQLite for quick local testing. Set `DATABASE_URL` env var to use Postgres in production.
- This skeleton intentionally keeps dependencies minimal for easier maintenance.
