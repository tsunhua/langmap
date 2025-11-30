# langmap

LangMap is a language learning tool that helps you learn new languages by mapping words and phrases to their meanings in other languages.

## Features

- **Language Learning:** LangMap helps you learn new languages by mapping words and phrases to their meanings in other languages.
- **Interactive Map:** The interactive map allows you to explore the language map and see how words and phrases are mapped to their meanings in other languages.
- **User-Friendly Interface:** LangMap has a user-friendly interface that makes it easy to use.

## Installation

To install LangMap, follow these steps:
```bash
cd langmap
pip install -r requirements.txt
python -c "from app.db.session import engine; from app.db import models; models.Base.metadata.create_all(bind=engine)"
uvicorn app.main:app --reload --port 8000
```

## Todo

- [] 支持有音無字的語言輸入，聲音錄入
